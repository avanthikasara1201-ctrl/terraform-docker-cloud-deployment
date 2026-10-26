
output "instance_profile_name" {
  description = "IAM instance profile for EC2 to pull images from ECR"
  value       = aws_iam_instance_profile.ec2.name
}
