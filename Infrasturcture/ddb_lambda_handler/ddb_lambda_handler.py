import boto3
from datetime import date

s3 = boto3.client("s3")
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('etl_final_table')

def lambda_handler(event, context):
    bucket = event["Records"][0]["s3"]["bucket"]["name"]
    key =  event["Records"][0]["s3"]["object"]["key"]
    response = s3.get_object(Bucket = bucket, Key= key)
    data = response["Body"].read().decode("utf-8")
    csvdata = data.split("\n")
    csvdata = list(filter(None,csvdata))
    today = date.today()
    date_of_transaction = today.strftime("%b-%d-%Y")
    for item in csvdata:
        item_arr = item.split(",")
        idint = int(item_arr[0])
        table.put_item(
            Item = {
                "date_of_transaction" : date_of_transaction,
                "id" : idint,
                "product_name" : item_arr[1],
                "quantity" : item_arr[2],
                "price" : item_arr[3]
            })

    return "done"
