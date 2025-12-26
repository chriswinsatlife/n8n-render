FROM n8nio/n8n:2.1.4

USER root

# Reinstall apk-tools since n8n 2.1.0+ removes it
# Source: https://community.n8n.io/t/docker-image-is-distroless-cannot-install-git-gh-cli-need-extensible-variant/240490
RUN ARCH=$(uname -m) && \
    wget -qO- "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/" | \
    grep -o 'href="apk-tools-static-[^"]*\.apk"' | head -1 | cut -d'"' -f2 | \
    xargs -I {} wget -q "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/{}" && \
    tar -xzf apk-tools-static-*.apk && \
    ./sbin/apk.static -X http://dl-cdn.alpinelinux.org/alpine/latest-stable/main \
        -U --allow-untrusted add apk-tools && \
    rm -rf sbin apk-tools-static-*.apk

# Now apk works - install our dependencies
RUN apk add --no-cache \
    chromium \
    ffmpeg \
    imagemagick \
    poppler-utils \
    ghostscript \
    graphicsmagick \
    pandoc \
    python3 \
    py3-pip

# Install Python packages
RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --no-cache-dir yt-dlp mobi

ENV PATH="/opt/venv/bin:$PATH"

# Create symlink to make /usr/bin/env node work
RUN ln -sf /usr/local/bin/node /usr/bin/node

# Debug: verify node setup at build time
RUN echo "=== DEBUG: Build-time node verification ===" && \
    echo "1. which node:" && which node && \
    echo "2. /usr/bin/node:" && ls -la /usr/bin/node && \
    echo "3. /usr/local/bin/node:" && ls -la /usr/local/bin/node && \
    echo "4. readlink /usr/bin/node:" && readlink -f /usr/bin/node && \
    echo "5. /usr/bin/env node -v:" && /usr/bin/env node -v && \
    echo "6. PATH:" && echo $PATH && \
    echo "7. /usr/bin contents (node related):" && ls -la /usr/bin/ | grep node && \
    echo "8. /usr/local/bin contents (node related):" && ls -la /usr/local/bin/ | grep node && \
    echo "=== END DEBUG ==="

USER node
