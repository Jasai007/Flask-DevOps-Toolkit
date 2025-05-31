#!/bin/bash

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    echo "Docker is not installed. Installing Docker using yum..."
    # Install Docker using yum
    sudo yum update -y
    sudo yum install -y docker
    echo "Docker installed successfully."
    # Start and enable Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    # Add current user to docker group for root privileges
    sudo usermod -aG docker $USER
    echo "Added $USER to docker group. You may need to log out and log back in for group changes to take effect."
fi

# Ensure Docker is running
sudo systemctl start docker

# Run a Jenkins container in detached mode
sudo docker run -d --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  --restart=on-failure \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts