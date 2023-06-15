terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {

  resources = [
    "ecs_service",
    "lambda",
    "sns",
    "sqs",
    "s3_bucket",
    "rds_db_instance",
    "dynamodb_table"
  ]

  combined_config = <<EOF
 {
   "resources": [
     ${join(",", [for resource in local.resources : file("./${resource}/config.json")])}
   ]
 }
 EOF

  combined_event_rules = <<-EOF
AWSTemplateFormatVersion: 2010-09-09
Description: The template used to create event rules for the Port AWS exporter.
Parameters:
  PortAWSExporterStackName:
    Description: Name of the Port AWS exporter stack name
    Type: String
    MinLength: 1
    MaxLength: 255
    AllowedPattern: ^[a-zA-Z][-a-zA-Z0-9]*$
    Default: serverlessrepo-port-aws-exporter
Resources:
${join("\n", [for resource in local.resources : "  ${indent(2, file("./${resource}/event_rule.yaml"))}"])}
  EOF

  combined_policies = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": ${jsonencode(flatten([for resource in local.resources : jsondecode(file("./${resource}/policy.json"))]))},
     "Resource": "*"
   }
 ]
}
EOF

  bucket_name = "port-aws-exporter-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}

resource "local_file" "configuration" {
  content  = local.combined_config
  filename = "config.json"
}

resource "local_file" "policy" {
  content  = local.combined_policies
  filename = "policy.json"
}

resource "local_file" "event_rules" {
  content  = local.combined_event_rules
  filename = "event_rules.yaml"
}

# Deploy the AWS exporter application
module "port_aws_exporter" {
  source = "git::https://github.com/port-labs/terraform-aws-port-exporter.git"
  config_json   = local.combined_config
  lambda_policy = local.combined_policies
  bucket_name = local.bucket_name
}

resource "aws_cloudformation_stack" "port-aws-exporter-event-rules" {
  name = "port-aws-exporter-event-rules"

  parameters = {
    PortAWSExporterStackName = "serverlessrepo-port-aws-exporter"
  }

  template_body = local.combined_event_rules
  depends_on = [module.port_aws_exporter]
}
