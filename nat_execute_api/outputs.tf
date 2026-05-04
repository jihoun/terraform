output "execute_api_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.execute_api.id
  description = "Interface VPC endpoint ID for execute-api."
}

output "nat_instance_id" {
  value       = aws_instance.nat.id
  description = "NAT EC2 instance ID."
}

output "nat_eip_public_ip" {
  value       = aws_eip.nat.public_ip
  description = "Public IPv4 of the NAT instance (Elastic IP)."
}
