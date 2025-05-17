FROM n8nio/n8n:next

USER root

# 1. Your original system dependencies + additions for Markitdown's Python dependencies
#    - Added: git, python3, py3-pip, python3-dev, build-base, libffi-dev
#    - pandoc and poppler-utils (needed by markitdown) are already in your list.
#    - The complex fallback for yt-dlp/mobi is kept but adjusted for PEP 668.
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
    # --- Additions for Python and Markitdown ---
    git \
    python3 \
    py3-pip \
    python3-dev \
    build-base \
    libffi-dev \
    # --- End Additions ---
    yt-dlp || \
    (echo "apk install for yt-dlp failed, attempting pip install..." && \
     python3 -m pip install --no-cache-dir --break-system-packages yt-dlp && \
     python3 -m pip install --no-cache-dir --break-system-packages mobi)

# 2. Upgrade pip (using the system Python installed via apk)
RUN python3 -m pip install --no-cache-dir --break-system-packages --upgrade pip

# 3. Install additional Python packages if 'mobi' or 'yt-dlp' weren't fully handled by the fallback
#    or if you prefer pip for them. Comment out if the above apk/fallback is sufficient.
# RUN python3 -m pip install --no-cache-dir --break-system-packages yt-dlp mobi

# 4. Install 'microsoft/markitdown' Python tool
#    Using /opt for third-party software is a common practice.
WORKDIR /opt
RUN git clone --depth 1 https://github.com/microsoft/markitdown.git && \
    cd markitdown && \
    # Install markitdown and its Python dependencies.
    # TRYING WITHOUT '[all]' to diagnose dependency conflict.
    # --break-system-packages is used to handle PEP 668.
    python3 -m pip install --no-cache-dir --use-pep517 --break-system-packages './packages/markitdown' && \
    cd / && \
    rm -rf /opt/markitdown # Clean up cloned source

# 5. Your original Puppeteer installation
RUN npm install -g puppeteer && \
  npm cache clean --force

# 6. Install the '@bitovi/n8n-nodes-markitdown' custom n8n node
WORKDIR /tmp/custom-node-build # Temporary directory for building the node
RUN git clone --depth 1 https://github.com/bitovi/n8n-nodes-markitdown.git . && \
    # Install node dependencies (e.g., fs-extra) LOCALLY from package.json
    # 'npm ci' is robust for CI/Docker as it uses package-lock.json
    npm ci && \
    # Run the build script (check package.json for the correct script, usually 'build')
    npm run build && \
    # Create the target directory for custom n8n nodes if it doesn't exist
    mkdir -p /home/node/.n8n/custom && \
    # Copy the built node(s) from the 'dist/nodes' directory
    # (Verify this path from the node's package structure/build output)
    cp -R dist/nodes/* /home/node/.n8n/custom/ && \
    # Clean up the temporary build directory
    rm -rf /tmp/custom-node-build

# Ensure n8n user owns its home directory contents if necessary.
# The base image should handle this, but this is a safeguard.
RUN chown -R node:node /home/node/.n8n

WORKDIR / # Reset to default n8n working directory

EXPOSE 5678
USER node
