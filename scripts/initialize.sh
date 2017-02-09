#!/usr/bin/env bash

user=$1
uuid=$2
band=$3

mkdir -p -m 777 ${user}/{etc,pipes,files,tmp}
pipe=${user}/pipes/${uuid}
rm -f ${pipe}
mkfifo ${pipe}
