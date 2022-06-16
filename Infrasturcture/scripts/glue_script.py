from awsglue.utils import getResolvedOptions
import sys
from pyspark.sql import SparkSession

args = getResolvedOptions(sys.argv,["s3_target_path_key", "s3_target_path_bucket"])
bucket = args["s3_target_path_bucket"]
file = args["s3_target_path_key"]

print(bucket,file)

spark = SparkSession.builder.appName("Glue Job").getOrCreate()
input_file = f"s3a://{bucket}//{file}"
output_file = f"s3a://etl-pipeline-destination-bucket-15062022//outputfile"

df1 = spark.read.options(Header = "True",inferSchema="True").csv(input_file)
df1.createOrReplaceTempView("product_table")
df2 = spark.sql("select product_id, product_name, quantity, price from product_table")
finalOutput = df2.groupBy("product_id","product_name").sum("quantity","price")

finalOutput.write.mode("overwrite").format("csv").save(output_file)