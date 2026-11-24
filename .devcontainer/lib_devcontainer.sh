# Bring the devcontainer up and leave $DC set to the CLI that did it.
# Sourced by claude.sh and bash.sh; not runnable on its own.
#
# Pass "$@" in. A leading --recreate or --rebuild is consumed here and the rest
# is left in DC_ARGS for the caller.
#
# `up` is idempotent: it starts the container if it is not running and **reuses
# it if it is**. initialize.sh rebuilds the image on every run, so a Dockerfile
# edit lands in the IMAGE immediately -- but a container that is already up is
# still the old one, and a new package is simply absent, with nothing saying so.
# Measured: a cross-compiler added to the Dockerfile, image rebuilt, script
# re-run, tool still "command not found". --recreate is how you get it.
#
# VS Code is not needed for any of this -- the devcontainer CLI reads the same
# devcontainer.json, and runs it with rootless Podman like VS Code does
# (with "dev.containers.dockerPath": "podman").

DC_ARGS=()
UP_EXTRA=()
for a in "$@"; do
	case $a in
		--recreate|--rebuild) UP_EXTRA+=(--remove-existing-container) ;;
		*) DC_ARGS+=("$a") ;;
	esac
done

CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/devcontainers-cli

DC=${DEVCONTAINER_CLI:-}
if [ -z "$DC" ]; then
	if command -v devcontainer >/dev/null 2>&1; then
		DC="devcontainer"
	elif command -v npx >/dev/null 2>&1; then
		DC="npx --yes @devcontainers/cli"
	elif command -v node >/dev/null 2>&1; then
		# No npm on this machine, but node alone is enough: unpack the published
		# tarball once and run it from the cache.
		if [ ! -f "$CACHE_DIR/package/devcontainer.js" ]; then
			echo "Fetching @devcontainers/cli into $CACHE_DIR ..." >&2
			mkdir -p "$CACHE_DIR"
			python3 - "$CACHE_DIR" <<-'PY'
				import io, json, sys, tarfile, urllib.request
				dest = sys.argv[1]
				meta = json.load(urllib.request.urlopen("https://registry.npmjs.org/@devcontainers/cli"))
				url = meta["versions"][meta["dist-tags"]["latest"]]["dist"]["tarball"]
				blob = urllib.request.urlopen(url).read()
				tarfile.open(fileobj=io.BytesIO(blob)).extractall(dest)
			PY
		fi
		DC="node $CACHE_DIR/package/devcontainer.js"
	else
		echo "error: no 'devcontainer', 'npx' or 'node' on PATH." >&2
		echo "       install the CLI with: npm install -g @devcontainers/cli" >&2
		exit 1
	fi
fi

# Rootless Podman (devcontainer.json says why). The flag goes after the
# subcommand: before `exec`, the CLI reads "exec" as the program to run.
ENGINE=(--docker-path podman)

$DC up "${ENGINE[@]}" ${UP_EXTRA[@]+"${UP_EXTRA[@]}"} --workspace-folder .
