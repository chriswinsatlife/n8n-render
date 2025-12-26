# Render Support Request

**Service ID:** srv-d117ruqdbo4c739o7bhg

## Problem

When I set a dockerCommand, `/usr/bin/env node` fails at runtime even though:
- The symlink `/usr/bin/node -> /usr/local/bin/node` exists (verified in build logs)
- `/usr/bin/env node -v` works during build and returns v22.21.1
- My web service using the same Dockerfile with NO dockerCommand works fine

## dockerCommand

```
/usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10
```

## Dockerfile

[https://github.com/chriswinsatlife/n8n-render/blob/main/Dockerfile](https://github.com/chriswinsatlife/n8n-render/blob/main/Dockerfile)

## Error

```
/usr/bin/env: 'node': No such file or directory
```

## Question

Why does dockerCommand cause PATH or /usr/bin to behave differently at runtime than during build?
