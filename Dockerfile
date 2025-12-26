FROM n8nio/n8n:2.1.4

# Switch to root to install packages
USER root

# Install necessary packages (Alpine: apk, Debian/Ubuntu: apt-get)
RUN set -eux; \
    if command -v apk >/dev/null 2>&1; then \
        apk add --no-cache \
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
            python3 \
            py3-pip; \
    elif command -v apt-get >/dev/null 2>&1; then \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            pandoc \
            chromium \
            libnss3 \
            libfreetype6 \
            libharfbuzz0b \
            ca-certificates \
            fonts-freefont-ttf \
            gosu \
            ffmpeg \
            imagemagick \
            poppler-utils \
            ghostscript \
            graphicsmagick \
            python3 \
            python3-pip; \
        rm -rf /var/lib/apt/lists/*; \
    else \
        echo "No supported package manager found"; \
        exit 1; \
    fi; \
    python3 -m pip install --no-cache-dir yt-dlp mobi || \
    python3 -m pip install --no-cache-dir --break-system-packages yt-dlp mobi

EXPOSE 5678
# Switch back to the default user
USER node
