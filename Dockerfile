# n8n on Debian (glibc) so onnxruntime wheel installs
FROM n8nio/n8n:latest          # this tag is Debian/bookworm-slim

USER root

# ---- system packages -------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip git curl \
        ffmpeg ghostscript poppler-utils imagemagick tesseract-ocr \
        chromium gnupg ca-certificates fonts-freefont pandoc && \
    rm -rf /var/lib/apt/lists/*

# ---- pip -------------------------------------------------------------
ENV PIP_NO_CACHE_DIR=1 \
    PIP_BREAK_SYSTEM_PACKAGES=1           # bypass PEP 668

RUN pip install \
        'markitdown[all]' \
        yt-dlp \
        mobi

# ---- custom n8n MarkItDown node --------------------------------------------
RUN git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown.git /tmp/mdnode && \
    cd /tmp/mdnode && \
    npm ci --omit=dev && \
    mkdir -p /home/node/.n8n/custom && \
    cp -R dist/nodes/* /home/node/.n8n/custom && \
    cd / && rm -rf /tmp/mdnode

# ---- Puppeteer (HTML→PDF inside the node) ----------------------------------
RUN npm install -g --omit=dev puppeteer && npm cache clean --force

USER node
EXPOSE 5678
CMD ["n8n"]
