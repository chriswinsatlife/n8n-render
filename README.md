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
- The worker is an image-backed Render service using `docker.io/n8nio/n8n:2.35.7` and `n8n worker --concurrency=10`.

The Render dashboard and API are the source of truth for service type, plan, resource IDs, environment values, disks, and the worker image. Do not recreate these resources from an old Blueprint.

No active Render Blueprint is connected to this repository. The duplicate `n8n-new` Blueprint was disconnected after its zero-resource sync began failing on the obsolete historical Postgres plan.

## Update Paths

The web service follows this path:

- Dependabot checks the pinned `n8nio/n8n:2.35.7` Docker base image weekly.
- Dependabot can propose minor and patch updates.
- The repository workflow enables automatic merging for Dependabot pull requests.
- Render automatically deploys the web service after the merged GitHub commit.
- `.github/workflows/deploy-worker-after-web.yml` waits for that web deployment to be live and healthy, then reconciles the worker to the same pinned image through the Render API.
- The coordinator also runs weekly, so a failed worker update is retried at the next scheduled run. It does not redeploy the worker when the configured image and latest live worker image already match.

Render’s image-backed worker does not follow Docker Hub tag updates by itself. The GitHub coordinator supplies the explicit image setting and deploy request only after the web service for the same repository commit is live and healthy. The encrypted GitHub repository secret `RENDER_API_KEY` is required for that coordinator.

## Local Files

- `Dockerfile` is the web service’s current base-image declaration.
- `.github/dependabot.yml` controls the weekly web-service image update cadence.
- `.github/workflows/auto-merge.yml` handles Dependabot pull requests.
- `.github/workflows/deploy-worker-after-web.yml` keeps the Render web service and worker on the same pinned n8n version.
- `render.yaml` is an empty historical Blueprint placeholder and must not be applied to the existing project.
- `render_queue_mode.yaml` is a historical queue-mode draft and must not be applied to the existing project.
- `FAILURE_LOG.md` records operational history and must be updated when this repository’s deployment configuration is edited.

Do not use n8n’s one-line installer or Docker Compose instructions for this Render-hosted setup. Those instructions are for a separately managed Docker host, not for the existing Render services.
