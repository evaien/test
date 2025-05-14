provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::<prod-account-id>:role/TerraformExecutionRole"
  }

  profile = "terraform-admin"
}