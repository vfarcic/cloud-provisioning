#!/usr/bin/env bash

docker network create --driver overlay proxy

docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    --reserve-memory 10m \
    --network proxy \
    --replicas 3 \
    -e MODE=swarm \
    -e LISTENER_ADDRESS=swarm-listener \
    vfarcic/docker-flow-proxy

docker service create --name swarm-listener \
    --network proxy \
    --reserve-memory 10m \
    --mount "type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock" \
    -e DF_NOTIF_CREATE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/reconfigure \
    -e DF_NOTIF_REMOVE_SERVICE_URL=http://proxy:8080/v1/docker-flow-proxy/remove \
    --constraint 'node.role==manager' \
    vfarcic/docker-flow-swarm-listener

docker service create --name jenkins \
    -e JENKINS_OPTS="--prefix=/jenkins" \
    --mount "type=volume,source=jenkins,target=/var/jenkins_home,volume-driver=rexray" \
    --label com.df.notify=true \
    --label com.df.distribute=true \
    --label com.df.servicePath=/jenkins \
    --label com.df.port=8080 \
    --network proxy \
    --reserve-memory 300m \
    jenkins:2.7.4-alpine

echo ""
echo ">> The scheduled services will be up-and-running soon"
