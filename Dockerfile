FROM node:22-bookworm-slim

USER root

ENV NODE_ENV=production

# Ensure `node` is discoverable even if the runtime PATH is restricted.
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Install OS-level dependencies for rendering/conversion tasks.
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
        tini \
        build-essential; \
    rm -rf /var/lib/apt/lists/*; \
    ln -sf /usr/local/bin/node /usr/bin/node

# Install Python tooling into an isolated venv.
ENV VIRTUAL_ENV=/opt/venv
RUN set -eux; \
    python3 -m venv "$VIRTUAL_ENV"; \
    "$VIRTUAL_ENV/bin/pip" install --no-cache-dir yt-dlp mobi
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ARG N8N_VERSION=2.1.4

# Install n8n itself.
RUN set -eux; \
    npm install -g "n8n@${N8N_VERSION}"

# Persist data to Render disk at /home/node/.n8n
RUN set -eux; \
    mkdir -p /home/node/.n8n; \
    chown -R node:node /home/node

WORKDIR /home/node
EXPOSE 5678

USER node
# Call the JS entrypoint with an absolute Node path so we don't depend on
# `/usr/bin/env node` resolution at runtime.
ENTRYPOINT ["tini", "--", "/usr/local/bin/node", "/usr/local/lib/node_modules/n8n/bin/n8n"]
