#main.tf

data "aws_caller_identity" "current" {}

// lock the terraform version to keep it stable
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

//just to make sure im using us east 1
provider "aws" {
  profile = "iam-glue-pipeline"
  region  = "us-east-1"
}

//debug aws terraform
output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_arn" {
  value = data.aws_caller_identity.current.arn
}
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

#end of this tf file
