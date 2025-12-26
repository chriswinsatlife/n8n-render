FROM n8nio/n8n:latest

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

# Now apk works - install our dependencies (no chromium - too big)
RUN apk add --no-cache \
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

USER node

# Keep the original ENTRYPOINT from n8n image: ["tini", "--", "/docker-entrypoint.sh"]
# Set CMD to run as worker - ENTRYPOINT will prepend "n8n" to this
CMD ["worker", "--concurrency=10"]
