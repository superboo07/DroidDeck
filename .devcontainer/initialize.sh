#!/usr/bin/env bash
# **Runs on the host, before the container exists** (devcontainer.json's
# initializeCommand -- VS Code, the devcontainer CLI and claude.sh alike).
#
# 1. The image is built here, with a plain `podman build` (rootless, as you),
#    and the container config only names it. The dev container tooling never
#    builds it: its generated Dockerfile-with-features build lives outside the
#    build context (Docker's buildx bake refuses it outright), and a plain build
#    of this directory is the same on every engine. Layer caching keeps it
#    quick when nothing changed; "Rebuild Container" runs it again.
#    CLAUDE_CODE_VERSION in the host environment (stable, latest -- the
#    default -- or a version) picks Claude Code. **A channel is resolved to its
#    current version number here**, and that number is the build arg: with the
#    channel name as the arg the layer's cache key never changed, so the image
#    kept whichever release was current at the first build, forever. A new
#    release now rebuilds that layer (and only the ones after it) on the next
#    start; offline, the channel name is passed and the cached layer is kept.
#
# 2. The host's global git identity -- user.name and user.email, those two
#    values only -- is written to .devcontainer/git-identity.env (gitignored by
#    `*.env`) for apply-git-identity.sh to put into the container's own git
#    config, so nobody types it in again. **Nothing else is read from the host's
#    git config** (no signing key, no credential helper, no includes), and the
#    file is a copy of two strings, not a mount.
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v podman >/dev/null 2>&1; then
    echo "error: this dev container is run by rootless Podman, and podman is not on PATH." >&2
    exit 1
fi

# Host identity -> workspace file. Rewritten on every start so it follows the
# host; removed when the host has none, so a stale one never lingers.
identity=.devcontainer/git-identity.env
rm -f "$identity"
if command -v git >/dev/null 2>&1; then
    for key in user.name user.email; do
        value=$(git config --global --get "$key" 2>/dev/null || true)
        if [ -n "$value" ]; then
            git config -f "$identity" "$key" "$value"
        fi
    done
fi

claude_version=${CLAUDE_CODE_VERSION:-latest}
case $claude_version in
    stable|latest)
        resolved=$(curl -fsSL --max-time 10 "https://downloads.claude.ai/claude-code-releases/$claude_version" 2>/dev/null || true)
        if [[ $resolved =~ ^[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+-]*$ ]]; then
            claude_version=$resolved
        else
            echo "warning: could not look up Claude Code's '$claude_version' release; keeping the image's cached one." >&2
        fi
        ;;
esac
build_args=(--build-arg "CLAUDE_CODE_VERSION=$claude_version")

podman build "${build_args[@]}" -t localhost/droiddeck-devcontainer:latest .devcontainer
