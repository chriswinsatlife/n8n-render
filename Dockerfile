FROM n8nio/n8n:1.102.4

# Switch to root to install packages
USER root

# Install necessary packages using apk (Alpine package manager)
RUN apk add --no-cache \
    pandoc \
    chromium \
    nss \
    freetype \
    harfbuzz \
    ca-certificates \
    ttf-freefont \
    su-exec \
    ffmpeg \
    imagemagick \
    poppler-utils \
    ghostscript \
    graphicsmagick \
    yt-dlp || \
    pip install --no-cache-dir yt-dlp \
    pip install --no-cache-dir mobi \
    && npm install --omit=dev --prefix /home/node/.n8n/nodes @bitovi/n8n-nodes-markitdown \
    && mv /home/node/.n8n/nodes/node_modules/@bitovi/n8n-nodes-markitdown/dist/nodes/Markitdown/Markitdown.node.js \
          /home/node/.n8n/nodes/node_modules/@bitovi/n8n-nodes-markitdown/dist/nodes/Markitdown/MarkitdownNode.node.js

EXPOSE 5678
# Switch back to the default user
USER node
