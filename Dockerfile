FROM n8nio/n8n:next

USER root

# Runtime deps + Python
RUN apk add --no-cache \
    python3 py3-pip \
    pandoc \
    chromium nss freetype harfbuzz ttf-freefont ca-certificates \
    ffmpeg imagemagick poppler-utils ghostscript graphicsmagick \
    tesseract-ocr \
    su-exec

# Python libraries (MarkItDown + tools)
RUN pip install --no-cache-dir \
    'markitdown[all]' \
    yt-dlp \
    mobi

# Custom n8n MarkItDown node
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown.git \
 && cd n8n-nodes-markitdown \
 && npm ci --omit=dev \
 && mkdir -p /home/node/.n8n/custom \
 && cp -R dist/nodes/* /home/node/.n8n/custom \
 && cd / && rm -rf /tmp/n8n-nodes-markitdown

# Puppeteer for HTML → PDF
RUN npm install -g --omit=dev puppeteer \
 && npm cache clean --force

USER node
EXPOSE 5678
