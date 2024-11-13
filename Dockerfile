FROM n8nio/n8n:next

# Switch to root to install packages
USER root

# Install ffmpeg using apk (Alpine package manager)
RUN apk add --no-cache ffmpeg

# Install imagemagick using apk (Alpine package manager)
RUN apk add --no-cache imagemagick

# Install pdftoppm etc using apk (Alpine package manager)
RUN apk add --no-cache poppler-utils

# Switch back to the default user 'node'
USER node
