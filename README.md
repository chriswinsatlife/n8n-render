# n8n-render

Successfull installation of n8n on Render using Docker.

To make it run just open Render Dashboard and use this git as Blueprint.

Important note if using disk on Render: Keep the mountPath as is, otherwise n8n won't change the data.

The .env file contain examples of lines that can be added manually on Environment Variables on Render after install.

To change the webhook URL from localhost to your domain, for example, just add the var WEBHOOK_URL followed by the full URL.

Version 0.224.1

## Render worker command
- Use the image entrypoint. Set Docker Command to `tini -- /docker-entrypoint.sh n8n worker --concurrency=10`.

## Changes to Dockerfile from original repo (`eborges-git/n8n-render`):
- Uses `FROM n8nio/n8n:2.1.4` - Dependabot can update this tag and automatically merge updates
- Reinstalls `apk-tools` using the workaround from GitHub issue #23246 in `n8n-io/n8n`
- Installs additional packages: `pandoc ffmpeg imagemagick poppler-utils ghostscript graphicsmagick python3 py3-pip`
- Installs Python packages: `yt-dlp mobi`
- Doesn't override `ENTRYPOINT` - uses the official n8n entrypoint
- Leaves the bundled `node` binary untouched (no custom symlink)
