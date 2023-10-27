terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "0.10.4"
    }
  }
}

resource "port-labs_blueprint" "eks_service" {
  title      = "EKS Cluster"
  icon       = "Service"
  identifier = "eks"

  properties {
    identifier = "name"
    type       = "string"
    title      = "Name"
  }

  properties {
    identifier = "roleArn"
    type       = "string"
    title      = "Role ARN"
  }

  properties {
    identifier = "tags"
    type       = "array"
    title      = "Tags"
  }

  properties {
      identifier = "version"
      type       = "string"
      title      = "Version"
    }

  relations {
       target     = "region"
       title      = "Region"
       identifier = "region"
       many       = false
       required   = false
     }
}
