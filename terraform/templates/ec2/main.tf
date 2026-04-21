# Required Provider Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# AWS Provider
provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu_linux_os" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_ami" "windows_server_os" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "server" {
  count                  = var.instance_count
  ami                    = var.ami_id != null ? var.ami_id : (var.os_type == "windows" ? data.aws_ami.windows_server_os.id : data.aws_ami.ubuntu_linux_os.id)
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.sec_grp_ids
  key_name               = var.key_name
  iam_instance_profile   = var.iam_profile

  root_block_device {
    volume_type           = var.root_vol_type
    volume_size           = var.root_vol_size
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name        = var.instance_name
    Environment = var.environment
    Owner       = var.owner
    Project     = var.project
  }
}
