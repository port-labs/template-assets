# terraform {
#   required_providers {
#     port-labs = {
#       source  = "port-labs/port-labs"
#       version = "0.10.4"
#     }
#   }
# }

resource "port-labs_blueprint" "lambda_function" {
  title      = "Lambda"
  icon       = "Lambda"
  identifier = "lambda"

  properties {
    identifier = "link"
    type       = "string"
    title      = "Link"
    format     = "url"
  }

  properties {
    identifier = "description"
    type       = "string"
    title      = "Description"
  }

  properties {
    identifier = "memorySize"
    type       = "number"
    title      = "Memory Size"
  }

  properties {
    identifier = "ephemeralStorageSize"
    type       = "number"
    title      = "Ephemeral Storage Size"
  }

  properties {
    identifier = "timeout"
    type       = "number"
    title      = "Timeout"
  }

  properties {
    identifier = "runtime"
    type       = "string"
    title      = "Runtime"
  }

  properties {
    identifier = "packageType"
    type       = "string"
    title      = "Package Type"
    enum       = ["Image", "Zip"]
  }

  properties {
    identifier = "environment"
    type       = "object"
    title      = "Environment"
  }

  properties {
    identifier = "architectures"
    type       = "array"
    title      = "Architectures"
  }

  properties {
    identifier = "layers"
    type       = "array"
    title      = "Layers"
  }

  properties {
    identifier = "tags"
    type       = "array"
    title      = "Tags"
  }

  properties {
    identifier = "iamRole"
    type       = "string"
    title      = "IAM Role"
    format     = "url"
    icon       = "Unlock"
  }

  properties {
    identifier = "arn"
    type       = "string"
    title      = "ARN"
  }

  relations {
       target     = "region"
       title      = "Region"
       identifier = "region"
       many       = false
       required   = false
     }
}
