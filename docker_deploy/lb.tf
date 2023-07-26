
resource "aws_alb" "lb" {
  subnets                    = var.lb_subnet_ids
  security_groups            = var.lb_security_group_ids
  name_prefix                = var.name
  tags                       = var.tags
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "tg" {
  name_prefix = var.name
  tags        = var.tags
  port        = var.port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "http" {
  count             = var.domain_name == null ? 1 : 0
  load_balancer_arn = aws_alb.lb.arn
  port              = "80"
  #tfsec:ignore:aws-elb-http-not-used
  protocol = "HTTP"
  tags     = var.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "https" {
  count             = var.domain_name != null && var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_alb.lb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn
  tags              = var.tags

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_lb_listener" "http_2_https" {
  count             = var.domain_name != null ? 1 : 0
  load_balancer_arn = aws_alb.lb.arn
  port              = "80"
  protocol          = "HTTP"
  tags              = var.tags

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
