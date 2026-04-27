variable "aws_region" {
  description = "AWS region to deploy all resources into."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "allowed_ssh_cidr" {
  description = "Your IP address in CIDR notation allowed to SSH into the EC2 instance (e.g. 203.0.113.5/32)."
  type        = string
}

variable "db_username" {
  description = "Master username for the RDS instance."
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Master password for the RDS instance. Must be at least 8 characters."
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "Globally unique name for the S3 static assets bucket."
  type        = string
}

variable "availability_zones" {
  description = "List of two availability zones to deploy public and private subnets into."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023 in your chosen region)."
  type        = string
  default     = "ami-0c02fb55956c7d316"
}
