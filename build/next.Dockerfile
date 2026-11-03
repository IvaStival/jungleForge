# syntax=docker/dockerfile:1
# Shared Next.js image. `next` is deliberately distinct from the Vite-oriented `node` stack:
# development runs `next dev`; production serves Next's standalone output with Node.
ARG NODE_VERSION=20

# === DEV: source is mounted by compose; dependencies persist on an anonymous volume. ===
FROM jungleforge/node:${NODE_VERSION}-dev AS dev
COPY deploy/supervisor/supervisord.dev.conf /etc/supervisor/supervisord.conf
COPY deploy/entrypoint.dev.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint
WORKDIR /app
EXPOSE 3000
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]

# === DEPS: install against the lockfile before source changes are copied. ===
FROM --platform=$BUILDPLATFORM node:${NODE_VERSION}-alpine AS deps
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

# === BUILD: NEXT_PUBLIC_* values are intentionally sourced only at image-build time. ===
FROM deps AS build
COPY . .
RUN --mount=type=secret,id=docker_env \
    set -a && . /run/secrets/docker_env && set +a && npm run build

# === APP: compact Next standalone server and static assets, no source or full node_modules. ===
FROM jungleforge/node:${NODE_VERSION}-prod AS app
ENV NODE_ENV=production \
    NEXT_TELEMETRY_DISABLED=1 \
    HOSTNAME=0.0.0.0
COPY deploy/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY deploy/entrypoint.sh /usr/local/bin/entrypoint
RUN chmod +x /usr/local/bin/entrypoint
WORKDIR /app
COPY --from=build /app/public ./public
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
EXPOSE 3000
ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/entrypoint"]
CMD ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
