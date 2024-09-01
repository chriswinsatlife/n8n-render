ARG NODE_VERSION=20

# 1. Use a builder step to download various dependencies
FROM node:${NODE_VERSION}-alpine as builder

# Install fonts
RUN	\
	apk --no-cache add --virtual fonts msttcorefonts-installer fontconfig && \
	update-ms-fonts && \
	fc-cache -f && \
	apk del fonts && \
	find  /usr/share/fonts/truetype/msttcorefonts/ -type l -exec unlink {} \;

# Install git and other OS dependencies
RUN apk add --update git openssh graphicsmagick tini tzdata ca-certificates libc6-compat jq

# Update npm and install full-uci
COPY .npmrc /usr/local/etc/npmrc
RUN npm install -g npm@9.9.2 full-icu@1.5.0

# Activate corepack, and install pnpm
WORKDIR /tmp
COPY package.json ./
RUN corepack enable && corepack prepare pnpm@latest --activate

# Cleanup
RUN	rm -rf /lib/apk/db /var/cache/apk/ /tmp/* /root/.npm /root/.cache/node /opt/yarn*

# 2. Start with the n8n base image and copy over the added files into a single layer
FROM n8nio/n8n:next

# Copy the built files from the builder stage
COPY --from=builder / /

# Delete this folder to make the base image backward compatible to be able to build older version images
RUN rm -rf /tmp/v8-compile-cache*

# Set working directory and environment variables
WORKDIR /home/node
ENV NODE_ICU_DATA /usr/local/lib/node_modules/full-icu

# Expose the necessary port
EXPOSE 5678/tcp

# Default command to run the n8n service
CMD ["n8n", "start"]
