#step_functions.tf

resource "aws_sfn_state_machine" "daily_crypto_pipeline" {
  name     = "daily_crypto_pipeline"
  role_arn = aws_iam_role.sfn_role.arn

  definition = jsonencode({
    Comment = "Daily pipeline for ingestion and processing"
    StartAt = "LambdaIngest"

    States = {

      LambdaIngest = {
        Type     = "Task"
        Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:ingest-crypto-coins"
        Next     = "GlueBronzeToSilver"
      }

      GlueBronzeToSilver = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "bronze_to_silver"
        }
        Next = "RunSilverCrawler"
      }

      RunSilverCrawler = {
        Type     = "Task"
        Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:start_glue_crawler"
        Parameters = {
          CrawlerName = "silver-coins-market-crawler"
        }
        Next = "GlueSilverToGold"
        Retry = [
          {
            ErrorEquals = ["Glue.CrawlerRunningException"]
            IntervalSeconds = 30
            MaxAttempts = 3
            BackoffRate = 2
          }
        ]
      }

      GlueSilverToGold = {
        Type     = "Task"
        Resource = "arn:aws:states:::glue:startJobRun.sync"
        Parameters = {
          JobName = "silver_to_gold"
        }
        Next = "RunGoldCrawler"
      }

      RunGoldCrawler = {
        Type     = "Task"
        Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:start_glue_crawler"
        Parameters = {
          CrawlerName = "gold-coins-market-crawler"
        }
        Next = "ExportDataToS3"
        Retry = [
          {
            ErrorEquals = ["Glue.CrawlerRunningException"]
            IntervalSeconds = 30
            MaxAttempts = 3
            BackoffRate = 2
          }
        ]
      }

      ExportDataToS3 = {
        Type     = "Task"
        Resource = "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:export_crypto_data_to_s3"
        End      = true
        Retry = [
          {
            ErrorEquals = ["States.TaskFailed"]
            IntervalSeconds = 10
            MaxAttempts = 2
            BackoffRate = 1.5
          }
        ]
      }
    }
  })
}
#end of this tf file
