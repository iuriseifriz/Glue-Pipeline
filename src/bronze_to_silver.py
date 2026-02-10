import sys
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.utils import getResolvedOptions
from pyspark.sql.functions import col, explode, row_number
from pyspark.sql.window import Window
from pyspark.sql.types import *

# --------------------------------------------------------------------------------
# Glue / Spark setup
# --------------------------------------------------------------------------------
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session

# Configurar partition overwrite mode dinâmico
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

# --------------------------------------------------------------------------------
# Args
# --------------------------------------------------------------------------------
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
job_name = args["JOB_NAME"]

# --------------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------------
BRONZE_PATH = "s3://crypto-datalake-381492258425/bronze/coins_market/"
SILVER_PATH = "s3://crypto-datalake-381492258425/silver/coins_market/"

# --------------------------------------------------------------------------------
# Read BRONZE (JSON)
# --------------------------------------------------------------------------------
bronze_df = spark.read.json(BRONZE_PATH)

# --------------------------------------------------------------------------------
# Explode data[]
# --------------------------------------------------------------------------------
coins_df = bronze_df.select(
    col("source"),
    col("ingestion_timestamp"),
    explode(col("data")).alias("coin")
)

# --------------------------------------------------------------------------------
# Flatten structure
# --------------------------------------------------------------------------------
flat_df = coins_df.select(
    col("source"),
    col("ingestion_timestamp"),

    col("coin.id").alias("coin_id"),
    col("coin.symbol"),
    col("coin.name"),

    col("coin.current_price"),
    col("coin.market_cap"),
    col("coin.market_cap_rank"),
    col("coin.total_volume"),

    col("coin.high_24h"),
    col("coin.low_24h"),

    col("coin.price_change_24h"),
    col("coin.price_change_percentage_24h"),

    col("coin.market_cap_change_24h"),
    col("coin.market_cap_change_percentage_24h"),

    col("coin.circulating_supply"),
    col("coin.total_supply"),
    col("coin.max_supply"),

    col("coin.ath"),
    col("coin.ath_change_percentage"),
    col("coin.ath_date"),

    col("coin.atl"),
    col("coin.atl_change_percentage"),
    col("coin.atl_date"),

    col("coin.last_updated")
)

# --------------------------------------------------------------------------------
# Extract partition (dt) from ingestion_timestamp
# --------------------------------------------------------------------------------
flat_df = flat_df.withColumn(
    "dt",
    col("ingestion_timestamp").substr(1, 10)
)

# --------------------------------------------------------------------------------
# Deduplicação: manter apenas o registro mais recente por (coin_id, dt)
# --------------------------------------------------------------------------------
window = Window.partitionBy("coin_id", "dt").orderBy(col("ingestion_timestamp").desc())

deduplicated_df = flat_df.withColumn("rank", row_number().over(window)) \
                         .filter(col("rank") == 1) \
                         .drop("rank")

# --------------------------------------------------------------------------------
# Write SILVER (Parquet, partitioned)
# mode="overwrite" + dynamic partition = sobrescreve apenas partições atuais
# --------------------------------------------------------------------------------
(
    deduplicated_df
    .write
    .mode("overwrite")
    .partitionBy("dt")
    .parquet(SILVER_PATH)
)

print(f"Job {job_name} completed successfully")