provider "aws" {
  region     = "ap-south-1"
  access_key = "put your access key here"
  secret_key = "put your secret key here"
}
# Create a VPC
resource "aws_vpc" "kube_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "kube_vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "kube_subnet" {
  vpc_id                  = aws_vpc.kube_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"
  tags = {
    Name = "kube_subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "kube_igw" {
  vpc_id = aws_vpc.kube_vpc.id
  tags = {
    Name = "kube_igw"
  }
}

# Create a Route Table
resource "aws_route_table" "kube_rt" {
  vpc_id = aws_vpc.kube_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kube_igw.id
  }
  tags = {
    Name = "kube_rt"
  }
}

# Associate the Subnet with the Route Table
resource "aws_route_table_association" "kube_rt_association" {
  subnet_id      = aws_subnet.kube_subnet.id
  route_table_id = aws_route_table.kube_rt.id
}

# Create a Security Group
resource "aws_security_group" "kube_sg" {
  name        = "kube_sg"
  description = "Allow SSH and HTTP traffic"
  vpc_id      = aws_vpc.kube_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kube_sg"
  }
}

# Create the Master Node
resource "aws_instance" "kube_master" {
  ami                    = "ami-0614680123427b75e"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.kube_subnet.id
  vpc_security_group_ids = [aws_security_group.kube_sg.id]
  
  # Pass the Bash script to the instance using user_data
  

  tags = {
    Name = "kube_master"
  }
}

# Create the Worker Node
resource "aws_instance" "kube_worker" {
  ami                    = "ami-0614680123427b75e"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.kube_subnet.id
  vpc_security_group_ids = [aws_security_group.kube_sg.id]

  # Pass the Bash script to the instance using user_data
  user_data = file("${path.module}/script.sh")

  tags = {
    Name = "kube_worker"
  }
  
}
