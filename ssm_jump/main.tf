# SSM jump host for secure access to resources in a VPC (e.g. RDS via port forwarding).
# Instance has no public IP; use AWS SSM port forwarding from your laptop.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.31.0"
    }
  }
}

locals {
  name = "${var.name}-${terraform.workspace}-ssm-jump"
  tags = merge(var.tags, { Name = local.name })
}

data "aws_subnet" "jump" {
  id = var.subnet_id
}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# VPC interface endpoints for Systems Manager (Session Manager from private subnet)
# See: https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-create-vpc.html
# -----------------------------------------------------------------------------

resource "aws_security_group" "ssm_endpoints" {
  name        = "${var.name}-${terraform.workspace}-vpce-ssm"
  description = "Allow HTTPS from SSM jump to SSM/ssmmessages/ec2messages endpoints"
  vpc_id      = data.aws_subnet.jump.vpc_id
  tags        = merge(var.tags, { Name = "${var.name}-${terraform.workspace}-vpce-ssm" })

  ingress {
    description     = "HTTPS from SSM jump instance"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = var.security_group_ids
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "endpoints" {
  for_each = {
    ssm         = "ssm"
    ssmessages  = "ssmmessages"
    ec2messages = "ec2messages"
  }
  vpc_id              = data.aws_subnet.jump.vpc_id
  service_name        = "com.amazonaws.${data.aws_region.current.id}.${each.value}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.subnet_id]
  security_group_ids  = [aws_security_group.ssm_endpoints.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "${var.name}-${terraform.workspace}-vpce-${each.key}" })
}

# -----------------------------------------------------------------------------
# IAM role for SSM-managed instance
# -----------------------------------------------------------------------------

resource "aws_iam_role" "ssm_jump" {
  name = local.name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "ssm_jump" {
  role       = aws_iam_role.ssm_jump.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_jump" {
  name = local.name
  role = aws_iam_role.ssm_jump.name
  tags = local.tags
}

# -----------------------------------------------------------------------------
# Jump host EC2
# -----------------------------------------------------------------------------

data "aws_ami" "ssm_jump" {
  most_recent = true
  owners      = ["amazon"]

  # Standard AL2023 only: the loose al2023-ami-* pattern matches al2023-ami-minimal-*,
  # which is often newest by date but does not register with SSM (no working agent).
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "ssm_jump" {
  ami                    = data.aws_ami.ssm_jump.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = aws_iam_instance_profile.ssm_jump.name
  tags                   = local.tags
}
