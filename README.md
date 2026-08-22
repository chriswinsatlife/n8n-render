# n8n-render

This repository supplies the Dockerfile for the live n8n web service on Render.

Do not deploy this repository as a new Render Blueprint. The existing CYHQ n8n project uses grandfathered Render resources, and the files named `render.yaml` and `render_queue_mode.yaml` are historical drafts that do not describe the live project.

For the timestamped live configuration, authority rules, read-only Render CLI commands, and deployment procedure, read [`docs/render_operations.md`](docs/render_operations.md).

## Live Setup

- Web service: `n8n`, Render service `srv-cmr5odgl5elc73ahtm40`
- Worker service: `n8n-background-worker-1`, Render service `srv-d117ruqdbo4c739o7bhg`
- Database: `n8n-database`, Render database `dpg-cjgkpc41ja0c73a8g8s0-a`
- Redis: `n8n-redis`, Render service `red-d1012l3ipnbc738dbk70`
- Both n8n services use the standard plan. The database and Redis retain their existing plans.
- The web service builds from this GitHub repository with `Dockerfile`.
- The worker is an image-backed Render service using `docker.io/n8nio/n8n:latest` and `n8n worker --concurrency=10`.

The Render dashboard and API are the source of truth for service type, plan, resource IDs, environment values, disks, and the worker image. Do not recreate these resources from an old Blueprint.

## Update Paths

The web service follows this path:

- Dependabot checks the `n8nio/n8n:latest` Docker base image monthly.
- Dependabot is configured to propose major-version updates only.
- The repository workflow enables automatic merging for Dependabot pull requests.
- Render automatically deploys the web service after the merged GitHub commit.

The worker does not follow Docker Hub tag updates automatically. Render’s image-backed service requires a manual deploy or an explicit deploy-hook/API call to pull the current `latest` image. No local scheduled updater for this worker was found.

The web service has a configured monthly Dependabot check and GitHub auto-merge path. The latest observed Dependabot pull request and auto-merge run were on 2025-12-24; no 2026 run was found in the 2026-08-22 audit. It does not automatically pull a new Docker Hub image into the worker.

Before any worker update, record the currently running image digest, confirm that the web service is healthy, and update the worker only after a separate deployment decision.

## Local Files

- `Dockerfile` is the web service’s current base-image declaration.
- `.github/dependabot.yml` controls the web-service image update cadence.
- `.github/workflows/auto-merge.yml` handles Dependabot pull requests.
- `render.yaml` is a historical web-and-database Blueprint and must not be applied to the existing project.
- `render_queue_mode.yaml` is a historical queue-mode draft and must not be applied to the existing project.
- `FAILURE_LOG.md` records operational history and must be updated when this repository’s deployment configuration is edited.

Do not use n8n’s one-line installer or Docker Compose instructions for this Render-hosted setup. Those instructions are for a separately managed Docker host, not for the existing Render services.
