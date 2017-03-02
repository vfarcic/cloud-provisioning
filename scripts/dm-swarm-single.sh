#!/usr/bin/env bash

docker-machine create \
    -d virtualbox \
    swarm

eval $(docker-machine env swarm)

docker swarm init \
  --advertise-addr $(docker-machine ip swarm)

echo ">> The swarm cluster is up and running"
