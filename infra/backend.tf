# backend.tf

terraform {
  backend "s3" {
    bucket  = "tf-state-glue-pipeline-381492258425"
    key     = "glue-pipeline/terraform.tfstate"
    region  = "us-east-1"
    profile = "iam-glue-pipeline"
  }
}

#end of this tf file
