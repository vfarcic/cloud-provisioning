#!/usr/bin/env bash

if [ ! -f /data/jenkins/jenkins.install.InstallUtil.lastExecVersion ];
then
  while [ ! -f /data/jenkins/secrets/initialAdminPassword ]; do
      sleep 2
  done
  echo \">> Please use the password that follows.\"
  cat /data/jenkins/secrets/initialAdminPassword
fi