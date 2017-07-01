#!/usr/bin/env bash
ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'