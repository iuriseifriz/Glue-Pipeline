#lambda_crawler.tf

# -------------------------------------------------------------------------------------------------
# Lambda Function - Inicia Crawlers (Reutilizável)
# -------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "start_glue_crawler" {
  function_name = "start_glue_crawler"
  role          = aws_iam_role.lambda_crawler_role.arn
  handler       = "crawler_starter_lambda.lambda_handler"
  runtime       = "python3.11"
  timeout       = 900  # 15 minutos

  # Código está no S3
  s3_bucket = "crypto-datalake-381492258425"
  s3_key    = "src/crawler_starter_lambda.zip"

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }

  tags = {
    project = "crypto-datalake"
    purpose = "crawler-orchestration"
  }
}

# -------------------------------------------------------------------------------------------------
# IAM Role para a Lambda
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_crawler_role" {
  name = "lambda-start-crawler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# -------------------------------------------------------------------------------------------------
# Policy: CloudWatch Logs
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_crawler_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -------------------------------------------------------------------------------------------------
# Policy: Glue Crawler
# -------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "lambda_glue_crawler_policy" {
  name = "lambda-glue-crawler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartCrawler",
          "glue:GetCrawler",
          "glue:GetCrawlerMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_glue_attach" {
  role       = aws_iam_role.lambda_crawler_role.name
  policy_arn = aws_iam_policy.lambda_glue_crawler_policy.arn
}

#end of this tf file