terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Create the backend bucket manually before running terraform init.
  # See README.md for setup instructions.
  # backend "s3" {
  #   bucket = "vela-payments-tf-state"
  #   key    = "vela-payments/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region                      = var.aws_region
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  skip_metadata_api_check     = true

  default_tags {
    tags = {
      Project = "vela-payments"
    }
  }
}
