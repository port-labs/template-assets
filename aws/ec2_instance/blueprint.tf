terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "0.10.4"
    }
  }
}

resource "port-labs_blueprint" "ec2_instance" {
  title      = "EC2 Instance"
  icon       = "EC2"
  identifier = "ec2_instance"

  properties {
    identifier = "state"
    type       = "string"
    title      = "State"
    enum       = ["pending", "running", "shutting-down", "terminated", "stopping", "stopped"]
    enum_colors = {
          "pending" = "yellow",
          "running" = "green",
          "shutting-down" =  "pink",
          "terminated" =  "red",
          "stopping" = "orange",
          "stopped" = "purple"
        }
  }

  properties {
    identifier = "type"
    type       = "string"
    title      = "Instance Type"
  }

  properties {
    identifier = "publicIP"
    type       = "string"
    title      = "Public IP"
    format     = "ipv4"
  }

  properties {
    identifier = "privateIP"
    type       = "string"
    title      = "Private IP"
    format      = "ipv4"
  }

  properties {
    identifier = "availabilityZone"
    type       = "string"
    title      = "Availability Zone"
  }

  properties {
    identifier = "group"
    type       = "string"
    title      = "Group Name"
  }

  properties {
    identifier = "platform"
    type       = "string"
    title      = "Platform"
  }

  properties {
    identifier = "vpcId"
    type       = "string"
    title      = "VPC ID"
  }

  properties {
    identifier = "architecture"
    type       = "string"
    title      = "Architecture"
    enum       = ["i386", "x86_64", "arm64", "x86_64_mac", "arm64_mac"]
  }

  properties {
    identifier = "tags"
    type       = "array"
    title      = "Tags"
  }

}
