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

# # resource "aws_s3_bucket" "new-bucket-creation" {
# #     bucket = "etl-pipeline-source-bucket-15062022"
# #     tags = {
# #         Description = "Source Bucket for our pipeline"
# #     }
# # }

resource "aws_iam_role" "lambda_role" {
    name = "lambda_role"
    assume_role_policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid"    : ""
      }
    ]
}
    EOF
}

resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_lambda"
  path        = "/"
  description = "AWS policy for managing aws lambda role"
  policy = <<EOF
{
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : [
          "logs:CreateLogsGroup",
          "logs:CreateLogsStream",
          "logs:PutLogEvents"
        ],
        "Resource" : "*",
        "Effect"   : "Allow"
      }
    ]
}  
  EOF
}

resource "aws_iam_policy_attachment" "attach_policy" {
  name       = "lambda-role-policy-attachment"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_python_code"{
    type = "zip"
    source_file = "${path.module}/handler_code/ingest_data_to_destination_bucket.py"
    output_path = "${path.module}/handler_code/ingest_data_to_destination_bucket.zip"
}

resource "aws_lambda_function" "source_to_destination_lambda" {
  filename      = "${path.module}/handler_code/ingest_data_to_destination_bucket.zip"
  function_name = "src_to_dst_s3_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "ingest_data_to_destination_bucket.lambda_handler"
  runtime = "python3.8"
  depends_on = [aws_iam_policy_attachment.attach_policy]
}