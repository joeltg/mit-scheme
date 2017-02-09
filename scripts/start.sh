#!/usr/bin/env bash

user=$1
uuid=$2
band=$3

exec schroot -c mit-scheme -d /files -o user.path=${user} -- /bin/bash /bin/start /pipes/${uuid} ${band}
