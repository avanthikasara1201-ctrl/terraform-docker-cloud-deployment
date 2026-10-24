
resource "aws_security_group" "ec2" {
  name        = "myterraform-ec2-sg"
  description = "Security group for myterraform EC2"
  vpc_id      = var.vpc_id

  # Allow SSH from your IP only
  ingress {
    description = "SSH from my IP only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["157.51.117.46/32"]
  }

  # Allow HTTP website traffic
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic
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

# Find the latest Amazon Linux 2023 AMI
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

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  associate_public_ip_address = true
  key_name                    = "myterraform-key"

  # Install Docker and launch an Nginx website automatically
  user_data = <<-EOF
    #!/bin/bash
    dnf update -y
    dnf install -y docker
    systemctl enable --now docker
    docker run -d --name myterraform-web -p 80:80 --restart unless-stopped nginx:latest
  EOF

  tags = {
    Name = "myterraform-web-server"
  }
}
