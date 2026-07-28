terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "velafi-candidate-tfstate-bucket"
    key    = "assessment.tfstate"
    region = "us-east-2"
  }
}

provider "aws" {
  # No static credentials here on purpose: the provider picks up
  # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY / AWS_SESSION_TOKEN
  # from the environment via the default AWS credential chain.
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
