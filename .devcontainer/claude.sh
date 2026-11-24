#!/usr/bin/env bash
# Start Claude Code inside the devcontainer, from a plain terminal.
#
#   .devcontainer/claude.sh              # interactive session in the container
#   .devcontainer/claude.sh --recreate   # ...after throwing the old container away
#   .devcontainer/claude.sh -p "..."     # anything else is passed to claude
set -euo pipefail
cd "$(dirname "$0")/.."
. .devcontainer/lib_devcontainer.sh "$@"

$DC exec "${ENGINE[@]}" --workspace-folder . bash .devcontainer/enable-plugins.sh >&2
$DC exec "${ENGINE[@]}" --workspace-folder . bash .devcontainer/apply-git-identity.sh >&2

# welcome.sh says what still needs doing. post-create's output never reaches
# here, and a reused container does not run it at all. To stderr so `claude -p`
# output stays clean; exit 10 means there is a to-do worth reading before
# Claude's UI scrolls it away.
status=0
$DC exec "${ENGINE[@]}" --workspace-folder . bash .devcontainer/welcome.sh >&2 || status=$?
if [ "$status" = 10 ] && [ -t 0 ] && [ -t 2 ]; then
	read -r -p "Press Enter to start Claude... " _ >&2 || true
fi

exec $DC exec "${ENGINE[@]}" --workspace-folder . claude ${DC_ARGS[@]+"${DC_ARGS[@]}"}
