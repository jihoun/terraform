terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }
}

# Interface VPC endpoint for execute-api (API Gateway PrivateLink) plus a small EC2
# NAT instance with default routes from app subnets for internet-only endpoints
# (e.g. Cognito OAuth hostnames). See module README / repository index.

data "aws_region" "current" {}

resource "aws_security_group" "execute_api_endpoint" {
  name        = "${var.name_prefix}-vpce-execute-api"
  description = "Allow HTTPS from app to execute-api VPC endpoint"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-vpce-execute-api" })

  ingress {
    description     = "HTTPS from app (backend, CRM Lambdas)"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.app_security_group_ids
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "execute_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.execute-api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = var.app_subnet_ids
  security_group_ids  = [aws_security_group.execute_api_endpoint.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name_prefix}-vpce-execute-api" })
}

data "aws_ami" "nat" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "nat" {
  name        = "${var.name_prefix}-nat-instance"
  description = "Allow traffic from private subnets for NAT"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${var.name_prefix}-nat-instance" })

  ingress {
    description = "From VPC (private subnets)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "nat" {
  ami                    = data.aws_ami.nat.id
  instance_type          = var.nat_instance_type
  subnet_id              = var.nat_public_subnet_id
  vpc_security_group_ids = [aws_security_group.nat.id]
  source_dest_check      = false

  user_data = <<-EOT
    #!/bin/bash
    set -e
    yum install -y iptables-services
    sysctl -w net.ipv4.ip_forward=1
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-nat.conf
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    iptables -A FORWARD -j ACCEPT
    service iptables save
    systemctl enable iptables
  EOT

  tags = merge(var.tags, { Name = "${var.name_prefix}-nat-instance" })
}

resource "aws_eip" "nat" {
  domain   = "vpc"
  instance = aws_instance.nat.id
  tags     = merge(var.tags, { Name = "${var.name_prefix}-nat-eip" })

  depends_on = [aws_instance.nat]
}

data "aws_route_table" "private_by_subnet" {
  for_each  = toset(var.app_subnet_ids)
  subnet_id = each.value
}

resource "aws_route" "nat" {
  for_each = toset([
    for rtb in data.aws_route_table.private_by_subnet : rtb.route_table_id
  ])
  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_instance.nat.primary_network_interface_id
}
