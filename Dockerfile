FROM n8nio/n8n:next

# Switch to root to install packages
USER root

# Install necessary packages using apk (Alpine package manager)
RUN apk add --no-cache \
    ffmpeg \
    imagemagick \
    poppler-utils \
    ghostscript \
    graphicsmagick \
    python3 \
    py3-pip && \
    pip install --no-cache-dir yt-dlp

# Switch back to the default user 'node'
USER node
