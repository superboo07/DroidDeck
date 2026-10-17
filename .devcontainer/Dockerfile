# The devcontainer image: the toolchain README.md "Build" and
# .github/workflows/build.yml ask for, and Claude Code.
#
# **The Android SDK/NDK is not in this image**: it is licensed, and you accept
# its licence yourself (.devcontainer/android-sdk.sh installs it into a volume).
# No signing keys or other secrets are in it either.
#
# Everything runs as root in here. The container is run by **rootless Podman**,
# so container root is your own host user: files written into the bind-mounted
# tree stay owned by you, and root in here has no privilege you do not have.
FROM docker.io/library/debian:trixie-slim

# tools/build_local.sh: curl tar zstd shasum (perl) unzip python3 gh; the
# helper builds also use make, patch and GNU awk (tools/proot/build.sh) and git.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		pkg-config \
		python3 \
		perl \
		git \
		ca-certificates \
		curl \
		gnupg \
		file \
		xz-utils \
		zstd \
		unzip \
		zip \
		patch \
		gawk \
		jq \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Java 17 (README, CI setup-java 17). Debian trixie ships no OpenJDK 17.
RUN curl -fsSL https://packages.adoptium.net/artifactory/api/gpg/key/public \
		| gpg --dearmor -o /usr/share/keyrings/adoptium.gpg \
	&& echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb trixie main" \
		> /etc/apt/sources.list.d/adoptium.list \
	&& apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get install -y --no-install-recommends temurin-17-jdk \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* \
	&& ln -s "$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")" /usr/lib/jvm/java-17
ENV JAVA_HOME=/usr/lib/jvm/java-17

# GitHub CLI: build_local.sh downloads the pinned Gamescope and droiddeck-esync
# release assets with `gh release download`.
RUN curl -fsSL -o /usr/share/keyrings/githubcli.gpg https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	&& echo "deb [signed-by=/usr/share/keyrings/githubcli.gpg] https://cli.github.com/packages stable main" \
		> /etc/apt/sources.list.d/github-cli.list \
	&& apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get install -y --no-install-recommends gh \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Rust for the store engines (CI "Rust toolchain for the store engines" +
# "cargo-ndk"). app/build.gradle runs `rustup run stable cargo ndk` from
# ${user.home}/.cargo/bin, so rustup lives under /root.
ENV RUSTUP_HOME=/root/.rustup CARGO_HOME=/root/.cargo
ENV PATH=/root/.cargo/bin:$PATH
RUN set -eu; \
	case "$(uname -m)" in \
		x86_64) triple=x86_64-unknown-linux-gnu ;; \
		aarch64) triple=aarch64-unknown-linux-gnu ;; \
	esac; \
	base=https://static.rust-lang.org/rustup/dist/$triple; \
	curl -fsSL -o /tmp/rustup-init "$base/rustup-init"; \
	echo "$(curl -fsSL "$base/rustup-init.sha256" | cut -d' ' -f1)  /tmp/rustup-init" | sha256sum -c -; \
	chmod +x /tmp/rustup-init; \
	/tmp/rustup-init -y --no-modify-path --profile minimal --default-toolchain stable; \
	rm /tmp/rustup-init; \
	rustup target add aarch64-linux-android; \
	cargo install cargo-ndk --locked; \
	rm -rf /root/.cargo/registry /root/.cargo/git

# Go for tools/syncthing/build.sh. Debian's Go only bootstraps: the script sets
# GOTOOLCHAIN to the fork's pinned go_version, which Go downloads and verifies.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get install -y --no-install-recommends golang-go \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Fail the image build, not the first configure inside it.
RUN set -e; \
	java -version 2>&1 | grep -q '"17\.' || { echo "Java 17 missing (README.md Build, CI setup-java)" >&2; exit 1; }; \
	python3 -c 'import sys; assert sys.version_info >= (3, 11)' || { echo "Python 3 too old (README.md Build)" >&2; exit 1; }; \
	rustup target list --installed | grep -qx aarch64-linux-android || { echo "Rust target aarch64-linux-android missing (CI)" >&2; exit 1; }; \
	cargo ndk --version; gh --version; \
	go version; \
	for t in curl tar zstd shasum unzip python3 make patch git; do \
		command -v "$t" >/dev/null || { echo "$t missing (tools/build_local.sh)" >&2; exit 1; }; \
	done

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get install -y --no-install-recommends \
		less procps bash-completion openssh-client ripgrep \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

