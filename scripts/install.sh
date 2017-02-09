#!/usr/bin/env bash

path=`realpath $(dirname $0)/..`
jail=${path}/jail
dir=/etc/schroot/mit-scheme

mkdir -p ${dir}

config="
CHROOT_DIRECTORY=\${USER_PATH}
SETUP_COPYFILES=mit-scheme/copyfiles
SETUP_NSSDATABASES=mit-scheme/nssdatabases
SETUP_FSTAB=mit-scheme/fstab
"

fstab="
${path}/chroot/bin   /bin    none ro,bind 0 0
${path}/chroot/lib   /lib    none ro,bind 0 0
${path}/chroot/lib64 /lib64  none ro,bind 0 0
${path}/utils        /utils  none ro,bind 0 0
"

echo "${fstab}"         > ${dir}/fstab
echo "${config}"        > ${dir}/config
echo "/etc/resolv.conf" > ${dir}/copyfiles
echo ""                 > ${dir}/nssdatabases

conf="
[mit-scheme]
type=directory
directory=${jail}
groups=users
root-groups=root,sudo
profile=mit-scheme
shell=/bin/bash
user.path=${jail}
user-modifiable-keys=user.path
"

echo "${conf}" > /etc/schroot/chroot.d/mit-scheme.conf
