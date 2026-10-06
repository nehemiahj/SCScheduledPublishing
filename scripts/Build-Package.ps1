<#
.SYNOPSIS
    Builds the Sitecore Scheduled Publish release artifacts without Package Designer.

.DESCRIPTION
    1. Generates the Items as Resources (IAR) files from the serialized items with the Sitecore CLI.
    2. Builds ScheduledPublish.dll.
    3. Lays out the webroot files and zips them (file-drop package; unzip into the webroot to install).
    4. Packs the NuGet package.
    5. Lays out the Sitecore module asset image (module\cm\content) and, with -DockerRepository,
       builds one image per Windows base (docker/Dockerfile). Pushing is left to the caller.

    Output goes to <repo>\artifacts. The file-drop zip is also copied to <repo>\Packages.

.EXAMPLE
    pwsh ./scripts/Build-Package.ps1

.EXAMPLE
    # Also builds nehemiah/sitecore-scheduled-publish:10.5-ltsc2025 and :10.5-ltsc2022
    pwsh ./scripts/Build-Package.ps1 -DockerRepository nehemiah/sitecore-scheduled-publish
#>
[CmdletBinding()]
param(
    [string]$Configuration = "Release",
    [string]$Version = "10.5.0",
    # Docker repository to build the module asset images into. No images are built when empty.
    [string]$DockerRepository,
    # Windows nanoserver base tags; one image is built per base, tagged <version>-<base>.
    # Sitecore 10.5 supports ltsc2025 and ltsc2022; 1809/ltsc2019 is no longer supported.
    [string[]]$DockerBases = @("ltsc2025", "ltsc2022")
)

$ErrorActionPreference = "Stop"

$repoRoot   = Split-Path -Parent $PSScriptRoot
$projectDir = Join-Path $repoRoot "src\Foundation\ScheduledPublish\code"
$project    = Join-Path $projectDir "ScheduledPublish.csproj"
$artifacts  = Join-Path $repoRoot "artifacts"
$iarDir     = Join-Path $artifacts "iar"
$webroot    = Join-Path $artifacts "webroot"
$zipName    = "Sitecore Schedule Publish-$Version IAR (files).zip"

function Invoke-Native([string]$exe, [string[]]$arguments) {
    & $exe @arguments
    if ($LASTEXITCODE -ne 0) { throw "$exe $($arguments -join ' ') failed with exit code $LASTEXITCODE" }
}

if (Test-Path $artifacts) { Remove-Item $artifacts -Recurse -Force }
New-Item -ItemType Directory -Force $iarDir, $webroot | Out-Null

Push-Location $repoRoot
try {
    # Sitecore CLI 5.2.x targets .NET 6; allow it to run on a newer installed runtime.
    $env:DOTNET_ROLL_FORWARD = "Major"

    Write-Host "== Generating IAR files" -ForegroundColor Cyan
    Invoke-Native dotnet @("tool", "restore")
    Invoke-Native dotnet @("sitecore", "itemres", "create", "-i", "ScheduledPublish", "-o", (Join-Path $iarDir "schedule.publish"), "--overwrite")

    Write-Host "== Building $Configuration" -ForegroundColor Cyan
    Invoke-Native dotnet @("build", $project, "-c", $Configuration, "-p:Version=$Version")

    Write-Host "== Laying out webroot files" -ForegroundColor Cyan
    $binDir = Join-Path $webroot "bin"
    New-Item -ItemType Directory -Force $binDir | Out-Null
    Copy-Item (Join-Path $projectDir "bin\$Configuration\net481\ScheduledPublish.dll") $binDir

    # Only the .config/.xml files are deployed; the dialog code-beside .cs files are compiled into the DLL.
    Get-ChildItem (Join-Path $projectDir "App_Config"), (Join-Path $projectDir "sitecore") -Recurse -File -Include *.config, *.xml |
        ForEach-Object {
            $target = Join-Path $webroot ([IO.Path]::GetRelativePath($projectDir, $_.FullName))
            New-Item -ItemType Directory -Force (Split-Path -Parent $target) | Out-Null
            Copy-Item $_.FullName $target
        }

    foreach ($db in "master", "core") {
        $dbDir = Join-Path $webroot "App_Data\items\$db"
        New-Item -ItemType Directory -Force $dbDir | Out-Null
        Copy-Item (Join-Path $iarDir "items.$db.schedule.publish.dat") $dbDir
    }

    Write-Host "== Creating file-drop zip" -ForegroundColor Cyan
    $zipPath = Join-Path $artifacts $zipName
    Compress-Archive -Path (Join-Path $webroot "*") -DestinationPath $zipPath
    Copy-Item $zipPath (Join-Path $repoRoot "Packages") -Force

    Write-Host "== Packing NuGet package" -ForegroundColor Cyan
    Invoke-Native dotnet @("pack", $project, "-c", $Configuration, "--no-build", "-o", $artifacts, "-p:Version=$Version", "-p:IarOutputPath=$iarDir\")

    Write-Host "== Laying out Docker module asset image (CM)" -ForegroundColor Cyan
    $dockerContext = Join-Path $artifacts "docker"
    $cmContent = Join-Path $dockerContext "module\cm\content"
    New-Item -ItemType Directory -Force $cmContent | Out-Null
    Copy-Item (Join-Path $webroot "*") $cmContent -Recurse

    $images = @()
    if ($DockerRepository) {
        # 10.5.0 -> 10.5, 10.5.1 -> 10.5.1 (matches the existing 10.4-ltsc2022 style tags)
        $imageVersion = $Version -replace '\.0$', ''
        $revision = (git -C $repoRoot rev-parse HEAD).Trim()
        $created = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        foreach ($base in $DockerBases) {
            $image = "$($DockerRepository.ToLower()):$imageVersion-$base"
            Write-Host "== Building Docker image $image" -ForegroundColor Cyan
            Invoke-Native docker @("build",
                "--build-arg", "BASE_IMAGE=mcr.microsoft.com/windows/nanoserver:$base",
                "--build-arg", "VERSION=$Version",
                "--build-arg", "REVISION=$revision",
                "--build-arg", "CREATED=$created",
                "-f", (Join-Path $repoRoot "docker\Dockerfile"), "-t", $image, $dockerContext)
            $images += $image
        }
    }

    Write-Host "`nArtifacts:" -ForegroundColor Green
    Get-ChildItem $artifacts -File | ForEach-Object { Write-Host "  $($_.FullName)" }
    if ($images) {
        Write-Host "`nDocker images (push with: docker push <image>):" -ForegroundColor Green
        $images | ForEach-Object { Write-Host "  $_" }
    }
}
finally {
    Pop-Location
}
