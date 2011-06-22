#!/bin/bash

out_msg=${1:-out}
err_msg=${2:-}
repeats=${3:-10}
exit_status=${4:-0}

n=0
while [ "$n" -lt "$repeats" ]
do
  if [ -n "$out_msg" ]
  then
    echo "$out_msg $n"
  fi
  if [ -n "$err_msg" ]
  then
    echo >&2 "$err_msg $n"
  fi
  n=$[$n + 1]
done

exit "$exit_status"
