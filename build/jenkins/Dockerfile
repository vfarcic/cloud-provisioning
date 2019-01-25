FROM jenkins/jenkins:2.161-alpine

ENV JENKINS_OPTS --prefix=/jenkins

COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY plugins.txt /usr/share/jenkins/ref/

