provider "aws" {
  profile = "terraform-admin"
  region  = "us-east-1"
}

resource "aws_s3_bucket" "tf_backend" {
  bucket              = "innovate-tf-state"
  object_lock_enabled = true

  tags = {
    Environment = "shared-services"
    Purpose     = "terraform-backend"
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_backend.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_object_lock_configuration" "object_lock" {
  bucket = aws_s3_bucket.tf_backend.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = 30
    }
  }
}
