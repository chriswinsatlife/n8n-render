FROM n8nio/n8n:next

# Switch to root to install packages
USER root

# System dependencies
# Start with a minimal set and add if pip or npm install fails
RUN apk add --no-cache \
    git \
    bash \
    curl \
    wget \
    python3 \
    py3-pip \
    python3-dev \
    build-base \
    libffi-dev \
    # Essential for microsoft/markitdown
    pandoc \
    poppler-utils \
    # Potentially needed by markitdown for full functionality with images/media
    # Add these if you know you need these specific conversions by markitdown
    # They add significant size to the image.
    ffmpeg \
    imagemagick \
    ghostscript \
    graphicsmagick \
    # For yt-dlp and mobi if they are separate tools you need
    yt-dlp \
    \ su-exec # If you have entrypoint scripts that need it, n8n base might have it
    # If any n8n node (or this custom one) explicitly needs puppeteer & base doesn't provide chromium:
    chromium nss freetype harfbuzz ca-certificates ttf-freefont \
    && python3 -m pip install --no-cache-dir --upgrade pip

# Install additional pip packages if needed (e.g., mobi, yt-dlp if not via apk)
RUN python3 -m pip install --no-cache-dir \
    mobi \
    yt-dlp # Or use apk add yt-dlp if version is suitable

# Install microsoft/markitdown Python tool
WORKDIR /opt
RUN git clone https://github.com/microsoft/markitdown.git && \
    cd markitdown && \
    # Assuming markitdown's setup.py and requirements.txt handle all its Python deps
    # This will install markitdown and its dependencies (like opencv, pillow, etc.)
    python3 -m pip install --no-cache-dir . && \
    cd / && \
    rm -rf /opt/markitdown # Remove source if only installed CLI is needed, or keep if node needs to access its files

# Install @bitovi/n8n-nodes-markitdown
# Ensure this path is writable by the current user (root)
WORKDIR /opt/custom-nodes
RUN git clone https://github.com/bitovi/n8n-nodes-markitdown.git .
RUN npm ci && npm run build # 'npm ci' is often preferred in CI/Docker for cleaner installs from package-lock.json
                          # 'npm install' is also fine.
                          # Ensure 'npm run build' is the correct script from its package.json

# Copy the built node to n8n's custom nodes directory
# This directory needs to be created and have correct permissions for the 'node' user later
RUN mkdir -p /home/node/.n8n/custom && \
    cp -R /opt/custom-nodes/dist/nodes/* /home/node/.n8n/custom/ && \
    # Optional: Set ownership now if needed, though n8n entrypoint might handle it
    # chown -R node:node /home/node/.n8n
    rm -rf /opt/custom-nodes # Clean up build source

# Puppeteer
RUN npm install -g puppeteer && npm cache clean --force

# Clean up apk cache
RUN rm -rf /var/cache/apk/*

WORKDIR / # Reset WORKDIR to default or n8n's expected dir

EXPOSE 5678
# Switch back to the default n8n user
USER node
