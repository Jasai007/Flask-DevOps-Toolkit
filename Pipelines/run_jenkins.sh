#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker could not be found. Please install Docker first."
    exit 1
fi

# Run a Jenkins container in detached mode
docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  --restart=on-failure \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts