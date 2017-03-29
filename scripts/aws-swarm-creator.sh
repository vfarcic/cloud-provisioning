#!/usr/bin/env bash

echo "Creating Docker Swarm Environment on AWS"

echo "Checking if AWS ENV variables are set"
[ -z "$AWS_ACCESS_KEY_ID" ] && echo "Need to set AWS_ACCESS_KEY_ID" && exit 1;
[ -z "$AWS_SECRET_ACCESS_KEY" ] && echo "Need to set AWS_SECRET_ACCESS_KEY" && exit 1;
[ -z "$AWS_DEFAULT_REGION" ] && echo "Need to set AWS_DEFAULT_REGION" && exit 1;

echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: Not showing you that!"
echo "AWS_DEFAULT_REGION: $AWS_DEFAULT_REGION"
echo "Checking if AWS CLI is installed"
command -v aws >/dev/null 2>&1 || { echo >&2 "I require aws but it's not installed.  Aborting."; exit 1; }
echo "IAM Get User"
aws iam get-user
echo "Checking the availability zones in $AWS_DEFAULT_REGION"
AWS_ZONES=($(aws ec2 describe-availability-zones | jq -r ".AvailabilityZones[] | .ZoneName"))
echo ${AWS_ZONES[@]}
NUMBER_OF_ZONES=${#AWS_ZONES[@]}
echo "Enter a swarm name:"
read SWARM_NAME
echo "How many manager nodes? (an odd number): "
read NUMBER_OF_MANAGERS
echo "How many worker nodes?"
read NUMBER_OF_WORKERS
TOTAL_NUMBER_OF_NODES=$(($NUMBER_OF_MANAGERS + $NUMBER_OF_WORKERS))

NODE_NUMBER=1
while [ $NODE_NUMBER -le $NUMBER_OF_MANAGERS ]; do
    ZONE_INDEX=$(($(($NODE_NUMBER-1))%$NUMBER_OF_ZONES))
    ZONE=${AWS_ZONES[$ZONE_INDEX]: -1: 1}
    NODE_NAME="$SWARM_NAME-$NODE_NUMBER"
    echo "Creating manager: $NODE_NAME on zone:$ZONE of $NUMBER_OF_ZONES zones in $AWS_DEFAULT_REGION"
    docker-machine create \
        --driver amazonec2 \
        --amazonec2-zone $ZONE \
        --amazonec2-tags "Type,manager" \
        --amazonec2-security-group $SWARM_NAME \
        $NODE_NAME
    let NODE_NUMBER=NODE_NUMBER+1
done

while [ $NODE_NUMBER -le $TOTAL_NUMBER_OF_NODES ]; do
    ZONE_INDEX=$(($(($NODE_NUMBER-1))%$NUMBER_OF_ZONES))
    ZONE=${AWS_ZONES[$ZONE_INDEX]: -1: 1}
    NODE_NAME="$SWARM_NAME-$NODE_NUMBER"
    echo "Creating worker: $NODE_NAME on zone:$ZONE of $NUMBER_OF_ZONES zones in $AWS_DEFAULT_REGION"
    docker-machine create \
        --driver amazonec2 \
        --amazonec2-zone $ZONE \
        --amazonec2-tags "Type,worker" \
        --amazonec2-security-group $SWARM_NAME \
        $NODE_NAME
    let NODE_NUMBER=NODE_NUMBER+1
done

LEADER_IP=$(aws ec2 describe-instances \
    --filter "Name=tag:Name,Values=$SWARM_NAME-1" \
    "Name=instance-state-name,Values=running" \
    | jq -r ".Reservations[0].Instances[0].PrivateIpAddress")
echo "LEADER_IP: $LEADER_IP"
eval $(docker-machine env $SWARM_NAME-1)
docker swarm init --advertise-addr $LEADER_IP
SECURITY_GROUP_ID=$(aws ec2 describe-security-groups \
    --filter "Name=group-name,Values=$SWARM_NAME" | \
    jq -r '.SecurityGroups[0].GroupId')
echo "SECURITY_GROUP_ID: $SECURITY_GROUP_ID"
echo "Open TCP ingress ports on 2377 7946 and 4789"
for p in 2377 7946 4789; do
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID \
        --protocol tcp \
        --port $p \
        --source-group $SECURITY_GROUP_ID
done
echo "Open UDP ingress ports on 7946 and 4789"
for p in 7946 4789; do
    aws ec2 authorize-security-group-ingress --group-id $SECURITY_GROUP_ID \
        --protocol udp \
        --port $p \
        --source-group $SECURITY_GROUP_ID
done
MANAGER_TOKEN=$(docker swarm join-token -q manager)
echo "MANAGER_TOKEN: $MANAGER_TOKEN"
WORKER_TOKEN=$(docker swarm join-token -q worker)
echo "WORKER_TOKEN: $WORKER_TOKEN"

NODE_NUMBER=2
while [ $NODE_NUMBER -le $NUMBER_OF_MANAGERS ]; do
    NODE_NAME="$SWARM_NAME-$NODE_NUMBER"
    IP=$(aws ec2 describe-instances \
        --filter "Name=tag:Name,Values=$SWARM_NAME" \
        "Name=instance-state-name,Values=running" \
        | jq -r ".Reservations[0].Instances[0].PrivateIpAddress")
    echo "IP for $NODE_NAME: $IP"
    eval $(docker-machine env $NODE_NAME)

    docker swarm join \
        --token $MANAGER_TOKEN \
        --advertise-addr $IP \
        $LEADER_IP:2377

    let NODE_NUMBER=NODE_NUMBER+1
done

while [ $NODE_NUMBER -le $TOTAL_NUMBER_OF_NODES ]; do
    NODE_NAME="$SWARM_NAME-$NODE_NUMBER"
    IP=$(aws ec2 describe-instances \
        --filter "Name=tag:Name,Values=$SWARM_NAME" \
        "Name=instance-state-name,Values=running" \
        | jq -r ".Reservations[0].Instances[0].PrivateIpAddress")
    echo "IP for $NODE_NAME: $IP"
    eval $(docker-machine env $NODE_NAME)

    docker swarm join \
        --token $WORKER_TOKEN \
        --advertise-addr $IP \
        $LEADER_IP:2377

    let NODE_NUMBER=NODE_NUMBER+1
done

eval $(docker-machine env $SWARM_NAME-1)
docker node ls