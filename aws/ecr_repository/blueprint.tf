terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "0.10.4"
    }
  }
}

resource "port-labs_blueprint" "ecr_repository" {
  title      = "ECR Repository"
  icon       = "Service"
  identifier = "ecr_repository"

  properties {
    identifier = "link"
    type       = "string"
    format     = "url"
    title      = "Link"
  }

  properties {
    identifier = "imageTagMutability"
    type       = "string"
    title      = "Image Tag Mutability"
  }

  properties {
    identifier = "repositoryArn"
    type       = "string"
    title      = "Repository ARN"
  }

  properties {
    identifier = "repositoryUri"
    type       = "string"
    title      = "Repository URI"
  }

  properties {
    identifier = "scanningConfiguration"
    type       = "object"
    title      = "Scanning Configuration"
  }

  properties {
    identifier = "encryptionConfiguration"
    type       = "object"
    title      = "Encryption Configuration"
  }

  properties {
    identifier = "lifecyclePolicy"
    type       = "object"
    title      = "Lifecycle Policy"
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
