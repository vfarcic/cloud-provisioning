#!/usr/bin/env bash

for rs in "$@"; do
    mongo --host $rs --eval 'db'
    while [ $? -ne 0 ]; do
        echo "Waiting for $rs to become available"
        sleep 3
        mongo --host $rs --eval 'db'
    done
done

i=0
for rs in "$@"; do
    if [ "$rs" != "$1" ]; then
        MEMBERS="$MEMBERS ,"
    fi
    MEMBERS="$MEMBERS {_id: $i, host: \"$rs\" }"
    i=$((i+1))
done

mongo --host $1 --eval "rs.initiate({_id: \"rs0\", version: 1, members: [$MEMBERS]})"
sleep 3
mongo --host $1 --eval 'rs.status()'