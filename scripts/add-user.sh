#!/usr/bin/env bash

user=$1

mkdir -p ${user}/{etc,pipes,files,tmp}
chmod a+w ${user}/{files,pipes}
