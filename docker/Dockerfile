# Sitecore module asset image for Scheduled Publish (CM only).
# Built by scripts/Build-Package.ps1 -DockerRepository <repo>; the build context is artifacts/docker.
#
# Use it in a CM Dockerfile:
#   FROM <repo>:<tag> AS scheduledpublish
#   COPY --from=scheduledpublish \module\cm\content .\
ARG BASE_IMAGE=mcr.microsoft.com/windows/nanoserver:ltsc2022
FROM ${BASE_IMAGE}

ARG VERSION=dev
ARG REVISION=unknown
ARG CREATED=unknown
ARG BASE_IMAGE

LABEL org.opencontainers.image.title="Sitecore Scheduled Publish" \
      org.opencontainers.image.description="Sitecore module asset image (CM only). Copy \\module\\cm\\content into the CM webroot. Items ship as Items as Resources (IAR) files; no package install or database step is needed." \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${REVISION}" \
      org.opencontainers.image.created="${CREATED}" \
      org.opencontainers.image.source="https://github.com/nehemiahj/SCScheduledPublishing" \
      org.opencontainers.image.url="https://hub.docker.com/r/nehemiah/sitecore-scheduled-publish" \
      org.opencontainers.image.documentation="https://github.com/nehemiahj/SCScheduledPublishing#sitecore-105" \
      org.opencontainers.image.authors="Nehemiah Jeyakumar" \
      org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.base.name="${BASE_IMAGE}"

COPY module/ /module/
