resource "aws_backup_plan" "plan" {
  count = var.backup_plan ? 1 : 0
  name  = "backup-plan-${terraform.workspace}"
  tags  = var.tags

  rule {
    completion_window        = 10080
    enable_continuous_backup = false
    recovery_point_tags      = {}
    rule_name                = "DailyBackups"
    schedule                 = "cron(0 5 ? * * *)"
    start_window             = 480
    target_vault_name        = "Default"

    lifecycle {
      cold_storage_after = 0
      delete_after       = 35
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "AWSBackupDefaultServiceRole"
  path               = "/service-role/${terraform.workspace}/"
  description        = "Provides AWS Backup permission to create backups and perform restores on your behalf across AWS services"
  tags               = var.tags
  assume_role_policy = <<-JSON
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "backup.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }
  JSON
}

resource "aws_iam_role_policy_attachment" "backup_AWSBackupServiceRolePolicyForBackup" {
  role       = aws_iam_role.backup.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_AWSBackupServiceRolePolicyForRestores" {
  role       = aws_iam_role.backup.id
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

resource "aws_backup_selection" "dynamodb" {
  count        = var.backup_plan ? 1 : 0
  iam_role_arn = aws_iam_role.backup.arn
  name         = "dynamodb"
  plan_id      = aws_backup_plan.plan[0].id

  resources = ["arn:aws:dynamodb:*:*:table/*"]
}


