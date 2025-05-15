terraform {
  backend "s3" {
    bucket        = "innovate-tf-state"
    key           = "environments/prod/terraform.tfstate"
    region        = "us-east-1"
    profile       = "terraform-admin"
	dynamodb_table = "terraform-state-lock"
    encrypt       = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
  }
}