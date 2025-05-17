FROM n8nio/n8n:next

USER root

# Installs your original dependencies, plus essential build tools for Python
# Adjusted the fallback for yt-dlp/mobi to include --break-system-packages for pip
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
    # Added git, python3, py3-pip, and build tools here
    git \
    python3 \
    py3-pip \
    python3-dev \
    build-base \
    libffi-dev \
    yt-dlp || \
    (echo "apk install for yt-dlp failed, attempting pip install..." && \
     python3 -m pip install --no-cache-dir --break-system-packages yt-dlp && \
     python3 -m pip install --no-cache-dir --break-system-packages mobi)

# Upgrade pip (with the fix)
RUN python3 -m pip install --no-cache-dir --break-system-packages --upgrade pip

# Install yt-dlp and mobi via pip if not handled reliably by the apk fallback,
# or if you prefer managing them with pip.
# If the apk line handles them, you might be able to comment this out.
# Ensure --break-system-packages is used.
RUN python3 -m pip install --no-cache-dir --break-system-packages yt-dlp mobi

# Install 'microsoft/markitdown' Python tool
WORKDIR /opt
RUN git clone --depth 1 https://github.com/microsoft/markitdown.git && \
    cd markitdown && \
    python3 -m pip install --no-cache-dir --use-pep517 --break-system-packages '/opt/markitdown/packages/markitdown[all]' && \
    cd / && \
    rm -rf /opt/markitdown

# Your original Puppeteer installation
RUN npm install -g puppeteer && \
  npm cache clean --force

# Install the '@bitovi/n8n-nodes-markitdown' custom n8n node
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
