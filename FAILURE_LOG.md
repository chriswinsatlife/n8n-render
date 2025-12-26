# n8n Background Worker on Render - Failure Log

## Service
- **Worker Service ID:** srv-d117ruqdbo4c739o7bhg
- **Dashboard:** https://dashboard.render.com/worker/srv-d117ruqdbo4c739o7bhg/settings
- **Repo:** chriswinsatlife/n8n-render (Dockerfile lives here)

## Current Status
**DOWN** - All attempts fail at runtime with `/usr/bin/env: 'node': No such file or directory`

---

## FAILED Dockerfile Approaches

### 1. n8n:2.1.4 Alpine + apk-tools workaround (community solution)
```dockerfile
FROM n8nio/n8n:2.1.4
USER root
RUN ARCH=$(uname -m) && \
    wget -qO- "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/" | \
    grep -o 'href="apk-tools-static-[^"]*\.apk"' | head -1 | cut -d'"' -f2 | \
    xargs -I {} wget -q "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/{}" && \
    tar -xzf apk-tools-static-*.apk && \
    ./sbin/apk.static -X http://dl-cdn.alpinelinux.org/alpine/latest-stable/main \
        -U --allow-untrusted add apk-tools && \
    rm -rf sbin apk-tools-static-*.apk
RUN apk add --no-cache chromium ffmpeg ...
USER node
```
**Result:** BUILD succeeds, RUNTIME fails with `/usr/bin/env: 'node': No such file or directory`

### 2. Debian multi-stage (copy /usr/local from n8n Alpine)
```dockerfile
FROM n8nio/n8n:2.1.4 AS n8n
FROM debian:bookworm-slim
COPY --from=n8n /usr/local/ /usr/local/
```
**Result:** BUILD fails - musl/glibc binary incompatibility. Node binary from Alpine won't execute on Debian.

### 3. node:22-bookworm-slim + npm install n8n
```dockerfile
FROM node:22-bookworm-slim
RUN npm install -g n8n@2.1.4
```
**Result:** BUILD succeeds, RUNTIME fails with `/usr/bin/env: 'node': No such file or directory`

### 4. Shebang rewrites (#!/usr/bin/env node -> #!/usr/bin/node)
Attempted to rewrite all shebangs in n8n to use absolute path.
**Result:** Still fails

### 5. Symlinks at build time
```dockerfile
RUN ln -sf /usr/local/bin/node /usr/bin/node
```
**Result:** Symlink exists and verifies during build, fails at runtime on Render

### 6. Custom wrapper script as ENTRYPOINT
Created shell script that sets PATH and calls n8n.
**Result:** Failed

### 7. Override ENTRYPOINT to call node directly
```dockerfile
ENTRYPOINT ["tini", "--", "/usr/local/bin/node", "/usr/local/lib/node_modules/n8n/bin/n8n"]
CMD ["worker", "--concurrency=10"]
```
**Result:** PENDING - commit 7a2fa98 (Dec 26 2025)

---

## FAILED dockerCommand Values (in Render dashboard)

All tested with various Dockerfile approaches above:

1. `worker --concurrency=10` - FAILED
2. `n8n worker --concurrency=10` - FAILED  
3. `/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10` - FAILED
4. `/usr/local/bin/node /usr/local/lib/node_modules/n8n/packages/cli/bin/n8n.js worker --concurrency=10` - FAILED
5. `tini -- /docker-entrypoint.sh worker --concurrency=10` - FAILED
6. `tini -- /docker-entrypoint.sh n8n worker --concurrency=10` - FAILED
7. `/docker-entrypoint.sh worker --concurrency=10` - FAILED
8. `/bin/sh -c 'export PATH=/usr/local/bin:/usr/bin:$PATH && exec n8n worker --concurrency=10'` - FAILED
9. `` (empty - rely on Dockerfile CMD) - FAILED

---

## Key Observations

1. **Web service works** with same Dockerfile and NO dockerCommand - uses default ENTRYPOINT
2. **Worker needs** dockerCommand or CMD to pass `worker --concurrency=10` args
3. **Render's runtime** doesn't have `/usr/local/bin` in PATH when using dockerCommand
4. **dockerCommand overrides** both ENTRYPOINT and CMD entirely
5. **Symlinks/PATH changes** made at build time don't persist or apply at Render runtime
6. **The n8n binary** at `/usr/local/lib/node_modules/n8n/bin/n8n` has shebang `#!/usr/bin/env node`

---

## UNTESTED Options

1. **Pin to n8n:2.0.2** - last version before apk-tools removal
2. **Contact Render support** - ask why runtime environment differs from build

---

## References
- GitHub Issue: https://github.com/n8n-io/n8n/issues/23246
- Community Thread: https://community.n8n.io/t/docker-image-is-distroless-cannot-install-git-gh-cli-need-extensible-variant/240490
- n8n Queue Mode Docs: https://docs.n8n.io/hosting/scaling/queue-mode/
