#!/bin/sh
#   Use this script to test if a given TCP host/port are available

# The MIT License (MIT)
# Copyright (c) 2016 Vance Lucas
# https://github.com/vishnubob/wait-for-it

set -e

host="$1"
shift
port="$1"
shift
cmd="$@"

wait_for() {
  for i in $(seq 1 30); do
    nc -z "$host" "$port" >/dev/null 2>&1 && return 0
    echo "Waiting for $host:$port..."
    sleep 1
  done
  return 1
}

wait_for

echo "$host:$port is available - executing command"
exec $cmd
