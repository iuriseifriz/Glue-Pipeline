#lambda_ingest.tf

# -------------------------------------------------------------------------------------------------
# Lambda de Ingestão - CoinGecko API
# -------------------------------------------------------------------------------------------------
resource "aws_lambda_function" "ingest_crypto_coins" {
  function_name = "ingest-crypto-coins"
  role          = aws_iam_role.lambda_ingest_role.arn
  handler       = "lambda_ingest_coins.lambda_handler"  # ← Nome correto
  runtime       = "python3.10"  # ← Versão atual
  timeout       = 30  # ← Timeout atual
  memory_size   = 128

  # Layer existente (requests)
  layers = [
    "arn:aws:lambda:us-east-1:381492258425:layer:requests-layer:1"
  ]

  # IMPORTANTE: vamos usar o código atual, não do S3
  # O Terraform vai ignorar mudanças no código se você não quiser atualizá-lo
  filename      = "dummy.zip"  # Placeholder - vamos usar lifecycle
  source_code_hash = "dummy"

  # Ignora mudanças no código para não sobrescrever
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
# IAM Role para a Lambda de Ingestão (já existe no AWS)
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role" "lambda_ingest_role" {
  name = "ingest-crypto-coins-role-svuwv39p"
  path = "/service-role/"  # ← Path correto

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

  # Inline policy existente
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
# Policy attachment existente
# -------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "lambda_ingest_basic_execution" {
  role       = aws_iam_role.lambda_ingest_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

#end of this tf file