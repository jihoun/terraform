
resource "aws_ecs_cluster" "cluster" {
  name = var.name
  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "spot" {
  cluster_name       = aws_ecs_cluster.cluster.name
  capacity_providers = ["FARGATE_SPOT"]
}
