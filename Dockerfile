FROM n8nio/n8n:2.1.4

USER root

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        pandoc \
        chromium \
        libnss3 \
        libfreetype6 \
        libharfbuzz0b \
        fonts-freefont-ttf \
        ca-certificates \
        ffmpeg \
        imagemagick \
        poppler-utils \
        ghostscript \
        graphicsmagick \
        python3 \
        python3-pip; \
    rm -rf /var/lib/apt/lists/*; \
    pip3 install --no-cache-dir --break-system-packages yt-dlp mobi || \
    pip3 install --no-cache-dir yt-dlp mobi || true; \
    npm install -g puppeteer && npm cache clean --force

EXPOSE 5678
USER node
