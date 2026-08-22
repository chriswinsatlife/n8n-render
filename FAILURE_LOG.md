# n8n Background Worker on Render - Failure Log

> Historical record only. Commands and service-recreation procedures in old entries are not an approved runbook. Do not execute them without a separate, explicit deployment decision and a fresh live-state inspection. Use `docs/render_operations.md` for the current operating procedure.

## Service
- **Worker Service ID:** srv-d117ruqdbo4c739o7bhg
- **Dashboard:** https://dashboard.render.com/worker/srv-d117ruqdbo4c739o7bhg/settings
- **Repo:** chriswinsatlife/n8n-render (Dockerfile lives here)

## Current Status
**UP AND WORKING** - Worker running with `dockerCommand: worker --concurrency=10`

### Final Working Configuration (2025-12-26)
- **Image:** `docker.io/n8nio/n8n:latest`
- **Runtime:** `image`
- **dockerCommand:** `worker --concurrency=10`
- **Key insight:** The command `worker --concurrency=10` is passed as arguments to the image's ENTRYPOINT (`/docker-entrypoint.sh`), which properly sets up the environment before running `n8n worker --concurrency=10`

---

## Session Log (2025-12-26)

### Deploy dep-d57cateuk2gs73cve6m0 - FAILED
- **Commit:** ab677b2 - Add symlink and debug output for node verification
- **Dockerfile:** n8n:2.0.2 + apk-tools workaround + symlink `/usr/bin/node -> /usr/local/bin/node`
- **dockerCommand:** `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
- **Build:** SUCCESS - Debug output confirmed:
  - `/usr/bin/node` symlink exists
  - `/usr/bin/env node -v` returns v22.21.1
  - PATH includes `/usr/local/bin`
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **Conclusion:** Symlinks created at build time do NOT persist at Render runtime

### Deploy dep-d57cgqpr0fns73a30gmg - FAILED
- **Commit:** Explicitly set PATH in ENV to persist at runtime
- **Change:** `ENV PATH="/usr/local/bin:/usr/bin:/bin:/opt/venv/bin:$PATH"`
- **dockerCommand:** `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
- **Build:** SUCCESS - Debug shows symlink exists, `/usr/bin/env node` works
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **Conclusion:** Explicit ENV PATH also doesn't help

### Deploy dep-d57co6m3jp1c73atdahg - FAILED
- **Commit:** revert to n8n 2.0.2 and pin (exact Dockerfile from Dec 15 when it worked)
- **Dockerfile:** Clean n8n:2.0.2 with apk add (no workarounds, no symlinks, no debug)
- **dockerCommand:** `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
- **Build:** SUCCESS
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **Conclusion:** The EXACT same Dockerfile and dockerCommand that worked Dec 15 now fails

### Deploy dep-d57cq61r0fns73a339jg - FAILED
- **Commit:** 6668d5f - Add worker-entrypoint.sh and node symlink
- **dockerCommand:** `/worker-entrypoint.sh`
- **Build:** SUCCESS
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **Analysis:**
  - The custom entrypoint script `/worker-entrypoint.sh` did NOT appear to run (no debug logs appeared).
  - The error `/usr/bin/env: 'node': ...` persists, suggesting Render is either ignoring the `dockerCommand` override or the override mechanism is failing to execute the shell script directly.
  - It's possible Render is wrapping the command or failing to invoke it as a shell script.

### Deploy dep-d57csjadbo4c73b12rug - FAILED (Superseded)
- **Status:** Likely stuck or canceled by subsequent deploy.

### Deploy dep-d57cuh0gjchc739hf870 - FAILED
- **Commit:** f2f1704 - Set ENTRYPOINT in Dockerfile
- **Strategy:** `ENTRYPOINT ["/worker-entrypoint.sh"]` in Dockerfile, Render Command: (empty)
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **Analysis:**
  - Even with `ENTRYPOINT ["/worker-entrypoint.sh"]`, the container still fails immediately with the same error.
  - This strongly implies that **Render is still overriding the entrypoint** somehow, or the way the image is built/run by Render completely ignores the `ENTRYPOINT` instruction if it thinks it's a "Docker" runtime service.
  - However, the logs show the image built successfully.
  - The error `/usr/bin/env: 'node': No such file` comes from the `n8n` binary itself (it's a node script with that shebang).
  - This means *something* is trying to execute `n8n` (or a script calling it) *without* the PATH being set correctly.
  - Since my entrypoint script sets the PATH, it means **my entrypoint script is NOT running**.

### Deploy (Next Attempt)
- **Strategy:** Hardcode the absolute path to the node binary in a custom launcher script, bypassing `/usr/bin/env` entirely.
  - Instead of relying on `PATH` and `/usr/bin/env`, we will create a wrapper that invokes node directly on the n8n javascript file.
  - We will try setting the **Render Docker Command** to this explicit invocation: `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
  - Wait, we tried that in `dep-d57cgqpr0fns73a30gmg` and it failed.
  - **New Idea:** Use `sh` as the entrypoint.
  - Render Command: `/bin/sh -c "export PATH=$PATH:/usr/local/bin && /worker-entrypoint.sh"`
  - This forces a shell to start, set the path, and *then* run our script.

