# Sitecore module asset image for Scheduled Publish (CM only).
# Built by scripts/Build-Package.ps1 -DockerRepository <repo>; the build context is artifacts/docker.
#
# Use it in a CM Dockerfile:
#   FROM <repo>:<tag> AS scheduledpublish
#   COPY --from=scheduledpublish \module\cm\content .\
ARG BASE_IMAGE=mcr.microsoft.com/windows/nanoserver:ltsc2022
FROM ${BASE_IMAGE}

COPY module/ /module/
