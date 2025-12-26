#!/bin/sh
set -e

echo "--- Worker Entrypoint Starting ---"
echo "Original PATH: $PATH"
echo "User: $(whoami)"

# Force PATH to include node location
export PATH=/usr/local/bin:/usr/bin:/bin:$PATH
echo "New PATH: $PATH"

# Verify node exists
if command -v node >/dev/null 2>&1; then
    echo "Node found at: $(command -v node)"
    node -v
else
    echo "CRITICAL: Node not found in PATH"
    ls -l /usr/local/bin/node || echo "/usr/local/bin/node missing"
    ls -l /usr/bin/node || echo "/usr/bin/node missing"
fi

# Execute n8n worker
echo "Exec n8n worker..."
# We execute the n8n binary directly using node to bypass any shebang/env issues in the launcher script
exec /usr/local/bin/node /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10
