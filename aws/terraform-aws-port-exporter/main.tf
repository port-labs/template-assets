
# Checks whether the policy and config are files or raw json
locals {
  policy = can(jsondecode(var.lambda_policy)) ? var.lambda_policy : file(var.lambda_policy)
  config = can(jsondecode(var.config_json)) ? var.config_json : file(var.config_json)
}

resource "aws_iam_policy" "port_aws_exporter_policy" {
  name   = var.iam_policy_name
  policy = local.policy
}

resource "aws_serverlessapplicationrepository_cloudformation_stack" "port_aws_exporter_stack" {
  tags = {
      applyId = uuid()
  }

  name           = var.stack_name
  application_id = "arn:aws:serverlessrepo:eu-west-1:185657066287:applications/port-aws-exporter"
  capabilities   = [
    "CAPABILITY_IAM",
    "CAPABILITY_RESOURCE_POLICY",
  ]
  parameters = {
    "CustomIAMPolicyARN"             = aws_iam_policy.port_aws_exporter_policy.arn
    "CustomPortCredentialsSecretARN" = var.custom_port_credentials_secret_arn != null ? var.custom_port_credentials_secret_arn : ""
    "SecretName"                     = var.custom_port_credentials_secret_arn == null ? var.secret_name : ""
    "CreateBucket"                   = var.create_bucket
    "BucketName"                     = var.bucket_name
    "ConfigJsonFileKey"              = var.config_s3_key
    "FunctionName"                   = var.function_name
    "ScheduleExpression"             = var.schedule_expression
    "ScheduleState"                  = var.schedule_state
  }
}

## Get the Port credentials from the environment variables
data "env_variable" "port_client_id" {
  name = "PORT_CLIENT_ID"
}
data "env_variable" "port_client_secret" {
  name = "PORT_CLIENT_SECRET"
}

resource "aws_secretsmanager_secret_version" "port_credentials_secret_version" {
  secret_id     = aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack.outputs.PortCredentialsSecretARN
  secret_string = jsonencode({
    id           = data.env_variable.port_client_id.value
    clientSecret = data.env_variable.port_client_secret.value
  })
  depends_on = [aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack]
}

data "jsonschema_validator" "port_config_validation" {
  document = local.config
  schema   = "${path.module}/defaults/config_schema.json"
}

resource "aws_s3_object" "config_file_object" {
  bucket       = aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack.outputs.ConfigBucketName
  key          = var.config_s3_key
  content_type = "application/json"
  content      = local.config
  depends_on   = [aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack]
}