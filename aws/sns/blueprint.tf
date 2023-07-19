terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "~> 1.0.0"
    }
  }
}

resource "port_blueprint" "sns_topic" {

  title      = "SNS Topic"
  icon       = "SNS"
  identifier = "sns"

  properties {
    identifier = "link"
    type       = "string"
    format     = "url"
    title      = "Link"
  }

  properties {
    identifier = "fifoTopic"
    type       = "boolean"
    title      = "Fifo Topic"
  }

  properties {
    identifier = "subscriptions"
    type       = "array"
    title      = "Subscriptions"
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
  relations {
   target     = "sqs"
   title      = "SQS"
   identifier = "sqs"
   many       = true
   required   = false
 }

 provider = port-labs
}