import json
import boto3

s3 = boto3.client("s3")
glue = boto3.client("glue")

def lambda_handler(event, context):
    
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    file = event["Records"][0]["s3"]["object"]["key"]
    
    response = glue.start_job_run(
        JobName = "Ingest_to_s3_glue_job",
        Arguments = {
            "--s3_target_path_key" : file,
            "--s3_target_path_bucket" : bucket
        }
    )
    
    
    return {
        'bucket_name_nav': bucket,
        'Key_nav': file
    }
