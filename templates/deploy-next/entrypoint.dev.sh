#!/bin/sh
# The development dependency volume starts empty on first boot.
set -e
cd /app

if [ ! -d node_modules ] || [ -z "$(ls -A node_modules 2>/dev/null)" ]; then
    echo ">> installing node_modules (first run)…"
    npm ci --no-audit --no-fund
fi

exec "$@"
