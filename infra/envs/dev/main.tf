locals {
  name = "${var.project}-${var.env}"
  tags = {
    Project = var.project
    Env     = var.env
    Owner   = "yourname"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = var.cidr_block

  azs             = ["us-east-2a", "us-east-2b"]
  public_subnets  = ["10.10.0.0/24", "10.10.1.0/24"]
  private_subnets = ["10.10.10.0/24", "10.10.11.0/24"]

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = local.tags
}

resource "aws_security_group" "web" {
  name        = "${local.name}-web-sg"
  description = "Allow HTTP/SSH"
  vpc_id      = module.vpc.vpc_id

  ingress { from_port = 22 to_port = 22 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 80 to_port = 80 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  egress  { from_port = 0  to_port = 0  protocol = "-1" cidr_blocks = ["0.0.0.0/0"] }

  tags = local.tags
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter { name = "name" values = ["al2023-ami-*-x86_64"] }
}

resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = <<-EOF
                #!/bin/bash
                dnf install -y httpd
                systemctl enable --now httpd
                echo "Hello from ${local.name}" > /var/www/html/index.html
              EOF
  tags = merge(local.tags, { Name = "${local.name}-web" })
}

output "web_public_ip" {
  value = aws_instance.web.public_ip
}
