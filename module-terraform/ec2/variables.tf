
variable "vpc_id" {
  description = "VPC ID for the EC2 security group"
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet for EC2"
  type        = string
}

variable "instance_profile_name" {
  description = "IAM instance profile for EC2"
  type        = string
}

