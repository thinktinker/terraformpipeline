terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
# Set in pipeline.yml

# Configure the AWS Instance
resource "aws_instance" "MartinTfWebServer" {
  ami                         = "ami-0f34c5ae932e6f0e4" # Amazon Linux 2 LTS
  instance_type               = "t2.micro"
  count                       = 2                                                           # number of AWS instances
  key_name                    = aws_key_pair.martinterraformkeypair.key_name                # for SSH connection with a new keypair created below
  subnet_id                   = "subnet-012fda4fc806b7308"                                  # points to the subnet from the used VPC                                       
  vpc_security_group_ids      = [aws_security_group.martin_allow_ssh_icmp_https_traffic.id] # Points to the security group below
  associate_public_ip_address = true

  user_data = <<-EOF
      #!/bin/bash
      sudo yum update -y
      sudo yum install pip -y
      sudo python3 -m pip install --user ansible
    EOF

  tags = {
    Name = "Martin TF Web Server ${count.index + 1}"
  }
}

# Configure the S3 instance
terraform {
  backend "s3" {
    bucket = "martins3terraform" # this bucket has to be created first
    key    = "s3terraformkey"    # this is where the terraform state is written to
    region = "us-east-1"
  }
}

# Configure the keypair resource
# Below resources will create a key pair to your local computer on the same path as your terraform folder
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "martinterraformkeypair" {
  key_name   = "martinterraformkeypair-us-east-1-keypair" # this creates a key pair on AWS (you don't have to do it on AWS console)
  public_key = tls_private_key.private_key.public_key_openssh

  provisioner "local-exec" { # Downloads the keypair: martinterraformkeypair-us-east-1-keypair
    command = "echo '${tls_private_key.private_key.private_key_pem}' > ./martinterraformkeypair-us-east-1-keypair"
  }
}

# Configure the security group
# Below resources matches the security group policy required for security group set up
resource "aws_security_group" "martin_allow_ssh_icmp_https_traffic" {
  name        = "martin_allow_ssh_icmp_https_traffic"
  description = "Allow inbound traffic for ssh, icmp and https"
  vpc_id      = "vpc-0ef68c37cb73605a7" # The VPC used for this exercise is working

  ingress { # inward bound traffic via ssh
    description = "SSH inbound"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 1. use descript-security-group to see existing references: https://blog.jwr.io/terraform/icmp/ping/security/groups/2018/02/02/terraform-icmp-rules.html
  # 2. https://docs.aws.amazon.com/cli/latest/userguide/cli-services-ec2-sg.html
  ingress { # inward bound traffic via icmp 
    description = "ICMP inbound"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress { # inward bound traffic via https
    description = "HTTPS inbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress { # outward bound traffic
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow tls"
  }

}
