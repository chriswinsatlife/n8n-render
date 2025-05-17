# ---------- base ------------------------------------------------------------
FROM n8nio/n8n:latest-ubi   # glibc-based, not Alpine

USER root

# ---------- system tools ----------------------------------------------------
RUN microdnf install -y \
        python3 python3-pip \
        ffmpeg ghostscript poppler-utils imagemagick tesseract \
        chromium nss freetype harfbuzz fontconfig \
    && microdnf clean all

# ---------- Python libs ------------------------------------------------------
ENV PIP_NO_CACHE_DIR=1
RUN pip install \
        yt-dlp \
        mobi \
        'markitdown[all]'

# ---------- custom n8n node --------------------------------------------------
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown.git \
 && cd n8n-nodes-markitdown \
 && npm ci --omit=dev \
 && mkdir -p /home/node/.n8n/custom \
 && cp -R dist/nodes/* /home/node/.n8n/custom \
 && cd / && rm -rf /tmp/n8n-nodes-markitdown

# ---------- puppeteer --------------------------------------------------------
RUN npm install -g --omit=dev puppeteer \
 && npm cache clean --force

USER node
EXPOSE 5678
