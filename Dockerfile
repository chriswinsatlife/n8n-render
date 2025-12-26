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

# Rewrite shebang in n8n binary to avoid /usr/bin/env node lookup
RUN find /usr/local/lib/node_modules -type f -name "*.js" -exec grep -l '#!/usr/bin/env node' {} \; | xargs -r sed -i 's|#!/usr/bin/env node|#!/usr/local/bin/node|g'
RUN sed -i 's|#!/usr/bin/env node|#!/usr/local/bin/node|g' /usr/local/lib/node_modules/n8n/bin/n8n || true

# Symlink node to /usr/bin for any remaining /usr/bin/env node calls
RUN ln -sf /usr/local/bin/node /usr/bin/node

# Copy worker entrypoint
COPY worker-entrypoint.sh /worker-entrypoint.sh
RUN chmod +x /worker-entrypoint.sh && chown node:node /worker-entrypoint.sh

USER node
ENTRYPOINT ["/worker-entrypoint.sh"]

# Switch back to the default user
USER node
