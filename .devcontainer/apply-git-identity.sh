#!/usr/bin/env bash
# Gives this container's git the identity (user.name / user.email) the host's
# global git config has -- those two values, **nothing else from the host**.
# initialize.sh (which runs on the host) wrote them to
# .devcontainer/git-identity.env, a plain git-config-format file in the
# workspace (gitignored by `*.env`); no ~/.gitconfig, no key, no credential is
# bound in. Only a value that is *not set yet* is filled in, so an identity you
# chose inside the container (it lives on the gitconfig volume) is never
# replaced. Run by post-create.sh and by claude.sh before every session, so a
# changed host identity or a reused container is picked up without a rebuild.
set -euo pipefail

src="$(dirname "$0")/git-identity.env"
[ -f "$src" ] || exit 0

for key in user.name user.email; do
    if ! git config --global --get "$key" >/dev/null 2>&1; then
        value=$(git config -f "$src" --get "$key" 2>/dev/null || true)
        if [ -n "$value" ]; then
            git config --global "$key" "$value"
            echo "git $key set from the host's global git config: $value"
        fi
    fi
done
