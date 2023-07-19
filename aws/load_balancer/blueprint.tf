# terraform {
#   required_providers {
#     port-labs = {
#       source  = "port-labs/port-labs"
#       version = "0.10.4"
#     }
#   }
# }

resource "port-labs_blueprint" "loadBalancer" {
  title      = "Load Balancer"
  icon       = "AWS"
  identifier = "loadBalancer"

  properties {
    identifier = "state"
    type       = "string"
    title      = "State"
    enum       = ["provisioning", "active", "failed", "active_impaired"]
    enum_colors = {
          "provisioning" = "yellow",
          "active" = "green",
          "failed" =  "red",
          "active_impaired" =  "orange"
        }
  }

  properties {
    identifier = "type"
    type       = "string"
    title      = "Type"
    enum       = ["application", "network", "gateway"]
  }

  properties {
    identifier = "scheme"
    type       = "string"
    title      = "Scheme"
  }

  properties {
    identifier = "vpcId"
    type       = "string"
    title      = "VPC ID"
  }

  properties {
    identifier = "link"
    type       = "string"
    title      = "Link"
    format     = "url"
  }

  properties {
    identifier = "availabilityZones"
    type       = "array"
    title      = "Availability Zones"
  }

  properties {
    identifier = "dnsName"
    type       = "string"
    title      = "DNS Name"
  }

  properties {
    identifier = "arn"
    type       = "string"
    title      = "ARN"
  }

  properties {
    identifier = "securityGroup"
    type       = "array"
    title      = "Security Group"
  }

  properties {
    identifier = "listeners"
    type       = "array"
    title      = "Listeners"
  }

  properties {
    identifier = "attributes"
    type       = "array"
    title      = "Attributes"
  }

  properties {
    identifier = "tags"
    type       = "array"
    title      = "Tags"
  }
  
  relations {
      target     = "region"
      title      = "Region"
      identifier = "region"
      many       = false
      required   = false
    }

}