---

## Root Cause Analysis (2025-12-26 Research Session)

### Retired Runtime Hypothesis About Render `dockerCommand`

The following was a 2025-12-26 runtime hypothesis from failed custom-image experiments. It is not a general statement about current Render behavior and must not override the live service inspection or current Render documentation.

**Historical sources consulted at the time:**
- https://community.render.com/t/docker-entrypoint-executable-not-running/1425
- https://community.render.com/t/commands-in-docker-compose-yml/16442
- https://render.com/docs/docker

**Historical interpretation:**
1. When you set a `dockerCommand` in Render, it uses Docker's `--entrypoint` flag internally
2. This **completely replaces** BOTH the Dockerfile's `ENTRYPOINT` AND `CMD`
3. The container launches with **minimal environment** - no shell setup, no PATH from profile scripts
4. Our `ENTRYPOINT ["/worker-entrypoint.sh"]` is **never executed** because Render bypasses it

**Historical failure interpretation:**
1. The `dockerCommand` value `/usr/local/bin/node ...` tries to execute the n8n binary directly
2. But the n8n binary at `/usr/local/lib/node_modules/n8n/bin/n8n` has shebang `#!/usr/bin/env node`
3. When Render starts the container with `dockerCommand`, PATH is minimal (no `/usr/local/bin`)
4. `/usr/bin/env node` cannot find `node` because PATH doesn't include `/usr/local/bin`
5. **Our entrypoint script that sets PATH never runs** - it's completely bypassed

### Why The Web Service Works
The n8n web service has **NO dockerCommand set**. This means:
1. Render uses the image's default ENTRYPOINT (the n8n docker-entrypoint.sh)
2. The n8n entrypoint sets up the environment properly
3. PATH is correct, node is found

### Solution Options

**Option 1: Remove dockerCommand entirely**
- Set dockerCommand to empty/blank
- Let Dockerfile's ENTRYPOINT run
- ENTRYPOINT must then start the worker (not the web UI)
- Problem: Need different behavior from same image

**Option 2: Use shell wrapper in dockerCommand**
- Set dockerCommand to: `sh -c 'export PATH=/usr/local/bin:$PATH && exec /usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10'`
- Forces a shell to start first, sets PATH, then execs
- Problem: Already tried something similar, but may not have been exact

**Option 3: Create a self-contained launcher**  
- Create a shell script that uses absolute paths for EVERYTHING
- No reliance on PATH at all, no `/usr/bin/env`
- Set dockerCommand to: `sh /worker-entrypoint.sh`
- The script calls `/usr/local/bin/node` directly

**Option 4: Modify n8n binary shebang** (hacky)
- During build, replace `#!/usr/bin/env node` with `#!/usr/local/bin/node` in the n8n binary
- Eliminates the env lookup entirely

**Key insight from previous failure:**
The dockerCommand `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker` FAILED because:
- When you run `/usr/local/bin/node /path/to/script.js`, node reads the script
- The script `/usr/local/lib/node_modules/n8n/bin/n8n` may `require()` other modules
- Those modules may spawn subprocesses that rely on `#!/usr/bin/env node` or PATH
- Even though we called node directly, internal n8n processes still fail

