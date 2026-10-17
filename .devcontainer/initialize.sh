#!/usr/bin/env bash
# **Runs on the host, before the container exists** (devcontainer.json's
# initializeCommand -- VS Code, the devcontainer CLI and claude.sh alike).
#
#
# 3. The image is built here, with a plain `podman build` (rootless, as you),
#    and the container config only names it. The dev container tooling never
#    builds it: its generated Dockerfile-with-features build lives outside the
#    build context (Docker's buildx bake refuses it outright), and a plain build
#    of this directory is the same on every engine. Layer caching keeps it
#    quick when nothing changed; "Rebuild Container" runs it again.
#    CLAUDE_CODE_VERSION in the host environment (stable, latest, or a version)
#    is passed through; add --no-cache by hand to re-fetch a moving channel.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v podman >/dev/null 2>&1; then
    echo "error: this dev container is run by rootless Podman, and podman is not on PATH." >&2
    exit 1
fi


build_args=()
if [ -n "${CLAUDE_CODE_VERSION:-}" ]; then
    build_args+=(--build-arg "CLAUDE_CODE_VERSION=$CLAUDE_CODE_VERSION")
fi

podman build "${build_args[@]}" -t localhost/droiddeck-devcontainer:latest .devcontainer
