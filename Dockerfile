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

RUN npm install -g puppeteer n8n && \
  npm cache clean --force

EXPOSE 5678

# Switch back to the default user
USER node
