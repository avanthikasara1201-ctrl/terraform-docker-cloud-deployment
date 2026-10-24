output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}
output "security_group_id" {
  value = module.ec2.security_group_id
}
output "instance_id" {
  value = module.ec2.instance_id
}

output "public_ip" {
  value = module.ec2.public_ip
}

output "ecr_repository_url" {
  description = "URL of our ECR Docker repository"
  value       = module.ecr.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of our ECR Docker repository"
  value       = module.ecr.repository_arn
}
