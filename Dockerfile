FROM n8nio/n8n:2.1.4 AS n8n

FROM debian:bookworm-slim

USER root

ENV NODE_ENV=production
ENV NODE_ICU_DATA=/usr/local/lib/node_modules/full-icu

# Install OS-level dependencies. We can't use apk/apt inside the upstream n8n
# image because it does not include a package manager.
RUN set -eux; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
        ca-certificates \
        pandoc \
        chromium \
        ffmpeg \
        imagemagick \
        poppler-utils \
        ghostscript \
        graphicsmagick \
        python3 \
        python3-venv \
        python3-pip \
        tini; \
        rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/venv
RUN set -eux; \
        python3 -m venv "$VIRTUAL_ENV"; \
        "$VIRTUAL_ENV/bin/pip" install --no-cache-dir yt-dlp mobi
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# Bring in the exact n8n + Node.js runtime from the official image.
COPY --from=n8n /usr/local/ /usr/local/

# Ensure node is discoverable for /usr/bin/env node and absolute lookups.
RUN set -eux; \
        ln -sf /usr/local/bin/node /usr/bin/node; \
        ENV_PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"; \
        PATH="$ENV_PATH:$PATH" which node; \
        PATH="$ENV_PATH:$PATH" node -v; \
        PATH="$ENV_PATH:$PATH" /usr/bin/env node -v; \
        if ! id node >/dev/null 2>&1; then \
        useradd -m -u 1000 -s /bin/sh node; \
        fi; \
        mkdir -p /home/node/.n8n; \
        chown -R node:node /home/node

ENV PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

WORKDIR /home/node
EXPOSE 5678

USER node
ENTRYPOINT ["tini", "--", "/usr/local/bin/node", "/usr/local/lib/node_modules/n8n/bin/n8n"]
