# n8n Background Worker on Render - Failure Log

## Service
- **Worker Service ID:** srv-d117ruqdbo4c739o7bhg
- **Dashboard:** https://dashboard.render.com/worker/srv-d117ruqdbo4c739o7bhg/settings
- **Repo:** chriswinsatlife/n8n-render (Dockerfile lives here)

## Current Status
**DOWN** - All attempts fail at runtime with `/usr/bin/env: 'node': No such file or directory`

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

### CRITICAL DISCOVERY: Render's `dockerCommand` Completely Overrides BOTH ENTRYPOINT and CMD

**Source:** Render community posts and official documentation confirm:
- https://community.render.com/t/docker-entrypoint-executable-not-running/1425
- https://community.render.com/t/commands-in-docker-compose-yml/16442
- https://render.com/docs/docker

**The Problem:**
1. When you set a `dockerCommand` in Render, it uses Docker's `--entrypoint` flag internally
2. This **completely replaces** BOTH the Dockerfile's `ENTRYPOINT` AND `CMD`
3. The container launches with **minimal environment** - no shell setup, no PATH from profile scripts
4. Our `ENTRYPOINT ["/worker-entrypoint.sh"]` is **never executed** because Render bypasses it

**Why We See `/usr/bin/env: 'node': No such file or directory`:**
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

### Deploy dep-d57dhu63jp1c73atsfag - FAILED (CRITICAL TEST)
- **Change:** Switched to official n8n image directly - NO custom Dockerfile
- **Image:** `docker.io/n8nio/n8n:latest`
- **Runtime:** `image` (not `docker`)
- **dockerCommand:** (empty)
- **Env vars:** `EXECUTIONS_MODE=queue`, `EXECUTIONS_PROCESS=worker`
- **Runtime:** FAILED - `/usr/bin/env: 'node': No such file or directory`
- **CONCLUSION:** Even the official n8n image fails on Render background worker. This proves it's NOT the Dockerfile - it's a Render platform issue.

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

## FAILED dockerCommand Values

1. `worker --concurrency=10` - FAILED
2. `n8n worker --concurrency=10` - FAILED  
3. `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10` - FAILED
4. `/docker-entrypoint.sh worker --concurrency=10` - FAILED
5. `tini -- /docker-entrypoint.sh worker --concurrency=10` - FAILED
6. `/bin/sh -c 'export PATH=/usr/local/bin:/usr/bin:$PATH && exec n8n worker --concurrency=10'` - FAILED
7. (empty - rely on Dockerfile CMD) - FAILED

---

## References
- GitHub Issue: https://github.com/n8n-io/n8n/issues/23246
- Community Thread: https://community.n8n.io/t/docker-image-is-distroless-cannot-install-git-gh-cli-need-extensible-variant/240490
- Render Support Message: render_support_message.md
