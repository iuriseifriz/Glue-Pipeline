#jobs.tf

resource "aws_glue_job" "bronze_to_silver" {
  name     = "bronze_to_silver"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://${aws_s3_bucket.datalake.bucket}/src/bronze_to_silver.py"
    python_version  = "3"
  }

  glue_version = "4.0"
  timeout      = 10
  max_retries  = 0

  execution_property {
    max_concurrent_runs = 1
  }

  default_arguments = {
    "--job-language" = "python"
  }
}

resource "aws_glue_job" "silver_to_gold" {
  name     = "silver_to_gold"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    script_location = "s3://crypto-datalake-381492258425/src/silver_to_gold.py"
    python_version  = "3"
  }

  glue_version = "4.0"
  worker_type  = "G.1X"
  number_of_workers = 2

  default_arguments = {
    "--job-language"    = "python"
    "--enable-metrics"  = "true"

    "--SILVER_DATABASE" = "crypto_datalake"
    "--SILVER_TABLE"    = "coins_market"
    "--GOLD_S3_PATH"    = "s3://crypto-datalake-381492258425/gold/coins_daily_snapshot/"
  }

  execution_property {
    max_concurrent_runs = 1
  }

  tags = {
    project = "crypto-datalake"
    layer   = "gold"
  }
}

#end of this tf file
