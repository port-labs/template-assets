terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "0.10.4"
    }
  }
}

resource "port-labs_blueprint" "iam_user" {
  title      = "IAM User"
  icon       = "AWS"
  identifier = "iam_user"

  properties {
    identifier = "link"
    type       = "string"
    format     = "url"
    title      = "Link"
  }

  properties {
    identifier = "description"
    type       = "string"
    title      = "Description"
  }

  properties {
    identifier = "arn"
    type       = "string"
    title      = "ARN"
  }

  relations {
       target     = "region"
       title      = "Region"
       identifier = "region"
       many       = false
       required   = false
   }

  relations {
       target     = "role"
       title      = "Role"
       identifier = "role"
       many       = true
       required   = false
   }
}