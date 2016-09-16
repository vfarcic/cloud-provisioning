#!/usr/bin/env bash

eval $(docker-machine env swarm-test-1)

docker network create --driver overlay proxy

docker network create --driver overlay go-demo

docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    -p 8080:8080 \
    --network proxy \
    -e MODE=swarm \
    --replicas 3 \
    -e CONSUL_ADDRESS="$(docker-machine ip swarm-1):8500,$(docker-machine ip swarm-3):8500,$(docker-machine ip swarm-3):8500" \
    vfarcic/docker-flow-proxy

docker service create --name go-demo-db \
    --network go-demo \
    mongo

docker service create --name go-demo \
    -e DB=go-demo-db \
    --network go-demo \
    --network proxy \
    vfarcic/go-demo