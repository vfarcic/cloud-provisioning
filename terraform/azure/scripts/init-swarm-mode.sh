#!/usr/bin/env bash
IP=$(/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}')
docker swarm init --advertise-addr $IP
