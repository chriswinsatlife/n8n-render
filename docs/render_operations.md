# Render Operations

Last verified: 2026-08-22 11:24:00 WITA

This document records the live Render configuration and the commands used to verify it. The live Render service snapshot was collected at 2026-08-22 10:47:57 WITA. The GitHub automation audit was completed at 2026-08-22 11:10:36 WITA. Treat this document as stale when a Render service, deploy, image, GitHub workflow, or repository configuration changes after the timestamp.

## Authority Order

- Live Render API and Dashboard are authoritative for service type, plans, resource IDs, environment values, disks, commands, image references, and deployed image digests.
- GitHub `main` is authoritative for the web service Dockerfile and GitHub Actions workflows.
- This document and `AGENTS.md` explain how to inspect the live state. They are not a replacement for a live Render inspection.
- `render.yaml` is an empty historical, non-authoritative Blueprint placeholder. Do not apply it to the existing project.
- `render_queue_mode.yaml` is a historical, non-authoritative queue-mode draft. Do not apply it to the existing project.
- `~/github/n8n-background-worker/render.yaml` is also a historical Render export. It describes three Docker workers, while the live project has one image-backed worker.

## Live Render Project

- Workspace: `CYHQ`, owner ID `tea-cspvavogph6c739fg9o0`
- Project: `n8n`, project ID `prj-d117j42dbo4c739nuin0`
- Environment: `Production`, environment ID `evm-d117j42dbo4c739nuing`
- Region: Oregon

## Current Services

### Main Web Service

- Name: `n8n`
- Render service ID: `srv-cmr5odgl5elc73ahtm40`
- Type: web service
- Plan: standard
- Runtime: Docker
- Repository: `https://github.com/chriswinsatlife/n8n-render`
- Branch: `main`
- Dockerfile: `./Dockerfile`
- Docker context: `.`
- Docker command: empty; the image default starts n8n
- Health check: `/`
- Instances: 1
- Persistent disk: 5 GB at `/home/node`
- Public Render URL: `https://n8n-naps.onrender.com`
- Render auto-deploy setting: commit
- Last observed live deploy: `dep-da4h9t5ckfvc73ciu1e0`, new commit, 2026-08-22 11:18:33 WITA

The current repository Dockerfile contains `FROM n8nio/n8n:2.35.7`. A GitHub commit is required before this Git-backed Render service rebuilds and deploys.

### Background Worker

- Name: `n8n-background-worker-1`
- Render service ID: `srv-d117ruqdbo4c739o7bhg`
- Type: background worker
- Plan: standard
- Runtime: prebuilt image
- Image reference: `docker.io/n8nio/n8n:2.35.7`
- Command: `n8n worker --concurrency=10`
- Instances: 1
- Persistent disk: 5 GB at `/home/node/.n8n`
- Render API auto-deploy field: commit
- Last observed live deploy: `dep-da4hbl8n74is73dl14hg`, API, 2026-08-22 11:21:59 WITA
- Last observed image digest: `sha256:f410270e715c795b4935eb16f94c099f7aee8da81c340c9842e76f0d5e716ff3`
- Last observed image digest: `sha256:00220887605660bbd1aa79ff63b4761759d875fc27bcf013dc754bc3b7f6215c`

The worker has no linked Git repository. Render documents that image-backed services do not automatically redeploy when a registry tag such as `latest` changes. A manual deploy, deploy hook, or API trigger is required to pull a newer image. The `autoDeploy` and `autoDeployTrigger` fields must not be interpreted as a Docker Hub tag watcher.

No local GitHub Action, LaunchAgent, or n8n workflow referencing this worker’s Render service ID or deploy hook was found during the 2026-08-22 inspection.

### Database

- Name: `n8n-database`
- Render database ID: `dpg-cjgkpc41ja0c73a8g8s0-a`
- Plan: standard
- PostgreSQL version: 15
- Region: Oregon
- Status at last inspection: available

### Redis

- Name: `n8n-redis`
- Render service ID: `red-d1012l3ipnbc738dbk70`
- Plan: starter
- Redis version: 8.1.4
- Region: Oregon
- Persistence mode: journal snapshot
- Maxmemory policy: allkeys-lru
- Status at last inspection: available

## Current Update Paths

### Web Service Path

