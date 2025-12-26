FROM n8nio/n8n:2.1.4

USER root

RUN set -eux; \
    apk add --no-cache \
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
        python3 \
        py3-pip; \
    pip3 install --no-cache-dir --break-system-packages yt-dlp mobi || \
    pip3 install --no-cache-dir yt-dlp mobi || true

EXPOSE 5678
USER node
