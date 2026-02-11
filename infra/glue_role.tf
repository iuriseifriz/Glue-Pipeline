#glue_role.tf

resource "aws_iam_role" "glue_role" {
  name = "glue-role-crypto-pipeline"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

#end of this tf file
