data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

module "port_aws_exporter" {
  source = "git::https://github.com/port-labs/terraform-aws-port-exporter.git"
  config_json   = "config.json"
  lambda_policy = "../defaults/policy.json"
  bucket_name = "port-aws-exporter-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"
}