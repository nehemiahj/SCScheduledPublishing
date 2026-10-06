# Sitecore Scheduled Publish – module asset image

[Sitecore Scheduled Publish](https://github.com/nehemiahj/SCScheduledPublishing) lets content editors schedule a publish or unpublish of an item for a future date and time, with notifications. Pages or features can be prepared and previewed long before they go live, without the risk of an accidental early publish.

This is a **Sitecore module asset image**. You don't run it. You copy its files into your own Sitecore CM image when you build it.

## Tags

| Tag | Sitecore | Windows base | Items |
| --- | --- | --- | --- |
| `10.5-ltsc2025` | 10.5 | Server 2025 (`ltsc2025`) | IAR |
| `10.5-ltsc2022`, `latest` | 10.5 | Server 2022 (`ltsc2022`) | IAR |
| `10.4.1-ltsc2022` | 10.4.1 | Server 2022 (`ltsc2022`) | IAR |
| `10.4.1-1809` | 10.4.1 | Server 2019 (`1809`) | IAR |
| `10.4-ltsc2022` | 10.4 | Server 2022 (`ltsc2022`) | IAR |
| `10.4-1809` | 10.4 | Server 2019 (`1809`) | IAR |
| `10.3-1809` | 10.3 | Server 2019 (`1809`) | |
| `10.2-1809` | 10.2 | Server 2019 (`1809`) | |

Pick the tag that matches your Sitecore version and the Windows base of your CM image. Windows Server 2025 containers are supported from Sitecore 10.5, and Sitecore 10.5 no longer supports Windows Server 2019 (`1809` / `ltsc2019`), so there is no 10.5 `1809` image.

## Usage

Add the module to your CM image's Dockerfile:

```dockerfile
ARG BASE_IMAGE
ARG SCHEDULED_PUBLISH_IMAGE=nehemiah/sitecore-scheduled-publish:10.5-ltsc2022

FROM ${SCHEDULED_PUBLISH_IMAGE} AS scheduledpublish

FROM ${BASE_IMAGE}
...
COPY --from=scheduledpublish \module\cm\content .\
```

Then rebuild the CM image (`docker compose build cm`).

The image contains CM content only. The module is used from the Content Editor, so there are no CD, database or Solr layers.

## What's inside

```
\module\cm\content\
  bin\ScheduledPublish.dll
  App_Config\Include\ZZ_ScheduledPublish\ZZ_ScheduledPublishControl.config
  App_Data\items\master\items.master.schedule.publish.dat
  App_Data\items\core\items.core.schedule.publish.dat
  sitecore\shell\Applications\Content Manager\Dialogs\Schedule Publish\Schedule Publish.xml
  sitecore\shell\Applications\Content Manager\Dialogs\Edit Scheduled Publish\Edit Scheduled Publish.xml
```

From 10.4 onward, the module's items (templates, settings, the scheduled task, and the core ribbon, gutter and field types) ship as **Items as Resources (IAR)** `.dat` files. Copying the files is the whole installation: there's no package to install and no database step. This also works on Sitecore 10.5, where Package Designer is disabled.

**Upgrading** an environment where the module was once installed with the Installation Wizard: the database copies of the items take precedence over the IAR files. Remove them once with `dotnet sitecore itemres cleanup`. See the [upgrade notes](https://github.com/nehemiahj/SCScheduledPublishing#sitecore-105).

## Verify

- The Content Editor **Publish** ribbon shows the **Scheduled Publish** strip.
- `/sitecore/system/Tasks/Schedules/ScheduledPublishTask` exists.

## Image labels

10.5 images include OCI labels with the version, the source commit and the build date:

```
docker inspect nehemiah/sitecore-scheduled-publish:10.5-ltsc2022 --format "{{json .Config.Labels}}"
```

## Other ways to install

- **NuGet**: [`SCScheduledPublish`](https://www.nuget.org/packages/SCScheduledPublish)
- **File-drop zip**: [GitHub releases](https://github.com/nehemiahj/SCScheduledPublishing/releases)
- **Source and documentation**: [GitHub](https://github.com/nehemiahj/SCScheduledPublishing)

License: Apache-2.0
