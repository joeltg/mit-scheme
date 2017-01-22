#!/usr/bin/env bash

user=$1
uuid=$2

exec schroot -c scheme -d /files -o user.path=${user} -- /bin/bash /bin/start /pipes/${uuid}
