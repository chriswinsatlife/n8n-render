FROM n8nio/n8n:1.102.4

ENV N8N_COMMUNITY_PACKAGES_ENABLED=true \
    N8N_COMMUNITY_PACKAGES_ALLOW_TOOL_USAGE=true

USER root

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
        yt-dlp \
        py3-pip \
        git \
    && pip install --no-cache-dir yt-dlp mobi \
    && git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown /tmp/md \
    && mkdir -p /home/node/.n8n/nodes/node_modules/@bitovi \
    && cp -R /tmp/md /home/node/.n8n/nodes/node_modules/@bitovi/n8n-nodes-markitdown \
    && cd /home/node/.n8n/nodes/node_modules/@bitovi/n8n-nodes-markitdown/dist/nodes/Markitdown \
    && mv Markitdown.node.js MarkitdownNode.node.js \
    && printf '\nmodule.exports.MarkitdownNode = module.exports.Markitdown;\n' >> MarkitdownNode.node.js \
    && rm -rf /tmp/md

USER node
EXPOSE 5678
