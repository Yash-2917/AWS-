output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.secure_vpc.id
}

output "alb_dns_name" {
  description = "DNS name of the Load Balancer — use this to access your app"
  value       = aws_lb.alb.dns_name
}

output "alb_url" {
  description = "Full URL to access the application"
  value       = "http://${aws_lb.alb.dns_name}"
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "private_subnet_ids" {
  description = "IDs of private subnets (where EC2 servers live)"
  value       = [aws_subnet.private_az1.id, aws_subnet.private_az2.id]
}

output "nat_gateway_ip" {
  description = "Public IP of NAT Gateway (this is the only outbound IP from private servers)"
  value       = aws_eip.nat_eip.public_ip
}
