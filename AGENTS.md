# Render API Agent Instructions

## YOU MUST UPDATE `FAILURE_LOG.md` AFTER EVERY SINGLE CHANGE TO ANY CODE FILE IN THE REPO, EVERY SINGLE RENDER DEPLOYMENT, EVERY SINGLE CHANGE TO RENDER CONFIGURATION E.G. DOCKER COMMAND, ETC. NO EXCEPTIONS.

## Context

This repository is for managing the primary front-end web service of a self-hosted n8n instance on Render. 

The project has an associated n8n background worker repo at `chriswinsatlife/n8n-background-worker`.

The project has other services on Render, including a Postgres DB and Redis service, listed below.

## Render Web Services & Docker

- THERE IS LITERALLY NO SUCH THING AS FUCKING CMD ARGS IN RENDER
- THERE IS DOCKERFILE PATH, DOCKER BUILD CONTEXT DIRECTORY, DOCKER COMMAND, PRE-DEPLOY COMMAND, AND THAT'S FUCKING IT

## Notes
- The Render background worker has a Docker command field filled; it has changed many times
- The Render background worker repo has no Dockerfile; it simply references the Dockerfile in this `n8n-render` repo
- n8n background worker service on Render fails at runtime with /usr/bin/env: 'node': No such file or directory despite successful Docker builds.
- n8n 2.1.0+ removed apk-tools from their Alpine image. The community workaround to reinstall apk-tools works for BUILD but fails at RUNTIME on Render specifically.
- The web service works because it has no dockerCommand - it uses the image's default ENTRYPOINT which properly sets up the environment.

## Rules of Engagement
- Never ask the user to push code, make a commit, check GitHub, check Render, deploy on Render, inspect Render logs, etc; you MUST do this yourself in 100% of instances with CLI or API cURL
- Never ask for details like service IDs, deploy IDs, etc. Look these up on your own.
- Use the Exa tool to search for context regarding code, build issues, packages, etc.

## n8n Background Worker Configuration
- You can see the sole meaningful file in this repo by using `cat ~/GitHub/n8n-background-worker/render.yaml`
- The background worker is primarily configured in Render's web app admin, not the GitHub repo

## Render CLI

The Render CLI is installed. Use `render --help` for details.

You will find these in `.env` if you `source`:
- `RENDER_API_KEY`
- `RENDER_SERVICE_ID`
- `RENDER_OWNER_ID`

## GitHub Details

The n8n worker is at:
`chriswinsatlife/n8n-background-worker`

The only file of note for the background worker is:
- `render.yaml`

This repository is the `n8n-render` repository.

The n8n web service is at:
`chriswinsatlife/n8n-render`

Key files are:
- `Dockerfile`
- `render.yaml`
- `.github/workflows/auto-merge.yml`
- `render_queue_mode.yaml`

The worker is the primary service running the application and workflows; the web service is just the front-end.

## Render Service IDs

Use the below service IDs to inspect the Render deployments, services, logs, etc.

### n8n Worker Render ID
srv-d117ruqdbo4c739o7bhg

### n8n Web Service Render ID
srv-cmr5odgl5elc73ahtm40

### n8n Redis Render ID
red-d1012l3ipnbc738dbk70

### n8n DB Render ID
dpg-cjgkpc41ja0c73a8g8s0-a


## API Details

### Context

The Render API supports almost all of the same functionality available in the Render Dashboard. It includes endpoints for managing:
* Services and datastores
* Deploys
* Environment groups
* Blueprints
* Metrics and logs
* Projects and environments
* Custom domains
* One-off jobs
* Audit logs
* Additional account settings

The full API reference is available at [https://api-docs.render.com/reference/].

## Example Render API calls

### List Render Services

```bash
curl --request GET \
     --url "https://api.render.com/v1/services?limit=10" \
     --header "Accept: application/json" \
     --header "Authorization: Bearer ${RENDER_API_KEY}"
```

### Get Logs for n8n Worker Service

```bash
curl --request GET \
     --url "https://api.render.com/v1/logs?ownerId=${RENDER_OWNER_ID}&direction=backward&resource=srv-d117ruqdbo4c739o7bhg&limit=20" \
     --header "accept: application/json" \
     --header "authorization: Bearer ${RENDER_API_KEY}"
```

### Get Logs for n8n Main Service

```bash
curl --request GET \
     --url "https://api.render.com/v1/logs?ownerId=${RENDER_OWNER_ID}&direction=backward&resource=srv-cmr5odgl5elc73ahtm40&limit=20" \
     --header "accept: application/json" \
     --header "authorization: Bearer ${RENDER_API_KEY}"
```

### Get Logs for n8n Redis Service

```bash
curl --request GET \
     --url "https://api.render.com/v1/logs?ownerId=${RENDER_OWNER_ID}&direction=backward&resource=red-d1012l3ipnbc738dbk70&limit=20" \
     --header "accept: application/json" \
     --header "authorization: Bearer ${RENDER_API_KEY}"
```

## YOU MUST UPDATE `FAILURE_LOG.md` AFTER EVERY SINGLE CHANGE TO ANY CODE FILE IN THE REPO, EVERY SINGLE RENDER DEPLOYMENT, EVERY SINGLE CHANGE TO RENDER CONFIGURATION E.G. DOCKER COMMAND, ETC. NO EXCEPTIONS.
