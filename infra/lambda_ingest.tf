#lambda_ingest.tf

# -------------------------------------------------------------------------------------------------
# Lambda for ingestion - CoinGecko API
# -------------------------------------------------------------------------------------------------

# configs of the lambda
resource "aws_lambda_function" "ingest_crypto_coins" {
  function_name = "ingest-crypto-coins"
  role          = aws_iam_role.lambda_ingest_role.arn
  handler       = "lambda_ingest_coins.lambda_handler"
  runtime       = "python3.10" 
  timeout       = 30
  memory_size   = 128

  # Layer (requests)
  layers = [
    "arn:aws:lambda:us-east-1:381492258425:layer:requests-layer:1"
  ]

  environment {
    variables = {
      S3_BUCKET = aws_s3_bucket.datalake.bucket
    }
  }


  filename      = "dummy.zip"
  source_code_hash = "dummy"


  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash,
      last_modified
    ]
  }

  tags = {}
}

# -------------------------------------------------------------------------------------------------
# IAM Role for Lambda ingestion
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_ingest_role" {
  name = "ingest-crypto-coins-role-svuwv39p"
  path = "/service-role/" 

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

  # Inline policy
  inline_policy {
    name = "ingest-crypto-lambda-custom-role"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "s3:PutObject",
            "s3:PutObjectAcl"
          ]
          Resource = "${aws_s3_bucket.datalake.arn}/bronze/*"
        }
      ]
    })
  }
}

# -------------------------------------------------------------------------------------------------
# Policy attachment
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_ingest_basic_execution" {
  role       = aws_iam_role.lambda_ingest_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


#end of this tf file
