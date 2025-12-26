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

### Deploy PENDING - e66256c
- **Commit:** e66256c - Explicitly set PATH in ENV to persist at runtime
- **Change:** `ENV PATH="/usr/local/bin:/usr/bin:/bin:/opt/venv/bin:$PATH"`
- **dockerCommand:** `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10`
- **Status:** Waiting for deploy

---

## Root Cause Analysis

Research (Exa) found that Render's `dockerCommand` bypasses the image ENTRYPOINT, which means:
1. The entrypoint script that sets up PATH never runs
2. Container starts with minimal environment
3. Even though symlinks exist in the image, PATH may not include the directories

**Key finding:** The symlink DOES persist in the image. The issue is PATH not being set at runtime when using dockerCommand.

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

### 8. Explicit PATH in ENV (CURRENT ATTEMPT)
**Result:** PENDING

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
