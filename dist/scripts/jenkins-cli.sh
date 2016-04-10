#!/usr/bin/env bash

if [[ ! -f /opt/jenkins/jenkins-cli.jar ]]; then
  tmpDir="$(mktemp -d)"
  sudo mkdir /opt/jenkins
  curl -s -o ${tmpDir}/jenkins-cli.jar http://app:8080/jnlpJars/jenkins-cli.jar
  sudo mv ${tmpDir}/jenkins-cli.jar /opt/jenkins
  rm -rf ${tmpDir}
fi

java -jar /opt/jenkins/jenkins-cli.jar -s http://app:8080 $@