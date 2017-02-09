#!/usr/bin/env bash

user=$1
uuid=$2
band=$3
mkdir -p ${user}/{etc,tmp}
mkdir -p -m 777 ${user}/{pipes,files}
pipe=${user}/pipes/${uuid}
rm -f ${pipe}
mkfifo ${pipe}
