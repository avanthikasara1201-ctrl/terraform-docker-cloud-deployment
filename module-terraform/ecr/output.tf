
output "repository_url" {
  description = "URL used to push and pull Docker images"
  value       = aws_ecr_repository.web.repository_url
}

output "repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.web.arn
}
