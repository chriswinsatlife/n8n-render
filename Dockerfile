FROM n8nio/n8n:next
USER root

RUN apk add --no-cache \
    python3 py3-pip \
    pandoc \
    chromium nss freetype harfbuzz ttf-freefont ca-certificates \
    ffmpeg imagemagick poppler-utils ghostscript graphicsmagick \
    tesseract-ocr su-exec

# allow installs into the system interpreter
ENV PIP_BREAK_SYSTEM_PACKAGES=1

# base Python tooling
RUN pip install --no-cache-dir yt-dlp mobi 'magika<0.6'

# MarkItDown (local clone) — keep the magika pin
RUN git clone --depth 1 https://github.com/microsoft/markitdown.git /tmp/markitdown \
 && pip install --no-cache-dir --use-pep517 '/tmp/markitdown/packages/markitdown[all]' 'magika<0.6' \
 && rm -rf /tmp/markitdown

# custom n8n node
WORKDIR /tmp
RUN git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown.git \
 && cd n8n-nodes-markitdown \
 && npm ci --omit=dev \
 && mkdir -p /home/node/.n8n/custom \
 && cp -R dist/nodes/* /home/node/.n8n/custom \
 && cd / && rm -rf /tmp/n8n-nodes-markitdown

# puppeteer for HTML→PDF
RUN npm install -g --omit=dev puppeteer && npm cache clean --force

USER node
EXPOSE 5678
