terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.env_prefix}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env_prefix}-igw"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnet_cidr_block
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_prefix}-subnet"
  }
}

# Route Table
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.env_prefix}-rt"
  }
}

# Route Table Association
resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

# Security Group
resource "aws_security_group" "main" {
  name        = "${var.env_prefix}-sg"
  description = "Security group for lab project"
  vpc_id      = aws_vpc.main.id

  # SSH from your IP only
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.my_ip]
    description = "SSH from my IP"
  }

  # HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from anywhere"
  }

  # Allow all traffic within VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "All traffic within VPC"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.env_prefix}-sg"
  }
}

# SSH Key Pair
resource "aws_key_pair" "main" {
  key_name   = "${var.env_prefix}-key"
  public_key = file(pathexpand(var.public_key_path))
}

# Frontend EC2 Instance
resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name

  tags = {
    Name = "${var.env_prefix}-frontend"
    Role = "frontend"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Instance ready'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(pathexpand(var.private_key_path))
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}

# Backend EC2 Instances
resource "aws_instance" "backend" {
  count                  = 3
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
  key_name               = aws_key_pair.main.key_name

  tags = {
    Name = "${var.env_prefix}-backend-${count.index}"
    Role = "backend"
  }

  provisioner "remote-exec" {
    inline = ["echo 'Instance ready'"]

    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(pathexpand(var.private_key_path))
      host        = self.public_ip
      timeout     = "5m"
    }
  }
}

# Generate Ansible Inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory_template.tpl", {
    frontend_ip          = aws_instance.frontend.public_ip
    backend_0_ip         = aws_instance.backend[0].public_ip
    backend_1_ip         = aws_instance.backend[1].public_ip
    backend_2_ip         = aws_instance.backend[2].public_ip
    backend_0_private_ip = aws_instance.backend[0].private_ip
    backend_1_private_ip = aws_instance.backend[1].private_ip
    backend_2_private_ip = aws_instance.backend[2].private_ip
    private_key_path     = pathexpand(var.private_key_path)
  })
  filename = "${path.module}/generated_hosts.ini"
}

# Ansible Configuration Automation
resource "null_resource" "ansible_config" {
  triggers = {
    frontend_ip = aws_instance.frontend.public_ip
    backend_ips = join(",", [for b in aws_instance.backend : b.public_ip])
  }

  depends_on = [
    aws_instance.frontend,
    aws_instance.backend,
    local_file.ansible_inventory
  ]

  provisioner "local-exec" {
    command = <<-EOT
      echo "Waiting for instances to be fully ready..."
      sleep 60
      ANSIBLE_CONFIG=ansible/ansible.cfg ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i generated_hosts.ini \
        ansible/playbooks/site.yaml
    EOT
  }
}
