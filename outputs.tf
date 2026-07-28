output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "vps_instance_id" {
  description = "ID of the VPS EC2 instance"
  value       = aws_instance.vps.id
}

output "vps_public_ip" {
  description = "Public IP address of the VPS"
  value       = aws_instance.vps.public_ip
}

output "db_endpoint" {
  description = "Connection endpoint of the RDS PostgreSQL instance"
  value       = aws_db_instance.this.endpoint
}

output "db_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.this.db_name
}
