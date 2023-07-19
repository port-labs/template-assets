variable "bucket_name" {
  description = "Required bucket name for the exporter configuration. Lambda also use it to write intermediate temporary files."
  type        = string
}

variable "secret_name" {
  description = "Required secret name for Port credentials, in case you don't provide your own (CustomPortCredentialsSecretARN)."
  type        = string
  default     = "port-credentials"
}

variable "iam_policy_name" {
  description = "Optional policy name for Port exporter's role"
  type = string
  default = "PortAWSExporterPolicy"
}

variable "custom_port_credentials_secret_arn" {
  description = "Optional Secret ARN for Port credentials (client id and client secret). The secret value should look like {\"id\":\"<PORT_CLIENT_ID>\",\"clientSecret\":\"<PORT_CLIENT_SECRET>\"}"
  type        = string
  default     = null
}

variable "config_json" {
  description = "Required file path / JSON formatted string of the exporter config"
  type        = string
}

variable "config_s3_key" {
  description = "Required s3 key name of the exporter config"
  type        = string
  default     = "config.json"
}

variable "lambda_policy" {
  description = "Optional path or JSON formatted string of the AWS policy json to grant to the Lambda function. If not passed, using the default exporter policies"
  type = string
}

variable "function_name" {
  description = "Required function name for the exporter Lambda."
  type        = string
  default     = "port-aws-exporter"
}

variable "stack_name" {
  description = "Required CloudFormation Stack name to the Port exporter"
  type        = string
  default     = "port-aws-exporter"
}

variable "events_queue_name" {
  description = "Required the name of the events queue to the Port exporter."
  type        = string
  default     = "port_exporter_events_queue"
}

variable "create_bucket" {
  type        = bool
  description = "Required flag to control if to create a new bucket for the exporter configuration or use an existing one."
  default     = true
}

variable "schedule_state" {
  type        = string
  description = "Required schedule state - 'ENABLED' or 'DISABLED'. We recommend to enable it only after one successful run. Also make sure to update the schedule expression interval to be longer than the execution time."
  default     = "DISABLED"
  validation {
    condition     = var.schedule_state == "ENABLED" || var.schedule_state == "DISABLED"
    error_message = "Schedule state must be 'ENABLED' or 'DISABLED'"
  }
}

variable "schedule_expression" {
  type        = string
  description = "Required schedule expression to define an event schedule for the exporter, according to following spec https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html."
  default = "rate(1 hour)"
}
