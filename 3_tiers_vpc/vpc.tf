resource "aws_vpc" "main" {
  tags = merge(var.tags, { "Name" = var.name })

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  for_each = {
    a: "10.0.0.0/20", 
    b: "10.0.16.0/20"
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "ap-southeast-1${each.key}"

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-public-${data.aws_region.current.id}${each.key}"
  })
}

locals {
  public_subnet_ids = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_subnet" "private" {
  for_each = {
    a: "10.0.128.0/20", 
    b: "10.0.144.0/20"
  }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "ap-southeast-1${each.key}"

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-private-${data.aws_region.current.id}${each.key}"
  })
}

locals {
  private_subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, { Name = "${var.name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-rtb-public" })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  for_each = { a = "a", b = "b" }
  vpc_id   = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.name}-rtb-private-${data.aws_region.current.id}${each.value}"
  })
}

resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name}-${terraform.workspace}-vpce"
  vpc_id      = aws_vpc.main.id
  description = "Security group for VPC interface endpoints (Secrets Manager, ECR, logs, RDS)"

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
    description     = "HTTPS from app tier"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name}-vpce-sg" })
}

resource "aws_vpc_endpoint" "endpoints" {
  for_each = {
    ecr            = "ecr.dkr"
    ecr-api        = "ecr.api"
    secretsmanager = "secretsmanager"
    logs           = "logs"
    rds            = "rds"
  }
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${data.aws_region.current.id}.${each.value}"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnet_ids
  security_group_ids = [aws_security_group.vpc_endpoints.id] 

  tags = merge(var.tags, {
    "Name" = "${var.name}-vpce-${each.key}"
  })

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.id}.s3"

  tags = merge(var.tags, {
    "Name" = "${var.name}-vpce-s3"
  })
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  for_each         = aws_route_table.private
  vpc_endpoint_id  = aws_vpc_endpoint.s3.id
  route_table_id   = each.value.id
}

resource "aws_security_group" "public" {
  name        = "${var.name}-${terraform.workspace}-public"
  vpc_id      = aws_vpc.main.id
  tags        = merge(var.tags, { Name = "${var.name}-public" })
  description = "Public security group for ${var.name}"

  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "TCP"
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    ipv6_cidr_blocks = ["::/0"]
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming http requests"
  }
  ingress {
    from_port = 443
    to_port   = 443
    protocol  = "TCP"
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    ipv6_cidr_blocks = ["::/0"]
    #tfsec:ignore:aws-ec2-no-public-ingress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    description = "Incoming https requests"
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
    description      = "Outgoing requests"
  }
}

resource "aws_security_group" "app" {
  name        = "${var.name}-${terraform.workspace}-app"
  vpc_id      = aws_vpc.main.id
  tags        = merge(var.tags, { Name = "${var.name}-app" })
  description = "App security group for ${var.name}"

  ingress {
    description = "From self"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  ingress {
    description     = "From load balancer"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "TCP"
    security_groups = [aws_security_group.public.id]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
    description      = "Outgoing requests"
  }
}

resource "aws_security_group" "db" {
  name        = "${var.name}-${terraform.workspace}-db"
  vpc_id      = aws_vpc.main.id
  tags        = merge(var.tags, { Name = "${var.name}-db" })
  description = "Database security group for ${var.name}"

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.app.id]
    description     = "PostgreSQL requests"
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    ipv6_cidr_blocks = ["::/0"]
    description      = "Outgoing requests"
  }
}
