# Shared Rust base image for jungleforge Rust dev-shell projects (e.g. a Tauri app under
# active development). Dev-only — unlike base/php.Dockerfile and base/node.Dockerfile there is no
# prod target: this stack is for local development tooling, not something this control plane
# deploys.
#
# Debian, not Alpine (unlike the php/node bases): the upstream `rust` image is Debian-based, and
# switching to `rust:*-alpine` risks musl-linking issues for crates with C dependencies (e.g.
# rusqlite's `bundled` sqlite).
#
# Build with: make base-rust   (or `make base-rust 1.82` to pin a specific version).
ARG RUST_VERSION=1

FROM rust:${RUST_VERSION} AS dev
RUN rustup component add rustfmt clippy rust-analyzer \
    && cargo install cargo-watch cargo-edit cargo-expand

# Pre-configured zsh: oh-my-zsh + powerlevel10k + autosuggestions + syntax-highlighting.
# Cloned (shallow) rather than via the curl|sh installer; .git dirs stripped to keep it small.
# Config is shipped (base/zsh/*) so there is NO `p10k configure` wizard on first shell.
RUN apt-get update \
    && apt-get install -y --no-install-recommends git zsh \
    && git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git                  /root/.oh-my-zsh \
    && git clone --depth=1 https://github.com/romkatv/powerlevel10k.git            /root/.oh-my-zsh/custom/themes/powerlevel10k \
    && git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git    /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions \
    && git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
    && find /root/.oh-my-zsh -name '.git' -prune -exec rm -rf {} + \
    && rm -rf /var/lib/apt/lists/*
COPY base/zsh/zshrc    /root/.zshrc
COPY base/zsh/p10k.zsh /root/.p10k.zsh

WORKDIR /workspace
