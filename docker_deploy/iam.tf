
resource "aws_iam_role" "execution" {
  name_prefix = substr("${var.name}-execution_", 0, 38)
  path        = "/${terraform.workspace}/"
  tags        = var.tags

  assume_role_policy = <<-JSON
    {
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Effect": "Allow",
          "Principal": { "Service": "ecs-tasks.amazonaws.com" }
        }
      ],
      "Version": "2012-10-17"
    }
  JSON
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy_document" "execution" {
  statement {
    actions   = ["logs:CreateLogGroup"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "execution" {
  policy      = data.aws_iam_policy_document.execution.json
  name_prefix = "strapi-execution"
  path        = "/ecs/${terraform.workspace}/"
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "execution2" {
  role       = aws_iam_role.execution.id
  policy_arn = aws_iam_policy.execution.id
}

resource "aws_iam_role" "task" {
  name_prefix = "${substr(var.name, 0, 37)}_"
  path        = "/${terraform.workspace}/"
  tags        = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
      }
    ]
  })
}
