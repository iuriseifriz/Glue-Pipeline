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

# Configurar partition overwrite mode dinâmico
spark.conf.set("spark.sql.sources.partitionOverwriteMode", "dynamic")

# --------------------------------------------------------------------------------
# Args
# --------------------------------------------------------------------------------
args = getResolvedOptions(sys.argv, ["JOB_NAME"])
job_name = args["JOB_NAME"]

# --------------------------------------------------------------------------------
# Paths e Catalog
# --------------------------------------------------------------------------------
SILVER_DATABASE = "crypto_datalake"
SILVER_TABLE = "silver_coins_market"
GOLD_PATH = "s3://crypto-datalake-381492258425/gold/coins_market/"

# --------------------------------------------------------------------------------
# Ler dados da tabela silver (Glue Catalog)
# --------------------------------------------------------------------------------
silver_df = glueContext.create_dynamic_frame.from_catalog(
    database=SILVER_DATABASE,
    table_name=SILVER_TABLE
).toDF()

# --------------------------------------------------------------------------------
# Garantir que temos coluna 'dt' para particionamento
# --------------------------------------------------------------------------------
if "dt" not in silver_df.columns:
    silver_df = silver_df.withColumn("dt", col("ingestion_timestamp").substr(1, 10))

# --------------------------------------------------------------------------------
# Deduplicação: manter apenas o registro mais recente por (coin_id, dt)
# (Proteção extra caso ainda haja duplicatas vindas do silver)
# --------------------------------------------------------------------------------
window = Window.partitionBy("coin_id", "dt").orderBy(col("ingestion_timestamp").desc())

gold_df = silver_df.withColumn("rank", row_number().over(window)) \
                   .filter(col("rank") == 1) \
                   .drop("rank")

# --------------------------------------------------------------------------------
# Gravar em S3 na camada GOLD, particionado por dt
# mode="overwrite" + dynamic partition = sobrescreve apenas partições atuais
# --------------------------------------------------------------------------------
(
    gold_df
    .write
    .mode("overwrite")
    .partitionBy("dt")
    .parquet(GOLD_PATH)
)

print(f"Job {job_name} completed successfully")