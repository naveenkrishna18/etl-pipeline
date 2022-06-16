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

resource "aws_s3_bucket" "source-bucket-creation" {
    bucket = "etl-pipeline-source-bucket-15062022"
    tags = {
        Description = "Source Bucket for our pipeline"
    }
}



resource "aws_iam_role" "invoke_glue_lambda_role" {
    name = "invoke_glue_lambda_role"
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

resource "aws_iam_policy" "iam_policy_for_invoke_glue_lambda_role" {
  name        = "aws_iam_policy_for_invoke_glue_lambda_role"
  path        = "/"
  description = "AWS policy for managing aws lambda role"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}   
  EOF
}

resource "aws_iam_policy_attachment" "invoke_glue_lambda_attach_policy" {
  name       = "invoke_glue_lambda_role_policy_attachment"
  roles      = [aws_iam_role.invoke_glue_lambda_role.name]
  policy_arn = aws_iam_policy.iam_policy_for_invoke_glue_lambda_role.arn
}

data "archive_file" "zip_python_code"{
    type = "zip"
    source_file = "${path.module}/handler_code/ingest_data_to_destination_bucket.py"
    output_path = "${path.module}/handler_code/ingest_data_to_destination_bucket.zip"
}

resource "aws_lambda_function" "source_to_destination_lambda" {
  filename      = "${path.module}/handler_code/ingest_data_to_destination_bucket.zip"
  function_name = "src_to_dst_s3_lambda"
  role          = aws_iam_role.invoke_glue_lambda_role.arn
  handler       = "ingest_data_to_destination_bucket.lambda_handler"
  runtime = "python3.8"
  depends_on = [aws_iam_policy_attachment.invoke_glue_lambda_attach_policy]

}

resource "aws_s3_bucket_notification" "source_to_destination_lambda_trigger" {
  bucket = aws_s3_bucket.source-bucket-creation.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.source_to_destination_lambda.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  }
}

resource "aws_lambda_permission" "invoke_source_to_glue_lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.source_to_destination_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.source-bucket-creation.id}"
}

resource "aws_iam_role" "glue_role" {
    name = "glue_role"
    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "glue.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
    EOF
}

resource "aws_iam_policy" "iam_policy_for_glue" {
  name        = "aws_iam_policy_for_glue"
  path        = "/"
  description = "AWS policy for managing aws glue role"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}   
  EOF
}

resource "aws_iam_policy_attachment" "glue_attach_policy" {
  name       = "glue_policy_attachment"
  roles      = [aws_iam_role.glue_role.name]
  policy_arn = aws_iam_policy.iam_policy_for_glue.arn
}

resource "aws_s3_bucket" "glue_scripts" {
    bucket = "gule-scripts-bucket-nav-15062022"
    tags = {
        Description = "bucket for glue scripts"
    }
}

resource "aws_s3_bucket_object" "glue_script_upload" {
  bucket = aws_s3_bucket.glue_scripts.bucket
  key    = "glue_script.py"
  source = "${path.module}/scripts/glue_script.py"
}


resource "aws_glue_job" "glue_job" {
  glue_version = "2.0"
  name     = "Ingest_to_s3_glue_job"
  role_arn = aws_iam_role.glue_role.arn
  command {
    script_location = "s3://${aws_s3_bucket.glue_scripts.bucket}/glue_script.py"
    python_version  = "3"
  }
}
resource "aws_s3_bucket" "destination-bucket-creation" {
    bucket = "etl-pipeline-destination-bucket-15062022"
    tags = {
        Description = "Destination Bucket for our pipeline"
    }
}

resource "aws_iam_role" "ddb_lambda_role" {
    name = "ddb_lambda_role"
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

resource "aws_iam_policy" "iam_policy_for_ddb_lambda" {
  name        = "aws_iam_policy_ddb_for_lambda"
  path        = "/"
  description = "AWS policy for managing aws ddb lambda role"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "*",
            "Resource": "*"
        }
    ]
}  
  EOF
}

resource "aws_iam_policy_attachment" "attach_policy_ddb_lambda" {
  name       = "ddb_lambda-role-policy-attachment"
  roles      = [aws_iam_role.ddb_lambda_role.name]
  policy_arn = aws_iam_policy.iam_policy_for_ddb_lambda.arn
}

data "archive_file" "zip_ddb_python_code"{
    type = "zip"
    source_file = "${path.module}/ddb_lambda_handler/ddb_lambda_handler.py"
    output_path = "${path.module}/ddb_lambda_handler/ddb_lambda_handler.zip"
}

resource "aws_lambda_function" "destination_bucket_to_ddb_lambda" {
  filename      = "${path.module}/ddb_lambda_handler/ddb_lambda_handler.zip"
  function_name = "dst_s3_to_ddb_lambda"
  role          = aws_iam_role.ddb_lambda_role.arn
  handler       = "ddb_lambda_handler.lambda_handler"
  runtime = "python3.8"
  depends_on = [aws_iam_policy_attachment.attach_policy_ddb_lambda]
}

resource "aws_s3_bucket_notification" "ddb_lambda_trigger" {
  bucket = aws_s3_bucket.destination-bucket-creation.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.destination_bucket_to_ddb_lambda.arn
    events              = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]

  }
}

resource "aws_dynamodb_table" "etl_final_table" {
    name = "etl_final_table"
    hash_key = "id"
    billing_mode = "PAY_PER_REQUEST"
    attribute {
      name = "id"
      type = "N"
    }
}

resource "aws_lambda_permission" "test" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.destination_bucket_to_ddb_lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = "arn:aws:s3:::${aws_s3_bucket.destination-bucket-creation.id}"
}