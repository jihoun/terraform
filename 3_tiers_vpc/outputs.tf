output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = local.public_subnet_ids
}

output "app_subnet_ids" {
  value = local.private_subnet_ids
}

output "db_subnet_ids" {
  value = local.private_subnet_ids
}

output "public_security_group_ids" {
  value = [aws_security_group.public.id]
}

output "app_security_group_ids" {
  value = [aws_security_group.app.id]
}

output "db_security_group_ids" {
  value = [aws_security_group.db.id]
}
