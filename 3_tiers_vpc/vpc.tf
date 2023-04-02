resource "aws_vpc" "main" {
  tags = merge(var.tags, { "Name" = var.name })

  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/20"
  availability_zone = "ap-southeast-1a"

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-public-${data.aws_region.current.name}a"
  })
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.16.0/20"
  availability_zone = "ap-southeast-1b"

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-public-${data.aws_region.current.name}b"
  })
}

locals {
  public_subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.128.0/20"
  availability_zone = "ap-southeast-1a"

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-private-${data.aws_region.current.name}a"
  })
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.144.0/20"
  availability_zone = "ap-southeast-1b"

  tags = merge(var.tags, {
    Name = "${var.name}-subnet-private-${data.aws_region.current.name}b"
  })
}

locals {
  private_subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
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
  for_each = {
    a = aws_subnet.public_a.id
    b = aws_subnet.public_b.id
  }
  subnet_id      = each.value
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.name}-rtb-private-${data.aws_region.current.name}a"
  })
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_a.id
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "${var.name}-rtb-private-${data.aws_region.current.name}b"
  })
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_b.id
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
  service_name      = "com.amazonaws.${data.aws_region.current.name}.${each.value}"
  vpc_endpoint_type = "Interface"
  subnet_ids        = local.private_subnet_ids

  tags = merge(var.tags, {
    "Name" = "${var.name}-vpce-${each.key}"
  })

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = merge(var.tags, {
    "Name" = "${var.name}-vpce-s3"
  })
}

resource "aws_vpc_endpoint_route_table_association" "s3" {
  for_each = {
    a : aws_route_table.private_a.id
    b : aws_route_table.private_b.id
  }
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = each.value
}

resource "aws_security_group" "public" {
  name   = "${var.name}-${terraform.workspace}-public"
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-public" })

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    ipv6_cidr_blocks = ["::/0"]
    cidr_blocks      = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "app" {
  name   = "${var.name}-${terraform.workspace}-app"
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-app" })

  ingress {
    description = "From self"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  ingress {
    description     = "From load balancer"
    from_port       = 1337
    to_port         = 1337
    protocol        = "TCP"
    security_groups = [aws_security_group.public.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "db" {
  name   = "${var.name}-${terraform.workspace}-db"
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "${var.name}-db" })

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "TCP"
    security_groups = [aws_security_group.app.id]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}
