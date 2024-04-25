#!/bin/bash
cd $(dirname $0)

kv_list=$(cat ../env.yaml \
  | grep -v -e '^\s*#' -e '^\s*$' \
  | tr -d " " \
  | awk -F: '{print $1"="$2}')

for kv in $kv_list; do
  echo "export $kv"
  eval "export $kv"
done

