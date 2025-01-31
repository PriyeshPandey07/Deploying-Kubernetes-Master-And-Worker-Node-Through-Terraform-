#!/bin/bash

# Update system and install dependencies
echo "Updating system and installing dependencies..."
sudo yum update -y
sudo yum install -y amazon-linux-extras curl vim wget httpd firewalld

# Start and enable HTTPD (optional service setup)
echo "Starting and enabling HTTPD..."
sudo systemctl start httpd
sudo systemctl enable httpd

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

# Install and configure containerd
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

# Update system and install Kubernetes components
echo "Updating system and installing Kubernetes components..."
sudo yum update -y
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

# Disable swap (required by Kubernetes)
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Enable and start kubelet
echo "Enabling and starting kubelet..."
sudo systemctl enable kubelet
sudo systemctl start kubelet

# Install Flannel CNI plugin for pod networking
echo "Installing Flannel CNI plugin..."
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
# Output the join command for worker nodesif [ $? -eq 0 ]; then
    echo "Setting up kubeconfig for kubectl..."
    mkdir -p ~/.kube
    sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    
    echo "Applying Flannel CNI plugin..."
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

    echo "Kubernetes master node initialized successfully!"
else
    echo "Kubernetes master node initialization failed."
    exit 1
fi

# Check node status
echo "Checking Kubernetes node status..."
kubectl get nodes

# Firewalld setup
echo "Installing and configuring firewalld..."
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="0.0.0.0/0" accept'
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv6" source address="::/0" accept'
sudo firewall-cmd --runtime-to-permanent
sudo firewall-cmd --list-all

echo -e "\nFor AWS: Update Security Groups to allow All traffic (Type: All, Port: 0-65535)."


echo "To join worker nodes to the cluster, run the following command on each worker node:"
kubeadm token create --print-join-command
