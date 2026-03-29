# '--shm-size 2G' is needed to more stable Firefox work and avoid crashing on shared memory lacks
# --security-opt="seccomp=unconfined": avoids Firefox error "Sandbox: CanCreateUserNamespace() clone() failure: EPERM"

docker run --rm -it --shm-size 2G \
           -e DISPLAY="$DISPLAY" \
           -e ENV_USER="$USER" \
           -e ENV_USER_ID="$(id -u)" \
           -e ENV_USER_GROUP_ID="$(id -g)" \
           --security-opt="seccomp=unconfined" \
           -v "$(pwd)/Documents":"$HOME/Documents" \
           -v /run/pcscd/pcscd.comm:/run/pcscd/pcscd.comm \
           -v /tmp/.X11-unix:/tmp/.X11-unix \
           -v "$HOME/.Xauthority":"$HOME/.Xauthority" \
           cryptopro
