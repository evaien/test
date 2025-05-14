terraform {
  backend "s3" {
    bucket         = "innovate-tf-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    profile        = "terraform-admin"
    encrypt        = true
    bucket_prefix  = "terraform/"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}