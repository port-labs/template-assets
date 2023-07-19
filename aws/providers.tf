# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 5.8.0"
#     }
#   }
# }

provider "aws" {
  #   region = var.region

  default_tags {
    tags = {
      CostCenter = "Port"
    }
  }
}
