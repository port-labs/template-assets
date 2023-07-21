terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "~> 1.0.0"
    }
  }
}

data "aws_region" "current" {}

# Create Blueprints
# resource "port_blueprint" "region" {
#   title      = "Port AWS Region"
#   icon       = "AWS"
#   identifier = "port_aws_region"

#   properties = {
#     string_props = {
#       title      = "Link"
#       identifier = "link"
#       type       = "string"
#       format     = "url"
#     }
#   }

#   provider = port-labs
# }

# resource "port_entity" "current_region" {
#   identifier = data.aws_region.current.name
#   title      = data.aws_region.current.name
#   blueprint  = port_blueprint.region.identifier

#   properties = {
#     string_props = {
#       name  = "link"
#       value = "https://${data.aws_region.current.name}.console.aws.amazon.com/"
#     }
#   }

#   provider = port-labs
# }


# module "port_dynamodb_table" {
#   source     = "../dynamodb_table"
#   count      = contains(var.resources, "dynamodb_table") ? 1 : 0
#   depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_ecs_service" {
#   source     = "../ecs_service"
#   count      = contains(var.resources, "ecs_service") ? 1 : 0
#   depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_lambda_function" {
#   source     = "../lambda"
#   count      = contains(var.resources, "lambda") ? 1 : 0
#   depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_rds_db_instance" {
#   source     = "../rds_db_instance"
#   count      = contains(var.resources, "rds_db_instance") ? 1 : 0
#   depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_s3_bucket" {
#   source     = "../s3_bucket"
#   count      = contains(var.resources, "s3_bucket") ? 1 : 0
#   depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_sqs" {
#   source     = "../sqs"
#   count      = contains(var.resources, "sqs") ? 1 : 0
#   depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_sns" {
#   source     = "../sns"
#   count      = contains(var.resources, "sns") ? 1 : 0
#   depends_on = [port_blueprint.region, module.port_sqs]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_ec2_instance" {
#   source     = "../ec2_instance"
#   count      = contains(var.resources, "ec2_instance") ? 1 : 0
#   # depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }

# module "port_load_balancer" {
#   source     = "../load_balancer"
#   count      = contains(var.resources, "load_balancer") ? 1 : 0
#   depends_on = [port_blueprint.region]

#   providers = {
#     port-labs = port-labs
#   }
# }
