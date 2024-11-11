FROM n8nio/n8n:next

# Switch to root to install packages
USER root

# Install ffmpeg using apt-get since we're on Ubuntu base image
RUN apt-get update && \
    apt-get install -y ffmpeg && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Switch back to the default user 'node'
USER node
