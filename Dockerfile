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

# Now apk works normally - also add nodejs to ensure node binary is available
RUN apk add --no-cache pandoc ffmpeg imagemagick poppler-utils ghostscript graphicsmagick python3 py3-pip nodejs && \
    pip3 install --no-cache-dir --break-system-packages yt-dlp mobi || true

# Ensure node binary is available (installed via apk at /usr/bin/node)
# Do not override the binary location; keep default paths intact
ENV PATH="/usr/bin:/usr/local/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"

EXPOSE 5678
USER node