- Dependabot checks the Docker base image monthly, according to `.github/dependabot.yml`.
- The current Dependabot configuration checks monthly and allows minor and patch version updates.
- `.github/workflows/auto-merge.yml` asks GitHub to auto-merge Dependabot pull requests. GitHub still applies required checks and branch protection rules.
- After a merged commit reaches `main`, Render’s Git-backed web service is configured to auto-deploy that commit.

This is a configured monthly check and auto-merge path for the web service. The latest observed Dependabot pull request and auto-merge run were both on 2025-12-24. No 2026 Dependabot pull request or auto-merge run was found in the audit. The 2026-08-10 web deploy was triggered by a new commit containing the Dependabot-throttling configuration; it was not an n8n version update and was not attributed to Dependabot. It is not an automatic Docker Hub image-refresh path for the worker.

GitHub reports automated security fixes enabled and no open Dependabot alerts at the audit timestamp. This confirms repository security-update settings, not that n8n image vulnerabilities are completely covered.

### Worker Path

- The worker remains on the image digest from its last successful deploy until another deploy is triggered.
- A Render Dashboard manual deploy, Render CLI deploy, deploy hook, or Render API trigger can pull the current tag or a specified tag/digest.
- Do not update the worker independently from the main service. Queue mode uses the main process, worker, Redis, database, and shared encryption key as one system.

### Manual and Emergency Path

- Use a manual deploy for an approved worker update, emergency security update, or recovery.
- Record the old and new image references and digests before and after the deploy.
- Verify the web health endpoint, recent web logs, recent worker logs, and one real workflow execution.
- Update this document’s timestamp and `FAILURE_LOG.md` after the live state changes.

## Read-Only Inspection

Run these commands from any directory after Render CLI authentication. They do not deploy, restart, update, or delete anything.

### Inspect Current Services

```bash
render services --output json | jq -r '
  .[] |
  if .service? then .service
  elif .postgres? then .postgres
  elif .keyValue? then .keyValue
  else empty
  end |
  select(.name == "n8n" or .name == "n8n-background-worker-1" or .name == "n8n-database" or .name == "n8n-redis") |
  {id, name, type, plan: (.plan // .serviceDetails.plan), region: (.region // .serviceDetails.region), runtime: (.runtime // .serviceDetails.runtime), autoDeploy, autoDeployTrigger, repo, branch, imagePath, serviceDetails, version, status, updatedAt}
'
```

### Inspect Deploy History

```bash
render deploys list srv-cmr5odgl5elc73ahtm40 --output json | jq '.[0:10] | map({id, status, trigger, createdAt, finishedAt, image})'
render deploys list srv-d117ruqdbo4c739o7bhg --output json | jq '.[0:10] | map({id, status, trigger, createdAt, finishedAt, image})'
```

### Inspect Logs

```bash
render logs --resources srv-cmr5odgl5elc73ahtm40 --limit 100 --output json
render logs --resources srv-d117ruqdbo4c739o7bhg --limit 100 --output json
```

Do not save or publish environment variables, API responses containing secrets, deploy-hook URLs, or credential values.

### Check Public Health

```bash
curl --fail --silent --show-error https://n8n-naps.onrender.com/healthz
```

### Check GitHub State

```bash
git -C ~/github/n8n-render status --short
git -C ~/github/n8n-render rev-parse HEAD
git ls-remote https://github.com/chriswinsatlife/n8n-render.git refs/heads/main
curl --fail --silent https://raw.githubusercontent.com/chriswinsatlife/n8n-render/main/.github/dependabot.yml
```

Compare the local files with GitHub `main` before deciding that a local document or configuration file is current.

## Deployment Rules

- Do not use n8n’s one-line installer or Docker Compose for this Render-hosted instance.
- Do not apply a Blueprint from this repository or the worker repository to the existing project.
- Do not recreate services, change plans, replace disks, or alter environment values to make a historical Blueprint validate.
- Do not trigger a Render deploy or restart without explicit authorization for that live operation.
- Before any approved update, inspect the live state and record a fresh timestamp.
- After any approved Render deployment or Render configuration change, update `FAILURE_LOG.md` with the deploy ID, trigger, result, image digest when applicable, and local WITA timestamp.

## Official References

- [Render image deployment](https://render.com/docs/deploying-an-image)
- [Render deploys](https://render.com/docs/deploys)
- [Render deploy hooks](https://render.com/docs/deploy-hooks)
- [n8n queue mode](https://docs.n8n.io/deploy/host-n8n/configure-n8n/scaling/enable-queue-mode)
