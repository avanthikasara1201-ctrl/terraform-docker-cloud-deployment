
resource "aws_security_group" "ec2" {
  name        = "myterraform-ec2-sg"
  description = "Security group for myterraform EC2"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["152.57.86.122/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "myterraform-ec2-sg"
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  associate_public_ip_address = true
  key_name                    = "myterraform-key"

  iam_instance_profile = var.instance_profile_name

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    dnf install -y docker awscli
    systemctl enable --now docker

    aws ecr get-login-password --region us-west-1 \
      | docker login --username AWS --password-stdin 075810104101.dkr.ecr.us-west-1.amazonaws.com

    docker pull 075810104101.dkr.ecr.us-west-1.amazonaws.com/my-cloud-website:latest

    docker run -d \
      --name myterraform-web \
      -p 80:80 \
      --restart unless-stopped \
      075810104101.dkr.ecr.us-west-1.amazonaws.com/my-cloud-website:latest
  EOF

  tags = {
    Name = "myterraform-web-server"
  }
}
