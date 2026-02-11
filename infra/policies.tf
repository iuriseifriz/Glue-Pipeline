# policies.tf

# --------------------------------------------------
# Glue Service Role
# --------------------------------------------------
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

# --------------------------------------------------
# Step Functions Role
# --------------------------------------------------
resource "aws_iam_role" "sfn_role" {
  name = "step-functions-crypto-pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "states.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# --------------------------------------------------
# Step Functions Glue Jobs + Crawlers
# --------------------------------------------------
resource "aws_iam_policy" "sfn_glue_policy" {
  name = "step-functions-glue-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:StartJobRun",
          "glue:GetJobRun",
          "glue:GetJobRuns",
          "glue:GetJob",
          "glue:BatchStopJobRun",

          "glue:StartCrawler",
          "glue:GetCrawler"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_glue_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_glue_policy.arn
}

# --------------------------------------------------
# Step Functions Lambda
# --------------------------------------------------
resource "aws_iam_policy" "sfn_lambda_policy" {
  name = "step-functions-lambda-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "lambda:InvokeFunction"
        Resource = [
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:ingest-crypto-coins",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:start_glue_crawler",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:export_crypto_data_to_s3"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sfn_lambda_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.sfn_lambda_policy.arn
}

# --------------------------------------------------
# EventBridge Step Functions
# --------------------------------------------------
resource "aws_iam_policy" "eventbridge_start_sfn_policy" {
  name = "eventbridge-start-step-functions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "states:StartExecution"
        Resource = aws_sfn_state_machine.daily_crypto_pipeline.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eventbridge_start_sfn_attach" {
  role       = aws_iam_role.sfn_role.name
  policy_arn = aws_iam_policy.eventbridge_start_sfn_policy.arn
}

#end of this tf file
