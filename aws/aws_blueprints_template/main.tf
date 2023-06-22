terraform {
  required_providers {
    port-labs = {
          source = "port-labs/port-labs"
          version = "0.10.4"
    }
  }
}

data "aws_region" "current" {}

# Create Blueprints
resource "port-labs_blueprint" "region" {
  title      = "Region"
  icon       = "AWS"
  identifier = "region"

  properties {
    title = "Link"
    identifier = "link"
    type = "string"
    format = "url"
  }
}

resource "port-labs_entity" "current_region" {
  identifier = data.aws_region.current.name
  title     = data.aws_region.current.name
  blueprint = port-labs_blueprint.region.identifier
  properties {
    name  = "link"
    value = "https://${data.aws_region.current.name}.console.aws.amazon.com/"
  }
}


module "port_dynamodb_table" {
  source = "../dynamodb_table"
  count = contains(var.resources, "dynamodb_table") ? 1 : 0
  depends_on = [port-labs_blueprint.region]
}

module "port_ecs_service" {
  source = "../ecs_service"
  count = contains(var.resources, "ecs_service") ? 1 : 0
  depends_on = [port-labs_blueprint.region]
}

module "port_lambda_function" {
  source = "../lambda"
  count = contains(var.resources, "lambda") ? 1 : 0
  depends_on = [port-labs_blueprint.region]
}

module "port_rds_db_instance" {
  source = "../rds_db_instance"
  count = contains(var.resources, "rds_db_instance") ? 1 : 0
  depends_on = [port-labs_blueprint.region]
}

module "port_s3_bucket" {
  source = "../s3_bucket"
  count = contains(var.resources, "s3_bucket") ? 1 : 0
  depends_on = [port-labs_blueprint.region]
}

module "port_sqs" {
  source = "../sqs"
  count = contains(var.resources, "sqs") ? 1 : 0
  depends_on = [port-labs_blueprint.region]
}

module "port_sns" {
  source = "../sns"
  count = contains(var.resources, "sns") ? 1 : 0
  depends_on = [port-labs_blueprint.region, module.port_sqs]
}

