ARG NODE_VERSION=20

# 1. Use a builder step to download various dependencies
FROM node:${NODE_VERSION}-alpine as builder

# Install fonts
RUN apk --no-cache add msttcorefonts-installer fontconfig && \
    update-ms-fonts && \
    fc-cache -f && \
    apk del msttcorefonts-installer && \
    find /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \;

# Install git and other OS dependencies
RUN apk add --no-cache git openssh graphicsmagick tini tzdata ca-certificates libc6-compat jq

# Update npm and install full-uci
COPY .npmrc /usr/local/etc/npmrc  # Include .npmrc if needed
RUN npm install -g npm@9.9.2 full-icu@1.5.0

# Activate corepack, and install pnpm if needed
WORKDIR /tmp
COPY package.json ./  # Include package.json if needed
RUN corepack enable && corepack prepare --activate  # Skip if not using pnpm

# Cleanup unnecessary files
RUN rm -rf /lib/apk/db /var/cache/apk/ /tmp/* /root/.npm /root/.cache/node /opt/yarn*

# 2. Start with the n8n image and copy over the added files into a single layer
FROM n8nio/n8n:next  # You can use n8nio/n8n:latest or a stable tag instead

# Copy necessary directories from the builder stage
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/local/lib /usr/local/lib
COPY --from=builder /usr/share/fonts /usr/share/fonts

# Cleanup
RUN rm -rf /tmp/v8-compile-cache*

WORKDIR /home/node
ENV NODE_ICU_DATA /usr/local/lib/node_modules/full-icu

EXPOSE 5678/tcp
