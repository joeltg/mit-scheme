#!/usr/bin/env bash

user=$1
uuid=$2
libs=$3

exec schroot -c scheme -d / -o user.path=${user} -- /bin/bash /bin/start /pipes/${uuid} ${libs}
