# Rules

- Comments should be rare, factual, and explain only non-obvious external constraints or business invariants.
- Never commit on your own. When a change is ready, stop and ask the user to review the diff and write the commit message themselves; don't draft one for them.
- Don't edit `README.md` or other user-facing documentation (such as `docs/releases/`) unless the user explicitly asks for that change.
- Don't use agents.md as a personal diary, the only time it should ever be changed is by the user or when instructed to by the user.

# Dev container

- `.devcontainer/` is run by rootless Podman as root (= the host user): `.devcontainer/claude.sh`, or "Reopen in Container" with VS Code's `dev.containers.dockerPath` set to `podman`. Debian trixie with Temurin 17, Rust stable + cargo-ndk, gh, Python 3 and podman; `tools/build_local.sh`'s `docker` builds run in it via podman (no host socket).
- The Android SDK/NDK is licensed and not in the image: `bash .devcontainer/android-sdk.sh` installs it into a volume after you accept the licence. adb reaches devices over Wireless debugging only.
- Gradle's `.gradle/`, `app/.cxx/` and the cargo target are container volumes, so host and container builds never share them; APKs still land in `app/build/outputs/`.
- No host credentials are bound: ssh, git config, gh, adb keys and Claude state are volumes. Only `~/.claude/skills` and `~/.claude/plugins` come in, read-only.
