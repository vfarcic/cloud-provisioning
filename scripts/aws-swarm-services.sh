#!/usr/bin/env bash

eval $(docker-machine env swarm-1)

docker network create --driver overlay proxy

docker network create --driver overlay go-demo

docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --network proxy \
    --replicas 3 \
    -e MODE=swarm \
    vfarcic/docker-flow-proxy

docker service create --name swarm-listener \
    --network proxy \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIF_CREATE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    -e DF_NOTIF_REMOVE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/remove \
    --constraint 'node.role==manager' \
    vfarcic/docker-flow-swarm-listener

docker service create --name go-demo-db \
    --network go-demo \
    mongo:3.2.10

docker service create --name go-demo \
    -e DB=go-demo-db \
    --network go-demo \
    --network proxy \
    --replicas 3 \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/demo \
    --label com.df.port=8080 \
    vfarcic/go-demo:1.2

docker service create --name util \
    --network proxy \
    --mode global \
    alpine sleep 1000000000

echo ""
echo ">> The services scheduled and will be up-and-running soon"
