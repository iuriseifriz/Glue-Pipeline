#lambda_export_data.tf

# -------------------------------------------------------------------------------------------------
# Lambda Function - Export Athena Data to Public S3
# -------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "export_data_to_s3" {
  function_name = "export_crypto_data_to_s3"
  role          = aws_iam_role.lambda_export_role.arn
  handler       = "export_data_to_s3.lambda_handler"
  runtime       = "python3.11"
  timeout       = 120

  s3_bucket = aws_s3_bucket.datalake.bucket
  s3_key    = "src/export_data_to_s3.zip"

  environment {
    variables = {
      DATABASE       = "crypto_datalake"
      TABLE          = "gold_coins_market"
      OUTPUT_BUCKET  = aws_s3_bucket.public_data.bucket
      OUTPUT_KEY     = "top10_cryptos.json"
      ATHENA_OUTPUT  = "s3://${aws_s3_bucket.datalake.bucket}/athena/query-results/"
    }
  }

  tags = {
    project = "crypto-datalake"
    purpose = "data-export"
  }
}

# -------------------------------------------------------------------------------------------------
# IAM Role para Lambda de Export
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_export_role" {
  name = "lambda-export-crypto-data-role"

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
# CloudWatch Logs Policy
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_export_logs" {
  role       = aws_iam_role.lambda_export_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# -------------------------------------------------------------------------------------------------
# Athena Query Policy
# -------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "lambda_export_athena_policy" {
  name = "lambda-export-athena-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "athena:StartQueryExecution",
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "athena:StopQueryExecution"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:GetDatabase",
          "glue:GetTable",
          "glue:GetPartitions"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_export_athena_attach" {
  role       = aws_iam_role.lambda_export_role.name
  policy_arn = aws_iam_policy.lambda_export_athena_policy.arn
}

# -------------------------------------------------------------------------------------------------
# S3 Policy - CORRIGIDA com todas permissões necessárias
# -------------------------------------------------------------------------------------------------
resource "aws_iam_policy" "lambda_export_s3_policy" {
  name = "lambda-export-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ReadWriteDataLakeBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.datalake.arn,
          "${aws_s3_bucket.datalake.arn}/*"
        ]
      },
      {
        Sid    = "WritePublicDataBucket"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.public_data.arn,
          "${aws_s3_bucket.public_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_export_s3_attach" {
  role       = aws_iam_role.lambda_export_role.name
  policy_arn = aws_iam_policy.lambda_export_s3_policy.arn
}

#end of this tf file
