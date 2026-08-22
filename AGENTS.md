# Render Operations Instructions

Read `FAILURE_LOG.md` and `docs/render_operations.md` before inspecting or changing this repository. The operations document contains the last verified live Render snapshot, its WITA timestamp, the authority order, and read-only inspection commands.

## Source of Truth

- Live Render API and Dashboard are authoritative for service type, plans, resource IDs, environment values, disks, commands, image references, and deployed image digests.
- GitHub `main` is authoritative for the web service Dockerfile and GitHub Actions workflows.
- Local documentation is explanatory and becomes stale after a live deployment, Render configuration change, GitHub workflow change, or image update.
- `render.yaml` is an empty, historical, non-authoritative Blueprint placeholder. Never apply it to the existing grandfathered project.
- `render_queue_mode.yaml` is a historical, non-authoritative queue-mode draft. Never apply it to the existing grandfathered project.
- `~/github/n8n-background-worker/render.yaml` is a historical export describing three Docker workers. The live project has one image-backed worker.

## Live Service Roles

- `n8n` is the main web service. It serves the UI, API, and triggers, and is built from this repository’s `Dockerfile`.
- `n8n-background-worker-1` is the execution worker. It is a Render image-backed background worker running `n8n worker --concurrency=10`.
- PostgreSQL stores n8n state and execution data.
- Redis carries the queue between the main process and worker.

The main service and worker are one queue-mode system. They must continue to share the database, Redis, and main instance encryption key. Do not update one independently without an explicit compatibility decision.

## Update and Deploy Behavior

### Web Service

- `.github/dependabot.yml` checks the Docker base image monthly.
- The current configuration checks monthly and allows minor and patch version updates to be proposed.
- `.github/workflows/auto-merge.yml` requests automatic merging for Dependabot pull requests. Required checks and branch protection still control whether GitHub merges them.
- Render’s Git-backed web service is configured to deploy after a merged commit reaches `main`.
- The duplicate Render Blueprint `n8n-new` was disconnected on 2026-08-22 because it had zero managed resources and was syncing the stale historical Blueprint file.

This is the configured monthly check and auto-merge path for the web service. The latest observed Dependabot pull request and auto-merge run were on 2025-12-24; no 2026 run was found in the 2026-08-22 audit. Confirm actual Dependabot runs and resulting Render deploys instead of assuming the schedule has executed.

### Background Worker

- The worker currently uses `docker.io/n8nio/n8n:2.35.7`.
- Render’s image-backed services do not automatically redeploy when a registry tag changes. The worker requires a manual deploy, deploy hook, or API trigger to pull a newer image.
- The Render API may show `autoDeploy: yes` and `autoDeployTrigger: commit` for the worker. Because the worker has no linked repository and uses a prebuilt image, those fields are not a Docker Hub tag watcher.
- No local GitHub Action, LaunchAgent, or n8n workflow referencing the worker service ID or deploy hook was found during the 2026-08-22 inspection.

GitHub reported automated security fixes enabled and no open Dependabot alerts during the 2026-08-22 audit.

## Required Inspection

Before deciding that any local file describes the current deployment:

- Run the service inspection command in `docs/render_operations.md`.
- Run the deploy-history commands for both n8n services.
- Record the current WITA timestamp, latest deploy IDs, worker image digest, and relevant `updatedAt` values.
- Compare the local repository with GitHub `main` using `git status`, `git rev-parse`, and `git ls-remote`.
- Check `https://n8n-naps.onrender.com/healthz` and recent logs when validating a live deployment.

Treat the snapshot as stale if any live resource, deploy, image digest, GitHub workflow, or repository configuration changed after its timestamp. Refresh the snapshot instead of guessing.

Do not save or publish environment variables, API responses containing secrets, deploy-hook URLs, or credential values.

## Deployment Safety

- Do not use n8n’s one-line installer or Docker Compose for this Render-hosted setup.
- Do not apply a historical Blueprint to the existing project.
- Do not recreate services, change plans, replace disks, or alter environment values merely to make a historical Blueprint validate.
- Do not trigger a Render deployment or restart without explicit authorization for that live operation.
- Before an approved update, inspect the live state and record a fresh timestamp.
- After every approved Render deployment or Render configuration change, update `FAILURE_LOG.md` with the deploy ID, trigger, result, image digest when applicable, and local WITA timestamp.
- After changing this repository’s deployment-related code or configuration, update `FAILURE_LOG.md`.

## Repository Map

- `Dockerfile`: base image declaration used by the main web service.
- `.github/dependabot.yml`: monthly Docker image update schedule and version-update policy.
- `.github/workflows/auto-merge.yml`: Dependabot pull-request auto-merge workflow.
- `docs/render_operations.md`: canonical live-state snapshot and inspection procedure.
- `render.yaml`: empty historical Blueprint placeholder; do not apply.
- `render_queue_mode.yaml`: historical queue-mode Blueprint draft; do not apply.
- `FAILURE_LOG.md`: operational history and reconciliation record.

## Historical Incident Notes

The repository contains historical notes about failed attempts to add packages to the n8n image and to convert the worker from image runtime to Docker runtime. Those notes are not the current deployment configuration. Do not treat historical workaround text as a reason to change the live service.

## Official References

- [Render image deployment](https://render.com/docs/deploying-an-image)
- [Render deploys](https://render.com/docs/deploys)
- [Render deploy hooks](https://render.com/docs/deploy-hooks)
- [n8n queue mode](https://docs.n8n.io/deploy/host-n8n/configure-n8n/scaling/enable-queue-mode)
