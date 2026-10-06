forked from [HedgehogDevelopment/SCScheduledPublishing](https://github.com/HedgehogDevelopment/SCScheduledPublishing).

[Documentation](https://github.com/HedgehogDevelopment/SCScheduledPublishing/tree/master/Documentation) has been updated in the readme markdown.

# Overview:

The purpose of Scheduled Publish is to give the content editor the option to delay the publishing of an item for a future point in time. Thus, a page or a feature that should go live at a specific time can be created and populated in Sitecore and previewed long before it goes live without the risk of an accidental publish before the specific time. Moreover, there is no need for a content-editor to go to Sitecore and manually publish something at an inconvenient hour, e.g. a New Year’s announcement. Scheduled Publish intends to give the content-editor all features of a normal publish with the addition of automation, timing and notifications.

## Source:

- [Source](https://github.com/nehemiahj/SCScheduledPublishing/tree/master/src/Foundation/ScheduledPublish) is updated to Sitecore 10.5.
- [Sitecore Content Serialization](https://doc.sitecore.com/xp/en/developers/102/developer-tools/sitecore-content-serialization.html) is used to serialize the content. Use Sitecore CLI to Push and Pull the content.

## Setup:

| Sitecore version | Install options |
| --- | --- |
| 10.5 | NuGet, file-drop IAR zip, Docker image, source + Sitecore CLI (see [Sitecore 10.5](#sitecore-105)) |
| 10.2 – 10.4.1 | Sitecore package via Installation Wizard ([Packages](https://github.com/nehemiahj/SCScheduledPublishing/tree/master/Packages)), Docker image, source |

### Sitecore 10.5

Sitecore 10.5 disables Package Designer, and keeping it disabled is recommended. Starting with 10.5, Scheduled Publish ships **only** as an Items as Resources (IAR) build. All module items (templates, settings, task schedule, core ribbon/gutter/field types) are in `.dat` resource files, so the module installs as plain files. No Package Designer, Installation Wizard, or database writes are needed.

The module consists of these files:

```
bin/ScheduledPublish.dll
App_Config/Include/ZZ_ScheduledPublish/ZZ_ScheduledPublishControl.config
App_Data/items/master/items.master.schedule.publish.dat
App_Data/items/core/items.core.schedule.publish.dat
sitecore/shell/Applications/Content Manager/Dialogs/Schedule Publish/Schedule Publish.xml
sitecore/shell/Applications/Content Manager/Dialogs/Edit Scheduled Publish/Edit Scheduled Publish.xml
```

Pick one of the following:

1.  **NuGet** (recommended for solutions with a CI/CD pipeline). Add the package to your Sitecore web project:

    ```
    dotnet add package SCScheduledPublish --version 10.5.0
    ```

    The DLL is referenced as usual. The config, IAR and dialog files are added to the web project's publish output, at the paths listed above. Deploy the web project the way you normally do (Web Deploy, PaaS pipeline, or Docker build).
2.  **File-drop zip**. Download `Sitecore Schedule Publish-10.5.0 IAR (files).zip` from [Packages](https://github.com/nehemiahj/SCScheduledPublishing/tree/master/Packages) or the GitHub release, and extract it into the CM (and CD) webroot. On Azure PaaS, use Kudu / the zip deploy API. In a Docker image, add it to your CM Dockerfile:

    ```dockerfile
    COPY ./scheduled-publish/ C:/inetpub/wwwroot/
    ```

    Recycle the app pool (or restart the container) afterwards.
3.  **Docker image**. A Sitecore module asset image (CM only) is available on [Docker Hub](https://hub.docker.com/r/nehemiah/sitecore-scheduled-publish):
    - `nehemiah/sitecore-scheduled-publish:10.5-ltsc2022`: Windows Server 2022 base
    - `nehemiah/sitecore-scheduled-publish:10.5-1809`: Windows Server 2019 base

    The image contains the module files under `\module\cm\content`. Copy them into your CM image:

    ```dockerfile
    ARG BASE_IMAGE
    ARG SCHEDULED_PUBLISH_IMAGE=nehemiah/sitecore-scheduled-publish:10.5-ltsc2022

    FROM ${SCHEDULED_PUBLISH_IMAGE} AS scheduledpublish

    FROM ${BASE_IMAGE}
    ...
    COPY --from=scheduledpublish \module\cm\content .\
    ```
4.  **From source**. Clone the repo and add the project to your solution. Deploy the files, then either:
    - push the items to the database with the Sitecore CLI: `dotnet sitecore ser push -i ScheduledPublish`, or
    - generate the IAR files: `dotnet sitecore itemres create -i ScheduledPublish -o <webroot>/App_Data/items/schedule.publish`, then move each `items.<db>.schedule.publish.dat` into `App_Data/items/<db>/`.

**Verify the install:**
- The Content Editor **Publish** ribbon shows the **Scheduled Publish** strip.
- `/sitecore/system/Tasks/Schedules/ScheduledPublishTask` and `/sitecore/system/Modules/Scheduled Publish` exist.
- `/sitecore/admin/showconfig.aspx` contains the `ZZ_ScheduledPublish` settings.

**Upgrading an instance that had the module installed with the Installation Wizard** (non-IAR package): those items are in the database and take precedence over the IAR copies, so module updates from the `.dat` files would stay hidden. After deploying the 10.5 files, remove the database copies with:

```
dotnet sitecore itemres cleanup --what-if                                   # preview
dotnet sitecore itemres cleanup -p "/sitecore/templates/Scheduled Publish" -r
```

Run the second command for each root path in `ScheduledPublish.module.json`. Without `-p`, it cleans up every database item that has an IAR copy. Items whose fields differ from the IAR copy are skipped unless you add `--force`. Or delete the module items listed in `ScheduledPublish.module.json` from the master and core databases. Items created by editors under `/sitecore/system/Modules/Scheduled Publish/Publish Schedules` aren't part of the IAR files. Keep them.

**Uninstall:** delete the six files listed above and recycle the app pool.

### Sitecore 10.2 – 10.4.1

1.  Install the package for your version from [Packages](https://github.com/nehemiahj/SCScheduledPublishing/tree/master/Packages) with the Installation Wizard. From 10.3 onward, an IAR variant is available.
2.  Clone source and add it in solution.
3.  Use Docker Image from [Docker Hub](https://hub.docker.com/r/nehemiah/sitecore-scheduled-publish).
    - `nehemiah/sitecore-scheduled-publish:latest` - v10.4 & IAR
    - `nehemiah/sitecore-scheduled-publish:10.4-1809` - v10.4 & IAR
    - `nehemiah/sitecore-scheduled-publish:10.3-1809` - v10.3
    - `nehemiah/sitecore-scheduled-publish:10.2-1809` - v10.2
    - more...

### Building the release (maintainers)

```
pwsh ./scripts/Build-Package.ps1 -Version 10.5.0
```

The script generates the IAR files with `dotnet sitecore itemres create`, builds the DLL, and writes the file-drop zip and the `.nupkg` to `artifacts/`. It also copies the zip to `Packages/`. Package Designer isn't used.

To also build the Docker module asset images, run on Windows with Docker in Windows-container mode:

```
pwsh ./scripts/Build-Package.ps1 -Version 10.5.0 -DockerRepository nehemiah/sitecore-scheduled-publish
docker push nehemiah/sitecore-scheduled-publish:10.5-ltsc2022
docker push nehemiah/sitecore-scheduled-publish:10.5-1809
```

This builds one image per base in `-DockerBases` (default `ltsc2022`, `1809`) from `docker/Dockerfile`, tagged `<version>-<base>`. The images contain `\module\cm\content`, the same files as the zip. The [docker asset image creator](https://github.com/KayeeNL/sitecore-module-docker-asset-image-creator) isn't needed for 10.5: it converts Installation Wizard packages, and the 10.5 release is already plain files.

Pushing a `Sitecore_10.5*` tag runs `.github/workflows/release.yml`. That workflow builds the same artifacts, attaches them to a GitHub release, and publishes the NuGet package to nuget.org with [Trusted Publishing](https://learn.microsoft.com/nuget/nuget-org/trusted-publishing), so no API key is stored in the repo.

## Features:

- Scheduled Publish
- Scheduled Unpublish
- Edit publish schedule
- Date and time can be customized
- Warning if the content-editor selects a date that has already passed
- Check if the item is in a valid publishing state
- Check if the item’s publishing restrictions allow publishing according to the desired schedule
- Target database to which to publish
- Language versions which to publish
- Publish modes
- Publish Children
- Frequency of checks whether there are items queued for publishing
- Simple interface
- Customizable email notifications

## Guide:

This is how the Scheduled Publish strip in the Publish Ribbon:

![enter image description here](https://raw.githubusercontent.com/nehemiahj/images/main/Publish%201.PNG)

Content-editors can still use the well-known Publish button for all publish methods they are used to. The Schedule Publish button is what is used only for scheduling a future publish.
The Schedule Publish strip consists of three buttons:

- Schedule Publish button for scheduling a future publishing of the current item
- Schedule Unpublish button for scheduling a future unpublishing of the current item
- Edit Schedule button where the content editor can review, edit and delete any of the existing schedules for any items.

## Schedule Publish:

This is how the Scheduled Publish dialog looks like:

![enter image description here](https://raw.githubusercontent.com/nehemiahj/images/main/Publish%202.PNG)

Please note that the current server time will be used when scheduling and it is indicated in the Scheduled Publish Settings block.

Any existing schedules for the selected item will display in order in the Existing Schedules block. If there are none, this will be indicated.

As you see the input is fairly common to Sitecore’s Publish, with the addition of two dropdown menus.
From the first drop down the content-editors choose a date when to publish. If they choose a date that has passed, they will receive a warning and be returned to the dialog again until they choose a valid date:

![enter image description here](https://raw.githubusercontent.com/nehemiahj/images/main/Publish%203.PNG)

From the second dropdown, content-editors should choose an approximate time for publishing. It is approximate since the actual time of publishing will be the time they set +/- the frequency of the check for items for publishing queued.

![enter image description here](https://raw.githubusercontent.com/nehemiahj/images/main/Publish%204.PNG)

Sitecore displays only hours and halves, but they can be manually edited afterwards, as long as the time format is kept.

If there are already scheduled publishes for the particular item, a list of these will appear above. The list will show all dates and corresponding hours for publishing for the item in order.

![enter image description here](https://raw.githubusercontent.com/nehemiahj/images/main/Publish%205.PNG)

## Schedule Unpublish:

The Schedule Unpublish dialog is identical to the Schedule Publish one, only it will remove an item from the website at the selected time.

## Edit Publish:

The Edit Schedule button will pop the Edit Scheduled Publishing dialog.

Note: this dialog will list all scheduled publishes by date, not just the scheduled publishes for the currently selected item.

![enter image description here](https://raw.githubusercontent.com/nehemiahj/images/main/Publish%206.PNG)

The first column – Item - shows the name of the item and its path, since there may be items with the same name in different locations, especially in a multi-site environment.

The second column – Action – notifies whether the item is scheduled for Publish or Unpublish.

The third column – Date – first shows the current date and time of the schedule, and then two drop down menus for date and time respectively. The first line will not change when you select a different value below – it is just for reference. If you save the new value for any item, the first line will display this new value on reopening the Edit Scheduled Publishing dialog.

The fourth column – Delete – consists of a checkbox. Checking that checkbox will delete the selected schedule upon hitting ‘OK’.

## Publish Notification:

Scheduled Publish can be customized to send a notification to the content editor who assigned it and other users when a publish takes place. The email settings can be found under Sitecore/System/Modules/Scheduled Publish.
The Settings item contains a checkbox whether email notifications should be sent upon publish.

![enter image description here](https://raw.githubusercontent.com/nehemiahj/images/main/Publish%207.PNG)

The Scheduled Publish Email Settings item contains mail server info. It can be used to input a mail server or to set a mail server from web.config to be used. Read access to this item can be denied to some content-editors.

The Scheduled Publish Email item contains all fields for a nice, content-managed email.

If notification is enabled, the content-editor who assigned scheduled publish on an item will always receive an email in the mailbox they have input in their Sitecore profile. Additionally, the “To” field can accept a list of comma-separated email addresses. These emails will receive an email on every scheduled publish.

The name of the published item can be added to the Subject of the received email using the “[item]” placeholder for it.

## Email Tokens:

There are several placeholders available in the Message field as well so the mail message’s body is very flexible. It can contain anything the content-editor inputs, plus allows the following replacements:

[id] - the id of the item being published

[item] - name of the item being published

[path] - path of the item being published in the content tree

[date] - date when the publishing took place

[time] - the time when the publishing took place

[version] - the version of the item which was published

## Job Interval Configuration:

This module utilizes a scheduled task in the master database to manage content publishing. This task processes pending publish requests at regular intervals, defined by both global scheduling frequency and individual settings at the master database agent level. To ensure optimal performance, carefully consider the impact of increasing the frequency, as it can add load to the Content Management (CM) instance.

```xml
<scheduling>
	<!--  Time between checking for scheduled tasks waiting to execute  -->
	<!-- SCHEDULAR GLOBAL INTERVAL TIME -->
	<frequency>00:00:05</frequency>
	<!--  An agent that processes scheduled tasks embedded as items in the master database.  -->
	<!-- SCHEDULAR MASTER DB INTERVAL TIME -->
	<agent name="Master_Database_Agent" type="Sitecore.Tasks.DatabaseAgent" method="Run" interval="00:10:00" />
</scheduling>
```
