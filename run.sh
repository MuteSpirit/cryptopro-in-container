#!/bin/bash
# '--shm-size 2G' is needed to more stable Chromium-Gost work and avoid crashing on shared memory lacks
# --security-opt="seccomp=unconfined": avoids Chromium-Gost sandbox errors inside the container

RUNNER=${RUNNER:-docker}

# Build volume args array for optional mounts
VOLS=()
VOLS+=(-v "$(pwd)/Downloads":"$HOME/Downloads")
VOLS+=(-v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm)
VOLS+=(-v /tmp/.X11-unix:/tmp/.X11-unix)
VOLS+=(-v "$XDG_RUNTIME_DIR":"$XDG_RUNTIME_DIR")

# .Xauthority - only mount if file exists on host
if [ -f "$HOME/.Xauthority" ]; then
    VOLS+=(-v "$HOME/.Xauthority":"$HOME/.Xauthority:ro")
fi

$RUNNER run --rm -it --shm-size 2G \
           -e DISPLAY="$DISPLAY" \
           -e XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
           -e ENV_USER="$USER" \
           -e ENV_USER_ID="$(id -u)" \
           -e ENV_USER_GROUP_ID="$(id -g)" \
           --security-opt="seccomp=unconfined" \
           "${VOLS[@]}" \
           cryptopro $@
