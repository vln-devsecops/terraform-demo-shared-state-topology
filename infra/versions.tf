terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.63"
    }
  }

  backend "s3" {}
}

provider "aws" {
  region = coalesce(var.shared_state_region, "us-east-1")
}
