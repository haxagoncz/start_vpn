#!/bin/bash

# This script expects a valid wireguard config to be piped through stdin
# initializes the wireguard interface for haxagon
# it downloads wireguard if it can't find it and if it can install it

if [ $(id -u) -ne 0 ]; then
    echo "Script must be run as root"
    exit 1
fi
if [ $# -ne 1 ]; then
	echo "No wg config provided"
	echo "Usage: ./start_vpn.sh \$BASE64_WGCONFIG"
	exit 1
fi

if ! which wg-quick > /dev/null 2>&1; then
    DISTRO=$(cat /etc/os-release | grep ^ID= | cut -d = -f 2 | tr -d \")
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
	gentoo)
	   emerge --verbose net-vpn/wireguard-tools
        ;;
        *)
            echo "This script doesn't support automatic install for your distro, please install Wireguard manually"
            echo "https://www.wireguard.com/install/"
            exit 1
        ;;
        
    esac
    
fi

CONFIG_BASE64="$1"

CONFIG_DIR=$(mktemp -d)

echo "$CONFIG_BASE64" | base64 -d > "$CONFIG_DIR"/haxagon.conf

if ip a | grep haxagon 2>&1 > /dev/null; then
    ip link del haxagon 2>&1 > /dev/null
fi

wg-quick up ${CONFIG_DIR}/haxagon.conf

rm ${CONFIG_DIR}/haxagon.conf

mkdir -p /usr/local/etc/wireguard /etc/wireguard

echo "" | tee /usr/local/etc/wireguard/haxagon.conf > /etc/wireguard/haxagon.conf

echo
echo "Use: 'wg-quick down haxagon' to turn off vpn"
