# n8n on Debian – works with MarkItDown
FROM n8nio/n8n:latest-debian   # ← no trailing comments here

USER root

# minimal runtime deps
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 python3-pip git \
        ffmpeg ghostscript poppler-utils imagemagick tesseract-ocr \
        chromium ca-certificates fonts-freefont pandoc && \
    rm -rf /var/lib/apt/lists/*

ENV PIP_BREAK_SYSTEM_PACKAGES=1  \
    PIP_NO_CACHE_DIR=1

# Python libs (onnxruntime wheel now resolves)
RUN pip install \
      'markitdown[all]' \
      yt-dlp \
      mobi

# custom n8n node
RUN git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown.git /tmp/mdnode && \
    cd /tmp/mdnode && \
    npm ci --omit=dev && \
    mkdir -p /home/node/.n8n/custom && \
    cp -R dist/nodes/* /home/node/.n8n/custom && \
    cd / && rm -rf /tmp/mdnode

# puppeteer for HTML→PDF
RUN npm install -g --omit=dev puppeteer && npm cache clean --force

USER node
EXPOSE 5678
CMD ["n8n"]
