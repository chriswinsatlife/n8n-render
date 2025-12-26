FROM n8nio/n8n:2.1.4

USER root

# Reinstall apk-tools since n8n removes it in v2.1.0+
RUN ARCH=$(uname -m) && \
    wget -qO- "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/" | \
    grep -o 'href="apk-tools-static-[^"]*\.apk"' | head -1 | cut -d'"' -f2 | \
    xargs -I {} wget -q "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/{}" && \
    tar -xzf apk-tools-static-*.apk && \
    ./sbin/apk.static -X http://dl-cdn.alpinelinux.org/alpine/latest-stable/main \
        -U --allow-untrusted add apk-tools && \
    rm -rf sbin apk-tools-static-*.apk

# Now apk works normally
RUN apk add --no-cache pandoc ffmpeg imagemagick poppler-utils ghostscript graphicsmagick python3 py3-pip && \
    pip3 install --no-cache-dir --break-system-packages yt-dlp mobi || true

# Debug: find where node is and create symlink
RUN echo "=== Finding node ===" && \
    which node || echo "which node failed" && \
    ls -la /usr/local/bin/node 2>/dev/null || echo "not at /usr/local/bin/node" && \
    ls -la /usr/bin/node 2>/dev/null || echo "not at /usr/bin/node" && \
    find / -name "node" -type f 2>/dev/null || echo "find failed" && \
    echo "=== Creating symlink ===" && \
    ln -sf /usr/local/bin/node /usr/bin/node && \
    ls -la /usr/bin/node

EXPOSE 5678
USER node
