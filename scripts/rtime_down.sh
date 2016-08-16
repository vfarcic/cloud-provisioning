#!/usr/bin/env bash

SERVICE=$1
MAX_MILLIS_WARN=$2
MAX_MILLIS_ERR=$3

RTIME=$(curl http://{{ elk_ip }}:9200/logstash-*/_search -d "
{
    \"size\" : 0,
    \"query\": {
        \"bool\": {
            \"must\": { \"match\": { \"tags\" : \"haproxy_stats\" } },
            \"must\": { \"match\": { \"haproxy_stats.svname\" : \"BACKEND\" } },
            \"must\": { \"match\": { \"haproxy_stats.pxname.raw\" : \"${SERVICE}-be\" } },
            \"must\": { \"range\": { \"@timestamp\": { \"gt\" : \"now-1h\" } } }
        }
    },
    \"aggs\" : {
        \"avg_rtime\" : {
            \"avg\": { \"field\": \"haproxy_stats.rtime\" }
        }
    }
}" | jq '.aggregations.avg_rtime.value')

RTIME=$(printf "%.0f" $RTIME)

if [ $RTIME -lt $MAX_MILLIS_ERR ]; then
  exit 2
elif [ $RTIME -lt $MAX_MILLIS_WARN ]; then
  exit 1
else
  exit 0
fi
