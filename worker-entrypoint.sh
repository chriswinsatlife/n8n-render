#!/bin/sh
set -e

echo "--- Worker Entrypoint Starting ---"
echo "User: $(whoami)"
echo "PATH: $PATH"

# Locate node
NODE_BIN=$(command -v node || echo "/usr/local/bin/node")
if [ ! -x "$NODE_BIN" ]; then
    echo "Node not found at $NODE_BIN, checking /usr/bin/node"
    NODE_BIN="/usr/bin/node"
fi

echo "Using Node: $NODE_BIN"
$NODE_BIN -v

# Execute n8n worker directly with node to bypass shebang/env issues
echo "Exec n8n worker..."
exec $NODE_BIN /usr/local/lib/node_modules/n8n/bin/n8n worker --concurrency=10
