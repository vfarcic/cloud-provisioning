#!/usr/bin/env bash

eval $(docker-machine env swarm-1)

docker network create --driver overlay proxy

docker network create --driver overlay go-demo

curl -o docker-compose-proxy.yml \
    https://raw.githubusercontent.com/\
vfarcic/docker-flow-proxy/master/docker-compose.yml

export DOCKER_IP=$(docker-machine ip swarm-1)

docker-compose -f docker-compose-proxy.yml \
    up -d consul-server

export CONSUL_SERVER_IP=$(docker-machine ip swarm-1)

for i in 2 3; do
    eval $(docker-machine env swarm-$i)

    export DOCKER_IP=$(docker-machine ip swarm-$i)

    docker-compose -f docker-compose-proxy.yml \
        up -d consul-agent
done

rm docker-compose-proxy.yml

docker service create --name proxy \
    -p 80:80 \
    -p 443:443 \
    -p 8090:8080 \
    --network proxy \
    -e MODE=swarm \
    --replicas 3 \
    -e CONSUL_ADDRESS="$(docker-machine ip swarm-1):8500,$(docker-machine ip swarm-2):8500,$(docker-machine ip swarm-3):8500" \
    --reserve-memory 50m \
    vfarcic/docker-flow-proxy

docker service create --name go-demo-db \
    --network go-demo \
    --reserve-memory 150m \
    mongo:3.2.10

while true; do
    REPLICAS=$(docker service ls | grep proxy | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep proxy | awk '{print $4}')
    if [[ $REPLICAS == "3/3" || $REPLICAS_NEW == "3/3" ]]; then
        break
    else
        echo "Waiting for the proxy service..."
        sleep 10
    fi
done

while true; do
    REPLICAS=$(docker service ls | grep go-demo-db | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep go-demo-db | awk '{print $4}')
    if [[ $REPLICAS == "1/1" || $REPLICAS_NEW == "1/1" ]]; then
        break
    else
        echo "Waiting for the go-demo-db service..."
        sleep 10
    fi
done

docker service create --name go-demo \
    -e DB=go-demo-db \
    --network go-demo \
    --network proxy \
    --replicas 3 \
    --reserve-memory 50m \
    --update-delay 5s \
    vfarcic/go-demo:1.0

while true; do
    REPLICAS=$(docker service ls | grep vfarcic/go-demo | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep vfarcic/go-demo | awk '{print $4}')
    if [[ $REPLICAS == "3/3" || $REPLICAS_NEW == "3/3" ]]; then
        break
    else
        echo "Waiting for the go-demo-db service..."
        sleep 10
    fi
done

curl "$(docker-machine ip swarm-1):8090/v1/docker-flow-proxy/reconfigure?serviceName=go-demo&servicePath=/demo&port=8080&distribute=true"

echo ""
echo ">> The services are up and running inside the swarm cluster"
