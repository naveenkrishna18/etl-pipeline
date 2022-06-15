terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
    region = "ap-south-1"
    access_key = var.access_key
    secret_key = var.secret_key
}

resource "aws_s3_bucket" "new-bucket-creation" {
    bucket = "etl-pipeline-source-bucket-15062022"
    tags = {
        Description = "Source Bucket for our pipeline"
    }
}