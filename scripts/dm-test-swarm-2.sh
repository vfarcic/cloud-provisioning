#!/usr/bin/env bash

if [[ "$(uname -s )" == "Linux" ]]; then
  export VIRTUALBOX_SHARE_FOLDER="$PWD:$PWD"
fi

for i in 1 2 3; do
    docker-machine create \
        -d virtualbox \
        --virtualbox-memory 512 \
        swarm-test-$i
done

eval $(docker-machine env swarm-test-1)

docker swarm init \
    --advertise-addr $(docker-machine ip swarm-test-1)

docker node update \
    --label-add env=jenkins-agent \
    swarm-test-1

TOKEN=$(docker swarm join-token -q manager)

for i in 2 3; do
    eval $(docker-machine env swarm-test-$i)

    docker swarm join \
        --token $TOKEN \
        --advertise-addr $(docker-machine ip swarm-test-$i) \
        $(docker-machine ip swarm-test-1):2377

    docker node update \
        --label-add env=prod-like \
        swarm-test-$i
done

echo ">> The swarm test cluster is up and running"
