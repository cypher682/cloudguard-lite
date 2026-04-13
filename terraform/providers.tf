terraform {
  required_version = ">= 1.14.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
    backend "s3" {
    bucket  = "cloudguard-lite-tfstate-758620460011"
    key     = "cloudguard-lite/terraform.tfstate"
    region  = "us-east-1"
  }
}



provider "aws" {
  region  = var.aws_region
}
