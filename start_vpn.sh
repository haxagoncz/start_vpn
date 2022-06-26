#!/bin/bash

# This script expects a valid wireguard config to be piped through stdin
# initializes the wireguard interface for haxagon
# it downloads wireguard if it can't find it and if it can install it

if [ "$EUID" -ne 0 ]; then
    echo "Script must be run as root"
    exit 1
fi

DISTRO=$(cat /etc/os-release | grep ^ID= | cut -d = -f 2 | tr -d \")

if ! which wg-quick > /dev/null 2>&1; then

    case $DISTRO in

        manjaro | arch)
            pacman -S wireguard-tools --noconfirm
        ;;

        debian | ubuntu)
            apt update
            apt install wireguard -y
        ;;

        fedora)
            dnf install wireguard-tools -y
        ;;

        centos)
            yum install elrepo-release epel-release -y
            yum install kmod-wireguard wireguard-tools -y
        ;;

        rhel)
            yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
            yum install kmod-wireguard wireguard-tools  -y
        ;;

        *)
            echo "This script doesn't support your distro, please install Wireguard manually"
            echo "https://www.wireguard.com/install/"
            exit 1
        ;;

    esac

fi

CONFIG_BASE64=$(cat)

CONFIG_DIR=$(mktemp -d)

echo "$CONFIG_BASE64" | base64 -d > "$CONFIG_DIR"/haxagon.conf

wg-quick up "${CONFIG_DIR}"/haxagon.conf

rm "${CONFIG_DIR}"/haxagon.conf

echo
echo "Use: 'ip link del haxagon' to turn off vpn"
