#!/bin/bash

# Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo yum update -y
sudo yum install -y amazon-linux-extras curl vim wget

# Install and enable Docker
echo "Installing and enabling Docker..."
sudo amazon-linux-extras enable docker
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker

# Enable IP forwarding (required for Kubernetes networking)
echo "Enabling IP forwarding..."
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Configure containerd
echo "Configuring containerd..."
sudo yum install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
sudo systemctl restart containerd

# Add Kubernetes repository
echo "Adding Kubernetes repository..."
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
EOF

# Install Kubernetes components
echo "Installing Kubernetes components..."
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Disable swap (required by Kubernetes)
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Enable and start kubelet
echo "Enabling and starting kubelet..."
sudo systemctl enable kubelet
sudo systemctl start kubelet


