#!/usr/bin/env bash

user=$1
uuid=$2
libs=$3

pipe=${user}/pipes/${uuid}

rm -f ${pipe}
mkfifo ${pipe}