# **Container builds work in here, with podman**: build_local.sh, tools/vr and
# tools/comet `docker build`/`docker run` their cross-compile images
# (podman-docker is the `docker` command). There is no container socket from
# the host: handing one in would give the container the host's engine. The
# container config supplies SYS_ADMIN inside our user namespace, seccomp
# unconfined for pivot_root/keyctl and a storage volume; this covers what a
# container cannot do:
#  - netns=host: netavark cannot create bridges (netlink EPERM).
#  - cgroups=disabled: /sys/fs/cgroup is read-only in here.
#  - keyring=false: session keyrings are denied.
#  - short names resolve on Docker Hub, as `FROM ubuntu:24.04` does in Docker.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
	&& apt-get install -y --no-install-recommends \
		podman podman-docker crun uidmap \
	&& apt-get clean && rm -rf /var/lib/apt/lists/* \
	&& printf '%s\n' '[containers]' 'netns = "host"' 'cgroups = "disabled"' 'keyring = false' \
		'[engine]' 'cgroup_manager = "cgroupfs"' > /etc/containers/containers.conf \
	&& printf '%s\n' 'unqualified-search-registries = ["docker.io"]' 'short-name-mode = "permissive"' \
		> /etc/containers/registries.conf.d/50-docker-hub.conf \
	&& touch /etc/containers/nodocker

COPY --chmod=0755 docker /usr/local/bin/docker

# Claude Code, from Anthropic's release channel. `stable`/`latest` are moving
# channels; anything else is a pinned version. The checksum comes from the
# release manifest, so a truncated or substituted download fails the build.
ARG CLAUDE_CODE_VERSION=latest
RUN set -eu; \
	base=https://downloads.claude.ai/claude-code-releases; \
	case "${CLAUDE_CODE_VERSION}" in \
		stable|latest) version=$(curl -fsSL "$base/${CLAUDE_CODE_VERSION}") ;; \
		*) version="${CLAUDE_CODE_VERSION}" ;; \
	esac; \
	case "$(uname -m)" in \
		x86_64) platform=linux-x64 ;; \
		aarch64) platform=linux-arm64 ;; \
		*) echo "no Claude Code build for $(uname -m)" >&2; exit 1 ;; \
	esac; \
	curl -fsSL "$base/$version/manifest.json" \
		| python3 -c "import json,sys; print(json.load(sys.stdin)['platforms']['$platform']['checksum'])" \
		> /tmp/claude.sha256; \
	curl -fsSL -o /usr/local/bin/claude "$base/$version/$platform/claude"; \
	echo "$(cat /tmp/claude.sha256)  /usr/local/bin/claude" | sha256sum -c -; \
	chmod +x /usr/local/bin/claude; \
	rm -f /tmp/claude.sha256; \
	claude --version

# The image owns the version; rebuild the container to move it.
ENV DISABLE_AUTOUPDATER=1
ENV DISABLE_INSTALLATION_CHECKS=1

# Mount points for the container config's volumes, so the volumes inherit
# owner and mode (ssh refuses a .ssh that is not 0700). **Nothing is copied
# from the host.**
RUN install -d -m 0700 /root/.ssh /root/.android /root/.config/gh \
	&& install -d /root/.config/git /root/.claude /var/lib/containers /commandhistory \
		/root/.gradle /root/.cache /root/.cargo/registry /root/.cargo/git /opt/android-sdk \
	&& install -m 0600 /dev/null /commandhistory/.bash_history

# HTTP(S) push credentials go to the gitconfig volume; git's default
# ~/.git-credentials would be lost on rebuild.
RUN git config --system credential.helper 'store --file /root/.config/git/credentials'

ENV ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk
ENV PATH=/opt/android-sdk/cmdline-tools/latest/bin:/opt/android-sdk/platform-tools:$PATH
# The store engines' cargo target stays off the shared tree (the host may build too).
ENV CARGO_TARGET_DIR=/root/.cache/cargo-target
ENV HISTFILE=/commandhistory/.bash_history

# welcome.sh in interactive terminals: full the first time, to-do items after.
RUN cat >> /root/.bashrc <<'SH'

if [[ $- == *i* ]] && [ -f /workspaces/droiddeck/.devcontainer/welcome.sh ]; then
	if [ -e /tmp/.welcome-shown ]; then
		bash /workspaces/droiddeck/.devcontainer/welcome.sh --brief
	else
		bash /workspaces/droiddeck/.devcontainer/welcome.sh; touch /tmp/.welcome-shown
	fi
fi
SH

ENV DEVCONTAINER=true
