FROM n8nio/n8n:latest-debian

USER root

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip git \
        ffmpeg ghostscript poppler-utils imagemagick tesseract-ocr \
        chromium ca-certificates fonts-freefont-ttf pandoc && \
    rm -rf /var/lib/apt/lists/*

ENV PIP_BREAK_SYSTEM_PACKAGES=1

# ---- Python libs --------------------------------------------------
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --no-cache-dir \
        markitdown \
        yt-dlp \
        mobi

# ---- custom n8n node ---------------------------------------------
RUN git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown.git /tmp/md && \
    cd /tmp/md && npm ci --omit=dev && \
    mkdir -p /home/node/.n8n/custom && \
    cp -R dist/nodes/* /home/node/.n8n/custom && \
    cd / && rm -rf /tmp/md

RUN npm install -g --omit=dev puppeteer && npm cache clean --force

USER node
EXPOSE 5678
CMD ["n8n"]