---

## Tested Solutions After Research (2025-12-26)

### Deploy dep-d57d559r0fns73a36gq0 - FAILED
- **Commit:** bb53f7e - Rewrite shebangs to use absolute node path
- **Dockerfile changes:**
  - `find /usr/local/lib/node_modules -type f -name "*.js" -exec grep -l '#!/usr/bin/env node' {} \; | xargs -r sed -i 's|#!/usr/bin/env node|#!/usr/local/bin/node|g'`
  - `sed -i 's|#!/usr/bin/env node|#!/usr/local/bin/node|g' /usr/local/lib/node_modules/n8n/bin/n8n`
  - `ln -sf /usr/local/bin/node /usr/bin/node` (symlink)
- **dockerCommand:** `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
- **Build:** SUCCESS
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **Conclusion:** Shebang rewrite + symlink still fails. Symlinks don't persist at Render runtime.

### Deploy 230f8c4 - FAILED
- **Commit:** 230f8c4 - Copy node binary instead of symlink
- **Dockerfile change:** `cp /usr/local/bin/node /usr/bin/node` (actual copy, not symlink)
- **dockerCommand:** `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **Conclusion:** Even copying the binary to /usr/bin doesn't persist at runtime

### Deploy with sh wrapper - FAILED
- **dockerCommand:** `/bin/sh -c 'export PATH=/usr/local/bin:/usr/bin:/bin:$PATH && exec /usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10'`
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`

### Env Var Change (2025-12-26)
- **Change:** Added `EXECUTIONS_PROCESS=worker` environment variable via Render API
- **Reason:** Render's official n8n guide uses env vars (`EXECUTIONS_MODE=queue` + `EXECUTIONS_PROCESS=worker`) instead of dockerCommand arguments

### Deploy dep-d57df34hg0os73cq27o0 - FAILED
- **Commit:** c9a1ee8 - Revert to clean apk-tools workaround for n8n 2.1.4
- **Dockerfile:** Clean n8n:2.1.4 + apk-tools workaround
- **dockerCommand:** (empty)
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`

