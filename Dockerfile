FROM n8nio/n8n:next

USER root

# Installs your original dependencies
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
    # Add git, python3, py3-pip, and build tools here directly
    git \
    python3 \
    py3-pip \
    python3-dev \
    build-base \
    libffi-dev \
    yt-dlp || \
    (python3 -m pip install --no-cache-dir --break-system-packages yt-dlp && \
     python3 -m pip install --no-cache-dir --break-system-packages mobi)
    # Note: The original fallback logic for yt-dlp/mobi with pip has been adjusted 
    # to include --break-system-packages and to ensure mobi also installs in the fallback.
    # A simpler approach if yt-dlp from apk is reliable:
    # apk add ... yt-dlp
    # Then a separate RUN for pip install mobi

# If you prefer to ensure pip is upgraded and handle mobi/yt-dlp separately:
RUN python3 -m pip install --no-cache-dir --upgrade pip

# This is where your failing command was, now corrected:
# Installs yt-dlp, mobi (if not handled above or as a primary method), and markitdown
RUN python3 -m pip install --no-cache-dir --break-system-packages yt-dlp mobi \
 && git clone --depth 1 https://github.com/microsoft/markitdown.git /tmp/markitdown \
 && python3 -m pip install --no-cache-dir --use-pep517 --break-system-packages '/tmp/markitdown/packages/markitdown[all]' \
 && rm -rf /tmp/markitdown

# Your original Puppeteer installation
RUN npm install -g puppeteer && \
  npm cache clean --force

# Install the @bitovi/n8n-nodes-markitdown custom n8n node
WORKDIR /tmp/custom-node-build
RUN git clone https://github.com/bitovi/n8n-nodes-markitdown.git . && \
    npm ci && \
    npm run build && \
    mkdir -p /home/node/.n8n/custom && \
    cp -R dist/nodes/* /home/node/.n8n/custom/ && \
    rm -rf /tmp/custom-node-build

WORKDIR /

EXPOSE 5678
USER node
