# terraform {
#   required_providers {
#     port-labs = {
#       source  = "port-labs/port-labs"
#       version = "0.10.4"
#     }
#   }
# } 

resource "port-labs_blueprint" "sqs_queue" {
  title      = "SQS Queue"
  icon       = "AWS"
  identifier = "sqs"

  properties {
    identifier = "link"
    type       = "string"
    format     = "url"
    title      = "Link"
  }

  properties {
    identifier = "fifoQueue"
    type       = "boolean"
    title      = "Fifo Queue"
  }

  properties {
    identifier = "visibilityTimeout"
    type       = "number"
    title      = "Visibility Timeout"
  }

  properties {
    identifier = "messageRetentionPeriod"
    type       = "number"
    title      = "Message Retention Period"
  }

  properties {
    identifier = "maximumMessageSize"
    type       = "number"
    title      = "Maximum Message Size"
  }

  properties {
    identifier = "receiveMessageWaitTimeSeconds"
    type       = "number"
    title      = "Receive Message Wait Time Seconds"
  }

  properties {
    identifier = "delaySeconds"
    type       = "number"
    title      = "Delay Seconds"
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