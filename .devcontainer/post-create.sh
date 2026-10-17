#!/usr/bin/env bash
# Runs once, after the container is created. Idempotent and never destructive:
# nothing that already exists is replaced.
set -euo pipefail

cd "$(dirname "$0")/.."

# The tree is a bind mount from the host, so git sees an owner that is not the
# user running it.
git config --global --add safe.directory "$PWD" || true

bash .devcontainer/enable-plugins.sh


# Everything to tell you -- a missing input, git identity, signing key, the
# commands -- is in welcome.sh, which checks the state as it is *now* and runs
# again in every terminal and before claude.sh starts Claude. Output from this
# script only reaches the creation log, which nobody sees twice.
bash .devcontainer/welcome.sh || true
