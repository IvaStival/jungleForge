# syntax=docker/dockerfile:1
# THE one shared Rust project image (Rust counterpart of build/php.Dockerfile and
# build/node.Dockerfile). Dev-only stack: a single thin layer on the prebuilt
# jungleforge/rust:<v>-dev base. Code is volume-mounted, container just runs `sleep infinity`
# (see docker-compose.rust.dev.yml) — this is a dev shell for `cargo`/`clippy`/etc, not a served
# app, so there is no prod stage here.
ARG RUST_VERSION=1

FROM jungleforge/rust:${RUST_VERSION}-dev AS dev
WORKDIR /workspace
