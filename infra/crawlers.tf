#crawlers.tf

# -------------------------------------------------------------------------------------------------
# CRAWLERS
# -------------------------------------------------------------------------------------------------

# -------------------------------
# Crawler para camada SILVER
# -------------------------------
resource "aws_glue_crawler" "silver_coins_market" {
  name          = "silver-coins-market-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.crypto.name

  s3_target {
    path = "s3://${aws_s3_bucket.datalake.bucket}/silver/coins_market/"
  }

  table_prefix = "silver_"

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })
}

# -------------------------------
# Crawler para camada GOLD
# -------------------------------
resource "aws_glue_crawler" "gold_coins_market" {
  name          = "gold-coins-market-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.crypto.name

  s3_target {
    path = "s3://${aws_s3_bucket.datalake.bucket}/gold/coins_market/"
  }

  table_prefix = "gold_"

  schema_change_policy {
    update_behavior = "UPDATE_IN_DATABASE"
    delete_behavior = "LOG"
  }

  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Partitions = {
        AddOrUpdateBehavior = "InheritFromTable"
      }
    }
  })
}

# end of this tf file
