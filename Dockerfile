FROM n8nio/n8n:next

USER root

RUN apk add --no-cache pandoc chromium nss freetype harfbuzz ca-certificates ttf-freefont su-exec ffmpeg imagemagick poppler-utils ghostscript graphicsmagick python3 py3-pip

RUN pip install --no-cache-dir yt-dlp mobi

RUN npm install -g puppeteer && npm cache clean --force

EXPOSE 5678

USER node
