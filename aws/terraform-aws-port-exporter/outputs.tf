output "exporter_policy_arn" {
  value = aws_iam_policy.port_aws_exporter_policy.arn
}

output "config_bucket_name" {
  value = aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack.outputs.ConfigBucketName
}

output "lambda_function_arn" {
  value = aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack.outputs.LambdaFunctionARN
}

output "lambda_function_iam_role_arn" {
  value = aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack.outputs.LambdaFunctionIamRoleARN
}

output "port_credentials_secret_arn" {
  value = aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack.outputs.PortCredentialsSecretARN
}

output "events_queue_arn" {
  value = aws_serverlessapplicationrepository_cloudformation_stack.port_aws_exporter_stack.outputs.EventsQueueARN
}

output "config_file_object" {
  value = aws_s3_object.config_file_object.id
}