# eventbridge.tf

resource "aws_cloudwatch_event_rule" "daily_schedule" {
  name                = "daily_crypto_pipeline_schedule"
  schedule_expression = "cron(0 2 * * ? *)" # 02:00 UTC todo dia
}

resource "aws_cloudwatch_event_target" "invoke_sfn" {
  rule     = aws_cloudwatch_event_rule.daily_schedule.name
  arn      = aws_sfn_state_machine.daily_crypto_pipeline.arn
  role_arn = aws_iam_role.sfn_role.arn
}
#end of this tf file
