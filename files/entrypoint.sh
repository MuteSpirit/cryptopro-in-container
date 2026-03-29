#!/bin/sh

# Set next environment variables preliminary to execute this script:
#   ENV_USER - username
#   ENV_USER_ID - user ID 
#   ENV_USER_GROUP_ID - user group ID
# That information has been used to create such unprivileged user and perform docker CMD commands with it's permissions
#   Reason 1: browser will be run not by 'root'
#   Reason 2: files downloaded by browser will be stored in mounted folder with unprivileged user ownership 
#             and host user will have no troubles to access them
main()
{
    if [ -z "$ENV_USER" ]; then
        echo 'Use docker run cmdline option: -e ENV_USER="$USER"'
        exit 1
    fi

    if [ -z "$ENV_USER_ID" ]; then
        echo 'Use docker run cmdline option: -e ENV_USER_ID="$(id -u)"'
        exit 1
    fi

    if [ -z "$ENV_USER_GROUP_ID" ]; then
        echo 'Use docker run cmdline option: -e ENV_USER_GROUP_ID="$(id -g)"'
        exit 1
    fi

    addgroup --gid "$ENV_USER_GROUP_ID" "$ENV_USER"
    
    mkdir -p "/home/$ENV_USER"
    chown "$ENV_USER_ID":"$ENV_USER_GROUP_ID" -R "/home/$ENV_USER"

    adduser  --uid "$ENV_USER_ID" \
             --gid "$ENV_USER_GROUP_ID" \
             --disabled-password \
             --gecos "" \
             "$ENV_USER"

    # Allows regular user to access crypto containers:
    cat <<EOF > /usr/share/polkit-1/rules.d/pcsc.rules
polkit.addRule(function(action, subject) {
    if (action.id == "org.debian.pcsc-lite.access_card" &&
        subject.user == "$ENV_USER") {
            return polkit.Result.YES;
    }
});

polkit.addRule(function(action, subject) {
    if (action.id == "org.debian.pcsc-lite.access_pcsc" &&
        subject.user == "$ENV_USER") {
            return polkit.Result.YES;
    }
});
EOF

    su --pty "$ENV_USER" /bin/sh -c "cd \"/home/$ENV_USER\"; $*"
}

main "$@"
