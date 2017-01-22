#!/usr/bin/env bash

path=$1
root=$2
schroot=$3
public=${root}/public
dir=/etc/schroot/${schroot}

mkdir -p ${root}/users ${public}/{etc,pipes,files,tmp} ${dir}

chmod a+w ${public} ${public}/{files,pipes}

config="
CHROOT_DIRECTORY=\${USER_PATH}

SETUP_COPYFILES=${schroot}/copyfiles
SETUP_NSSDATABASES=${schroot}/nssdatabases
SETUP_FSTAB=${schroot}/fstab
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
[${schroot}]
type=directory
directory=${public}
groups=users
root-groups=root,sudo
profile=${schroot}
shell=/bin/bash
user.path=${public}
user-modifiable-keys=user.path
"

echo "${conf}" > /etc/schroot/chroot.d/${schroot}.conf