### Deploy dep-d57dhu63jp1c73atsfag - FAILED
- **Change:** Switched to official n8n image directly - NO custom Dockerfile
- **Image:** `docker.io/n8nio/n8n:latest`
- **Runtime:** `image` (not `docker`)
- **dockerCommand:** (empty)
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`

### Deploy dep-d57dj315pdvs739cm4dg - PARTIAL SUCCESS (NOT A WORKER)
- **Image:** `docker.io/n8nio/n8n:latest`
- **Runtime:** `image`
- **dockerCommand:** (empty)
- **Env vars:** `EXECUTIONS_MODE=queue`, `EXECUTIONS_PROCESS=worker`
- **Status:** LIVE but running as MAIN instance, NOT worker
- **Problem:** Logs showed "Editor is now accessible via: https://n8n-naps.onrender.com" - running web UI instead of worker
- **Root cause:** Env vars alone don't make it run as worker; the `n8n worker` command is required

### Deploy dep-d57dkcp5pdvs739cmnm0 - SUCCESS!!! WORKER RUNNING!!!
- **Image:** `docker.io/n8nio/n8n:latest`
- **Runtime:** `image`
- **dockerCommand:** `worker --concurrency=10`
- **Status:** LIVE and running as WORKER
- **Logs confirm:**
  - `worker.js` init logs (not `start.js`)
  - `n8n Task Broker ready on 127.0.0.1, port 5679`
  - `Registered runner "JS Task Runner"`
  - `n8nEventLog-worker.log` (worker-specific log file)
  - NO "Editor is now accessible" message
- **Why it works:** The `dockerCommand: worker --concurrency=10` is passed as ARGUMENTS to the existing ENTRYPOINT (`/docker-entrypoint.sh`), not as a replacement. The entrypoint properly sets up PATH/environment, then runs `n8n worker --concurrency=10`

---

## FAILED Dockerfile Approaches

### 1. n8n:2.1.4 Alpine + apk-tools workaround
**Result:** BUILD succeeds, RUNTIME fails

### 2. Debian multi-stage (copy /usr/local from n8n Alpine)
**Result:** BUILD fails - musl/glibc incompatibility

### 3. node:22-bookworm-slim + npm install n8n
**Result:** BUILD succeeds, RUNTIME fails

### 4. Shebang rewrites
**Result:** Failed

### 5. Symlinks at build time
**Result:** Symlink verified at build, fails at runtime

### 6. Custom wrapper script as ENTRYPOINT
**Result:** Failed

### 7. Override ENTRYPOINT to call node directly
**Result:** Failed

### 8. Explicit PATH in ENV
**Result:** FAILED - same runtime error

---

## dockerCommand Values Tested

### WITH CUSTOM DOCKERFILE (all FAILED)
1. `worker --concurrency=10` - FAILED
2. `n8n worker --concurrency=10` - FAILED  
3. `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10` - FAILED
4. `/docker-entrypoint.sh worker --concurrency=10` - FAILED
5. `tini -- /docker-entrypoint.sh worker --concurrency=10` - FAILED
6. `/bin/sh -c 'export PATH=/usr/local/bin:/usr/bin:$PATH && exec n8n worker --concurrency=10'` - FAILED
7. (empty - rely on Dockerfile CMD) - FAILED

### WITH OFFICIAL IMAGE (runtime: image) - SUCCESS!
8. `worker --concurrency=10` - **SUCCESS!**
   - This was the observed behavior for the official image-backed worker in this historical deploy.
   - Do not generalize this entrypoint behavior to every Render runtime. Check the current Render service and official Render documentation.

---

## Custom Packages - Not Yet Deployed (2025-12-26)

The worker is running with the official n8n image, which lacks custom packages:
- ffmpeg, imagemagick, poppler-utils, ghostscript, graphicsmagick, pandoc
- python3, yt-dlp, mobi

### Dockerfile Ready
A historical Dockerfile with these packages was prepared at the repository root as `Dockerfile`:
- Base: `n8nio/n8n:latest`
- Includes apk-tools workaround
- Has `CMD ["worker", "--concurrency=10"]` baked in
- Chromium excluded (too large - 1GB)

### Why Not Deployed Yet
1. **Cannot switch runtime via API** - Render won't let us change from `image` to `docker` runtime via API
2. **Docker Hub push timed out** - The ~480MB packages layer kept failing to upload
3. **ghcr.io token lacks scope** - Would need `write:packages` permission

### Historical Custom Image Procedure Retired

This section is archived and intentionally contains no executable deployment procedure. Do not push a custom image, delete the current worker, recreate the service, or re-add environment values based on this historical experiment. The live worker is the existing image-backed service documented in `docs/render_operations.md`.

---

## References
- GitHub Issue: https://github.com/n8n-io/n8n/issues/23246
- Community Thread: https://community.n8n.io/t/docker-image-is-distroless-cannot-install-git-gh-cli-need-extensible-variant/240490
- Render Support Message: render_support_message.md

## Documentation and Configuration Reconciliation 2026-08-22

- Updated `README.md` to describe the verified live Render architecture and the separate web-service and worker update paths.
- Aligned `.github/dependabot.yml` with the deployed monthly, major-version-only Docker update policy.
- Marked `render.yaml` and `render_queue_mode.yaml` as historical, non-authoritative files that must not be applied to the existing grandfathered Render project.
- No Render deployment, restart, plan change, resource recreation, or external update was performed.
- The live worker remains the existing image-backed service using `docker.io/n8nio/n8n:latest`; changing that service remains a separate deployment decision.

## Operations Documentation Refresh 2026-08-22

- Added `docs/render_operations.md` with a timestamped live Render snapshot, authority order, read-only inspection commands, update paths, deployment rules, and official references.
- Rewrote `AGENTS.md` to distinguish the monthly GitHub-to-Render web-service path from the separately deployed image-backed worker path.
- Added the operations document link and the web-versus-worker automation distinction to `README.md`.
- Verified the live snapshot at 2026-08-22 10:47:57 WITA. No Render deployment, restart, plan change, resource recreation, or external update was performed.

## Documentation Audit Corrections 2026-08-22

- Clarified that the web Dependabot path is configured for monthly checks and auto-merge, but the specific 2026-08-10 web deploy is not attributed to Dependabot by the available evidence.
- Added an explicit historical-only warning to this failure log and retired the old custom-image push and worker-recreation procedure.
- Reframed the old `dockerCommand` entrypoint conclusion as a runtime-specific historical hypothesis.
- Corrected the historical custom Dockerfile reference to the repository-relative `Dockerfile` path.
- Verified at 2026-08-22 11:01:13 WITA. No Render deployment, restart, plan change, resource recreation, or external update was performed.

## Automation Audit 2026-08-22

- Confirmed the GitHub configuration: Dependabot checks monthly, ignores minor and patch version updates, and the auto-merge workflow is present.
- The latest observed Dependabot pull request and auto-merge workflow run were on 2025-12-24 for n8n 2.1.4. No 2026 Dependabot pull request or auto-merge run was found.
- GitHub reported automated security fixes enabled and no open Dependabot alerts at 2026-08-22 11:10:36 WITA.
- The 2026-08-10 Render web deploy was triggered by a new commit containing the Dependabot-throttling configuration, not by an n8n version update.
- No repository automation or Render worker deploy was changed. No Render deployment, restart, plan change, resource recreation, or external update was performed.

## Coordinated n8n Update 2026-08-22

- Pinned the web-service Dockerfile and worker image to n8n `2.35.7`, the latest non-preview release verified during this update.
- Published repository commit `50ef3d7db69193bdeab5cfdefa6ee99ca2125243` to GitHub `main`.
- Web deploy `dep-da4h9t5ckfvc73ciu1e0` completed live at 2026-08-22 11:18:33 WITA. The image build resolved the n8n base image index `sha256:166d7e3ca384afdffe75394bf00046c299d84a4bf17b19b35d6cf7773af0a147`.
- Worker image reference changed from `docker.io/n8nio/n8n:latest` to `docker.io/n8nio/n8n:2.35.7`. Worker deploy `dep-da4hbl8n74is73dl14hg` completed live at 2026-08-22 11:21:59 WITA with image digest `sha256:f410270e715c795b4935eb16f94c099f7aee8da81c340c9842e76f0d5e716ff3`.
- Existing standard service plans, persistent disks, database, Redis, commands, and environment values were preserved.
- Public health returned `{"status":"ok"}` after the web deployment, and recent worker logs show successful workflow executions after the worker deployment.

## Blueprint Validation Repair 2026-08-22

- Render Blueprint `n8n-new` reported a sync failure because the historical `render.yaml` declared the legacy Postgres `starter` plan, which Render no longer permits for new Blueprint databases.
- Replaced the historical resource definitions with empty `services` and `databases` lists. This prevents stale Blueprint configuration from being applied and does not alter the live CYHQ n8n resources.
- Local Render CLI validation passed for the replacement placeholder. The repository must be published so the linked Blueprint can re-read the valid file.
- The duplicate zero-resource Blueprint `n8n-new` (`exs-cmr5n1n109ks73fg75k0`) was disconnected at 2026-08-22 11:26:58 WITA. Render returned HTTP 204, and no services or datastores were deleted.

## GitHub Actions Service Coordinator 2026-08-22

- Changed Dependabot from monthly to weekly Docker image checks while retaining minor and patch updates.
- Added `.github/workflows/deploy-worker-after-web.yml` for the temporary GitHub Actions deployment path requested for the grandfathered Render project.
- The coordinator reads the pinned n8n version from `Dockerfile`, waits for the matching Render web deployment to be live and healthy, then checks the worker’s configured and latest live image references.
- If the worker differs, the coordinator updates the worker image setting and triggers an explicit Render API deployment. If both services already match, it does not restart the worker.
- The coordinator runs after Dockerfile updates, weekly at 02:00 UTC / 10:00 WITA, and by manual dispatch. A failed run is retried by the next weekly run.
- The coordinator requires the encrypted GitHub repository secret `RENDER_API_KEY`; the credential is not stored in this repository or written to logs.
- No Render service plan, disk, database, Redis resource, command, or environment value was changed by this repository update.
