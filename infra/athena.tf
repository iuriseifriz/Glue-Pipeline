# athena.tf 

#-------------------------------------------------------------------------------------------------
# ATHENA WORKGROUP
# -------------------------------------------------------------------------------------------------
resource "aws_athena_workgroup" "primary" {
  name = "crypto-athena"

  configuration {
    enforce_workgroup_configuration = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.datalake.bucket}/athena/results/"
      encryption_configuration {
        encryption_option = "SSE_S3"
      }
    }
  }

  description = "Workgroup Athena para consultar dados do Crypto Data Lake"
  state       = "ENABLED"
}

# -------------------------------------------------------------------------------------------------
# Athena Database (opcional, para referência direta no Terraform)
# -------------------------------------------------------------------------------------------------
resource "aws_athena_database" "crypto" {
  name   = aws_glue_catalog_database.crypto.name
  bucket = aws_s3_bucket.datalake.bucket
}

#end of this tf file
