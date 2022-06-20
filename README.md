
# What is a ETL Pipeline ??

A ETL pipeline is a set of steps or process which is done inorder to move data from the data source to databases or data warehouse. A ETL pipeline is usually used for storing and managing data for the purpose of Data Analytics and to obtain business insights.

This ETL pipeline designed using pyspark and various AWS   services.


## Authors

- [@naveenkrishna18](https://github.com/naveenkrishna18)


## Requirements
- AWS account
- Terraform
- Python
- Spark with Python (PySpark)

## Architecture
![Architecture]([https://via.placeholder.com/468x300?text=App+Screenshot+Here](https://github.com/naveenkrishna18/etl-pipeline/blob/main/Images/ETL%20Pipeline%20Architecture.jpg))


## Deployment
Either set up the AWS CLI on your local machine or save your Access and Secret Keys on a seperate 
terraform.tfvars file.

To initialise terraform run

```bash
  terraform init
```

To create an execution plan run
```bash
  terraform plan
```
To deploy the resources in the cloud, run
```bash
  terraform apply
```

## Working

The ETL process starts once the data file lands on the Source S3 bucket. The destination will be the etl table inside DynamoDb.


## License

[GNU](https://github.com/naveenkrishna18/etl-pipeline/blob/main/LICENSE)

