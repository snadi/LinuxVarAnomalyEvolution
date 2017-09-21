#!/bin/zsh

for i in {20..38}
do
local version=v2.6.$i ; printf "%s %s " $version $version ; git show --date=short $version | grep '^Date' | head -n 1 | awk '{print $2}' | awk -F'-' '{print $2"/"$3"/"$1}'
done
