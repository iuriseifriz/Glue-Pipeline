import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.sql.functions import col, row_number
from pyspark.sql.window import Window

# --------------------------------------------------------------------------------
# Glue / Spark setup
# --------------------------------------------------------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# config dynamic partition
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

# --------------------------------------------------------------------------------
# Args
# --------------------------------------------------------------------------------
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
job_name = args["JOB_NAME"]

# --------------------------------------------------------------------------------
# Paths and Catalog
# --------------------------------------------------------------------------------
SILVER_DATABASE = "crypto_datalake"
SILVER_TABLE = "silver_coins_market"
GOLD_PATH = "s3://crypto-datalake-381492258425/gold/coins_market/"

# --------------------------------------------------------------------------------
# read from silver (Glue Catalog)
# --------------------------------------------------------------------------------
silver_df = glueContext.create_dynamic_frame.from_catalog(
    database=SILVER_DATABASE,
    table_name=SILVER_TABLE
).toDF()

# --------------------------------------------------------------------------------
# make sure we have dt as partition
# --------------------------------------------------------------------------------
if "dt" not in silver_df.columns:
    silver_df = silver_df.withColumn("dt", col("ingestion_timestamp").substr(1, 10))

# --------------------------------------------------------------------------------
# deduplication avoided (coin_id, dt)
# (extra protection if silver changed)
# --------------------------------------------------------------------------------
window = Window.partitionBy("coin_id", "dt").orderBy(col("ingestion_timestamp").desc())

gold_df = silver_df.withColumn("rank", row_number().over(window)) \
                   .filter(col("rank") == 1) \
                   .drop("rank")

# --------------------------------------------------------------------------------
# write the gold layer partitioned by dt
# mode="overwrite" + dynamic partition = overwrite data of right now
# --------------------------------------------------------------------------------
(
    gold_df
    .write
    .mode("overwrite")
    .partitionBy("dt")
    .parquet(GOLD_PATH)
)

print(f"Job {job_name} completed successfully")