```bash
curl -s "https://api.github.com/repos/n8n-io/n8n/issues/23246/comments" | jq -r '.[] | "---\n\(.user.login) (\(.created_at)):\n\(.body)\n"'
```
---
n8n-assistant[bot] (2025-12-15T16:40:48Z):
Hey @signo,
Thank you for reaching out! We’ve received your issue and are looking into it. To help us track this internally, we’ve created a Linear ticket with the reference: "GHC-5911".
We’ll keep you updated as we make progress, but if you have any additional details or context to share, feel free to add them here - it’s always helpful!
Thanks for your patience and for bringing this to our attention.
---
> For *INTERNAL* use only: [GHC-5911](https://linear.app/n8n/issue/GHC-5911)
---
iamgerwin (2025-12-15T17:32:31Z):
Hi @signo,
I've identified the root cause and submitted a fix in PR #23249.
**Root Cause:**
In commit `890ca377` ("ci: Optimize Docker image build process" - #23149), the `apk del apk-tools` command was moved from the builder stage to the final runtime stage of the n8n-base Dockerfile. This optimization removed the Alpine package manager (`apk`) from the final image, breaking the ability to extend the image with additional packages.
**The Fix:**
Simply remove the `apk del apk-tools` command from the final stage, restoring the package manager in the image.
**Workaround (until fix is released):**
You can work around this by reinstalling `apk-tools` in your custom Dockerfile:
```dockerfile
FROM n8nio/n8n:2.1.0
USER root
# Reinstall apk-tools first
RUN wget -q https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/apk-tools-2.14.8-r0.apk && \
    tar -xzf apk-tools-2.14.8-r0.apk -C / && \
    rm apk-tools-2.14.8-r0.apk
# Now you can use apk
RUN apk add --no-cache ffmpeg
USER node
```
Or simply use `n8n:2.0.2` until the fix is released.
---
Mohamed3nan (2025-12-15T19:23:14Z):
same issue here after upgrading to 2.1, my custom image broke..
---
shortstacked (2025-12-15T20:21:57Z):
Hi @signo, @Mohamed3nan,
Thanks for reporting this and for the detailed reproduction steps!
This change was intentional as part of our ongoing work to optimize and streamline the official Docker images. The removal of `apk-tools` from the final image helps reduce the image footprint and aligns with our goal of providing lean, production-ready containers.
While we understand this impacts workflows that extend the base image, building custom Docker images falls outside the scope of what we officially support. The official n8n images are designed to run n8n out of the box, and we can't guarantee compatibility with all possible customization scenarios.
For those who need additional packages like `ffmpeg`, you can reinstall `apk-tools` in your custom Dockerfile:
```dockerfile
FROM n8nio/n8n:2.1.0
USER root
# Reinstall apk-tools
RUN wget -q https://dl-cdn.alpinelinux.org/alpine/v3.22/main/x86_64/apk-tools-2.14.8-r0.apk && \
    tar -xzf apk-tools-2.14.8-r0.apk -C / && \
    rm apk-tools-2.14.8-r0.apk
# Now install your packages
RUN apk add --no-cache ffmpeg
USER node
```
Alternatively, you could build your own image from scratch using Alpine as a base, or use n8n version 2.0.2 which still includes apk-tools.
We appreciate your understanding, and thanks for being part of the n8n community!
---
DrummyFloyd (2025-12-15T21:25:59Z):
worst decision ever...
```dockerfile
# Reinstall apk-tools since n8n removes it
RUN ARCH=$(uname -m) && \
    wget -qO- "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/" | \
    grep -o 'href="apk-tools-static-[^"]*\.apk"' | head -1 | cut -d'"' -f2 | \
    xargs -I {} wget -q "http://dl-cdn.alpinelinux.org/alpine/latest-stable/main/${ARCH}/{}" && \
    tar -xzf apk-tools-static-*.apk && \
    ./sbin/apk.static -X http://dl-cdn.alpinelinux.org/alpine/latest-stable/main \
        -U --allow-untrusted add apk-tools && \
    rm -rf sbin apk-tools-static-*.apk
# Now apk works normally
RUN apk add --no-cache ffmpeg pipx
USER node
RUN pipx install yt-dlp
ENV PATH="/home/node/.local/bin:${PATH}"
```
something more reliable i think 
---
Mohamed3nan (2025-12-15T22:14:37Z):
Thanks @DrummyFloyd your approach is working nicely..
i just used it in the runner image..
---
bitzerk (2025-12-22T18:13:43Z):
@shortstacked thoughts on having a separate docker image called something like: n8n-minimal? Or vice-versa: n8n-full.
This is a pretty nasty work-around tbh.
