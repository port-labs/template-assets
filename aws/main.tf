terraform {
  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.4.0"
    }
  }
}

data "aws_caller_identity" "current" {}

# To deploy the exporter on a region different then the AWS cli region, use this block
# provider "aws" {
# region = "us-east-1"
# }

data "aws_region" "current" {}

# Create the AWS blueprints
module "port_blueprints_creator" {
  source = "./aws_blueprints_template"
  resources = var.resources
}

locals {
  bucket_name = "port-aws-exporter-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"

  # Generates the config.json
  combined_config = <<EOF
 {
   "resources": [
     ${join(",", [for resource in var.resources : file("./${resource}/config.json")])}
   ]
 }
 EOF

  # Generates the Event rules
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
${join("\n", [for resource in var.resources : "  ${indent(2, file("./${resource}/event_rule.yaml"))}"])}
  EOF

  # Generates the Lambda policy json
  combined_policies = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Effect": "Allow",
     "Action": ${jsonencode(flatten([for resource in var.resources : jsondecode(file("./${resource}/policy.json"))]))},
     "Resource": "*"
   }
 ]
}
EOF
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
  source  = "port-labs/port-exporter/aws"
  version = "0.1.1"
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

## Invoke the exporter lambda function at the end of the deployment
resource "aws_lambda_invocation" "first_exporter_invocation" {
  function_name = module.port_aws_exporter.lambda_function_arn
  count = var.invoke_function ? 1 : 0
  input = jsonencode({})
}
