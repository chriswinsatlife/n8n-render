FROM n8nio/n8n:1.118.2

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

EXPOSE 5678
# Switch back to the default user
USER node
