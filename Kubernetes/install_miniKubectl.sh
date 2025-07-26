#!/bin/bash

# Download the latest Minikube RPM package
echo "Downloading the latest Minikube RPM package..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm

# Install Minikube using rpm
echo "Installing Minikube..."
sudo rpm -Uvh minikube-latest.x86_64.rpm

# Start Minikube (force start)
echo "Starting Minikube (force start)..."
minikube start --force

# Download kubectl binary for Amazon EKS (1.33.0)
echo "Downloading kubectl binary for Amazon EKS (1.33.0)..."
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.0/2025-05-01/bin/linux/amd64/kubectl

# Make kubectl executable
echo "Making kubectl executable..."
chmod +x kubectl

# Move kubectl to /usr/local/bin for global access
echo "Moving kubectl to /usr/local/bin for global access..."
sudo mv kubectl /usr/local/bin/

# Verify Minikube installation
echo "Verifying Minikube installation..."
minikube version

# Verify kubectl installation
echo "Verifying kubectl installation..."
kubectl version --client