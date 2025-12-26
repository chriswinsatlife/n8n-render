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

# Now apk works normally - install additional packages (NOT nodejs - use existing node)
RUN apk add --no-cache pandoc ffmpeg imagemagick poppler-utils ghostscript graphicsmagick python3 py3-pip && \
        pip3 install --no-cache-dir --break-system-packages yt-dlp mobi || true

# Ensure node binary exists in both common locations (real binary at /usr/bin/node)
RUN apk add --no-cache --force-overwrite nodejs && \
        ln -sf /usr/bin/node /usr/local/bin/node

# Verify node is accessible
RUN ls -l /usr/bin/node /usr/local/bin/node && which node && node --version && /usr/bin/env node --version

EXPOSE 5678
USER node
