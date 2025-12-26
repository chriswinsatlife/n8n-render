# Render Support Request

**Service ID:** srv-d117ruqdbo4c739o7bhg
**Recent Deploy ID:** dep-d57cgqpr0fns73a30gmg

## Problem

When I set a dockerCommand, `/usr/bin/env node` fails at runtime even though:
- The symlink `/usr/bin/node -> /usr/local/bin/node` exists (verified in build logs)
- `/usr/bin/env node -v` works during build and returns v22.21.1
- My web service using the same Dockerfile with NO dockerCommand works fine

## dockerCommand

```
/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10
```

## Previously Tried and Failed dockerCommands
- `/bin/sh -c 'export PATH=/usr/local/bin:$PATH && exec n8n worker --concurrency=10'`
- `n8n worker --concurrency=10`
- `worker --concurrency=10`
- `tini -- /docker-entrypoint.sh n8n worker --concurrency=10`
- `/usr/local/bin/node /usr/local/lib/node_modules/n8n/packages/cli/bin/n8n.js worker --concurrency=10`
- `` (blank)

## Dockerfile

[https://github.com/chriswinsatlife/n8n-render/blob/main/Dockerfile](https://github.com/chriswinsatlife/n8n-render/blob/main/Dockerfile)

## Error

```
/usr/bin/env: 'node': No such file or directory
```

## Also Tried
- Explicit `ENV PATH="/usr/local/bin:/usr/bin:/bin:$PATH"` in Dockerfile - still fails at runtime

## Question

Why does dockerCommand cause `/usr/bin/env node` to fail at runtime when it works during build? The symlink and PATH both exist in the image.
