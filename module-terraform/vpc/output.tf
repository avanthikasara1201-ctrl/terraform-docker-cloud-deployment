output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
output "public_subnet_id" {
  value = aws_subnet.public.id
}