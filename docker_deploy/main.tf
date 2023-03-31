data "aws_region" "current" {}

resource "aws_ecs_task_definition" "service" {
  family                   = var.name
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
  tags                     = var.tags
  cpu                      = "1024"
  memory                   = "2048"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name      = var.name
      essential = true
      image     = var.image_url
      environment = [
        for k, v in var.environment_variables : {
          "name"  = k
          "value" = v
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-create-group  = "true"
          awslogs-group         = "/ecs/${var.name}"
          awslogs-region        = "${data.aws_region.current.name}"
          awslogs-stream-prefix = "ecs"
        }
      }
      portMappings = [
        {
          containerPort = var.port
          appProtocol   = "http"
          protocol      = "tcp"
        },
      ]
    }
  ])
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
}

resource "aws_ecs_service" "strapi" {
  name                 = var.name
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = aws_ecs_task_definition.service.arn
  launch_type          = "FARGATE"
  desired_count        = 1
  tags                 = var.tags
  force_new_deployment = true
  depends_on           = [aws_iam_role_policy_attachment.execution, aws_lb_listener.http]

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = var.name
    container_port   = 1337
  }

  network_configuration {
    subnets          = var.app_subnet_ids
    assign_public_ip = false
    security_groups  = var.app_security_group_ids
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "aws_route53_record" "cms" {
  count   = var.domain_name != null && var.zone_id != null ? 1 : 0
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_alb.lb.dns_name
    zone_id                = aws_alb.lb.zone_id
    evaluate_target_health = true
  }
}
