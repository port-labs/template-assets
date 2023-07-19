# terraform {
#   required_providers {
#     port-labs = {
#       source  = "port-labs/port-labs"
#       version = "0.10.4"
#     }
#   }
# }

resource "port-labs_blueprint" "dynamodb_table" {
  title      = "DynamoDB Table"
  icon       = "SQL"
  identifier = "dynamodb_table"

  properties {
    identifier = "link"
    type       = "string"
    title      = "Link"
    format     = "url"
  }

  properties {
    identifier = "writeCapacityUnits"
    type       = "number"
    title      = "Write Capacity Units"
  }

  properties {
    identifier = "readCapacityUnits"
    type       = "number"
    title      = "Read Capacity Units"
  }

  properties {
    identifier = "deletionProtectionEnabled"
    type       = "boolean"
    title      = "Deletion Protection Enabled"
  }

  properties {
    identifier = "pointInTimeRecoveryEnabled"
    type       = "boolean"
    title      = "Point In Time Recovery Enabled"
  }

  properties {
    identifier = "ttlEnabled"
    type       = "boolean"
    title      = "TTL Enabled"
  }

  properties {
    identifier = "ttlAttributeName"
    type       = "string"
    title      = "TTL Attribute Name"
  }

  properties {
    identifier = "billingMode"
    type       = "string"
    title      = "Billing Mode"
    enum       = ["PAY_PER_REQUEST", "PROVISIONED"]
  }

  properties {
    identifier = "attributeDefinitions"
    type       = "array"
    title      = "Attribute Definitions"
  }

  properties {
    identifier = "keySchema"
    type       = "array"
    title      = "Key Schema"
  }

  properties {
    identifier = "tags"
    type       = "array"
    title      = "Tags"
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
