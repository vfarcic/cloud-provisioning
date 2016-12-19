#!/usr/bin/env bash

for rs in "$@"; do
    mongo --host $rs --eval 'db'
    while [ $? -ne 0 ]; do
        echo "Waiting for $rs to become available"
        sleep 3
        mongo --host $rs --eval 'db'
    done
done

for rs in "$@"; do
    if [ "$rs" != "$1" ]; then
        MEMBERS="$MEMBERS ,"
    fi
    MEMBERS="$MEMBERS {_id: 0, host: \"$rs\" }"
done

mongo --host go-demo-db-rs1 --eval "rs.initiate({_id: "rs0", version: 1, members: [$MEMBERS]})"