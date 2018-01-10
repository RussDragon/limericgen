#!/usr/bin/env sh
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

cd $(dirname $0)
t update "$(lua limerickgen.lua 1)"
