#!/usr/bin/env bash

eval $(docker-machine env swarm-test-1)

docker network create --driver overlay proxy

docker network create --driver overlay go-demo

curl -o docker-compose-proxy.yml \
    https://raw.githubusercontent.com/\
vfarcic/docker-flow-proxy/master/docker-compose.yml

export DOCKER_IP=$(docker-machine ip swarm-test-1)

docker-compose -f docker-compose-proxy.yml \
    up -d consul-server

export CONSUL_SERVER_IP=$(docker-machine ip swarm-1)

for i in 2 3; do
    eval $(docker-machine env swarm-test-$i)

    export DOCKER_IP=$(docker-machine ip swarm-test-$i)

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
    --replicas 2 \
    -e CONSUL_ADDRESS="$(docker-machine ip swarm-test-1):8500,$(docker-machine ip swarm-test-2):8500,$(docker-machine ip swarm-test-3):8500" \
    --constraint 'node.labels.env == prod-like' \
    vfarcic/docker-flow-proxy

docker service create --name go-demo-db \
    --network go-demo \
    --constraint 'node.labels.env == prod-like' \
    mongo:3.2.10

while true; do
    REPLICAS=$(docker service ls | grep proxy | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep proxy | awk '{print $4}')
    if [[ $REPLICAS == "2/2" || $REPLICAS_NEW == "2/2" ]]; then
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
    --replicas 2 \
    --constraint 'node.labels.env == prod-like' \
    --update-delay 5s \
    vfarcic/go-demo:1.0

while true; do
    REPLICAS=$(docker service ls | grep vfarcic/go-demo | awk '{print $3}')
    REPLICAS_NEW=$(docker service ls | grep vfarcic/go-demo | awk '{print $4}')
    if [[ $REPLICAS == "2/2" || $REPLICAS_NEW == "2/2" ]]; then
        break
    else
        echo "Waiting for the go-demo-db service..."
        sleep 10
    fi
done

curl "$(docker-machine ip swarm-test-1):8090/v1/docker-flow-proxy/reconfigure?serviceName=go-demo&servicePath=/demo&port=8080&distribute=true"

echo ""
echo ">> The services are up and running inside the swarm test cluster"
