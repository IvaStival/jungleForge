#!/bin/sh
# Production assets and the standalone server are already baked into the image.
set -e
cd /app
exec "$@"
