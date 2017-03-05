#!/usr/bin/env bash

if [[ "$(uname -s )" == "Linux" ]]; then
  export VIRTUALBOX_SHARE_FOLDER="$PWD:$PWD"
fi

for i in {1..5}; do
    docker-machine create \
        -d virtualbox \
        swarm-$i
done

eval $(docker-machine env swarm-1)

docker swarm init \
  --advertise-addr $(docker-machine ip swarm-1)

TOKEN_MANAGER=$(docker swarm join-token -q manager)

TOKEN_WORKER=$(docker swarm join-token -q worker)

for i in 2 3; do
    eval $(docker-machine env swarm-$i)

    docker swarm join \
        --token $TOKEN_MANAGER \
        --advertise-addr $(docker-machine ip swarm-$i) \
        $(docker-machine ip swarm-1):2377
done

for i in 4 5; do
    eval $(docker-machine env swarm-$i)

    docker swarm join \
        --token $TOKEN_WORKER \
        --advertise-addr $(docker-machine ip swarm-$i) \
        $(docker-machine ip swarm-1):2377
done

for i in {1..5}; do
    eval $(docker-machine env swarm-1)

    docker node update \
        --label-add env=prod \
        swarm-$i
done

echo ""
echo ">> The swarm cluster is up and running"
