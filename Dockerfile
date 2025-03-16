FROM n8nio/n8n:next

# Switch to root to install packages
USER root

# Install necessary packages using apk (Alpine package manager)
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
    yt-dlp || \
    pip install --no-cache-dir yt-dlp \
    pip install --no-cache-dir mobi

RUN npm install -g puppeteer && \
  npm cache clean --force

# Change ownership of npm directories
RUN mkdir -p /home/node/.npm-global && \
    chown -R node:node /home/node/.npm-global && \
    chown -R node:node /usr/local/lib/node_modules || true

# Configure npm to use this directory
ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin

EXPOSE 5678
# Switch back to the default user
USER node
