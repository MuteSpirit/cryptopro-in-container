#!/bin/bash
#
# Script globally install downloaded XPI as Firefox addon
#   Reason 1: avoid user manual effort and just use preconfigure browser
#   Reason 2: way of downloading is responsibility of another code or user
# Plugin id/name is taken from XPI internals
#   Reason: avoid hard-code such info in Dockerfile
#
# Idea has been taken from https://askubuntu.com/a/1169161
# Thanks to darkdragon (https://askubuntu.com/users/206608/darkdragon)

install_addon() {
    # Installs .xpi file as Firefox plugin
    #
    # $1 - XPI file absolute path
    # $2 - extensions directory absolute path

    local xpi=$1
    local extensions_path=$2
    local new_filename
    new_filename=$(get_addon_id_from_xpi "$xpi").xpi
    
    local addon_name
    addon_name=$(get_addon_name_from_xpi "$xpi")

    local new_filepath="${extensions_path}/${new_filename}"
    if [ -f "$new_filepath" ]; then
        echo "File already exists: $new_filepath"
        echo "Skipping installation for addon $addon_name."
    else
        cp -v "$xpi" "$new_filepath"
    fi
}

get_addon_id_from_xpi() {
    # $1 - path to .xpi file
    local id
    id=$(unzip -p "$1" manifest.json | jq .applications.gecko.id | tr -d '"')
    if [ -z "$id" ] || [ "null" = "$id" ]; then
        id=$(unzip -p "$1" manifest.json | jq .browser_specific_settings.gecko.id | tr -d '"')
    fi
    echo $id
}

get_addon_name_from_xpi() {
    # $1 - path to .xpi file
    unzip -p "$1" manifest.json | jq .name | tr -d '"'
}

install_addon "$@"
