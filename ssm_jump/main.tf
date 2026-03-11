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

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
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
