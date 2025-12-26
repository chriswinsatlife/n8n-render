FROM n8nio/n8n:2.0.2

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

# Copy worker entrypoint
COPY worker-entrypoint.sh /worker-entrypoint.sh
RUN chmod +x /worker-entrypoint.sh
RUN ln -s /usr/local/bin/node /usr/bin/node

ENTRYPOINT ["/worker-entrypoint.sh"]

# Switch back to the default user
USER node
