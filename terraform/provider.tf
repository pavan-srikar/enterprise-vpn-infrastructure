terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote backend — keeps tfstate off your local machine.
  # Setup: run scripts/setup-tf-backend.sh once before terraform init.
  # Then uncomment this block and run: terraform init -migrate-state
  #
  # No DynamoDB lock table — fine for solo/free-tier use.
  # Just don't run terraform apply from two places at once.
  #
  # backend "s3" {
  #   bucket  = "your-tf-state-bucket-name"
  #   key     = "vpn-infrastructure/terraform.tfstate"
  #   region  = "us-east-1"
  #   encrypt = true
  # }
  
}

provider "aws" {
  region = var.aws_region
}