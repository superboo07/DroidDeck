#!/usr/bin/env bash
# A bash shell inside the devcontainer, in the workspace.
#
#   .devcontainer/bash.sh              # interactive shell
#   .devcontainer/bash.sh --recreate   # ...after throwing the old container away
#   .devcontainer/bash.sh make test    # run a command instead
set -euo pipefail
cd "$(dirname "$0")/.."
. .devcontainer/lib_devcontainer.sh "$@"

if [ ${#DC_ARGS[@]} -eq 0 ]; then
	exec $DC exec "${ENGINE[@]}" --workspace-folder . bash -l
fi
exec $DC exec "${ENGINE[@]}" --workspace-folder . "${DC_ARGS[@]}"
