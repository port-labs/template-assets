terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "0.10.4"
    }
  }
}

resource "port-labs_blueprint" "elasticache_cluster" {
  title      = "Elasticache Cluster"
  icon       = "AWS"
  identifier = "elasticache_cluster"

  properties {
    identifier = "status"
    type       = "string"
    title      = "Status"
  }

  properties {
    identifier = "engine"
    type       = "string"
    title      = "Engine"
  }

  properties {
    identifier = "engineVersion"
    type       = "string"
    title      = "Engine Version"
  }

  properties {
    identifier = "preferredAvailabilityZone"
    type       = "string"
    title      = "Preferred Availability Zone"
  }

  properties {
    identifier = "createdDate"
    type       = "string"
    format     = "date-time"
    title      = "Created Date"
  }

  properties {
    identifier = "arn"
    type       = "string"
    title      = "ARN"
  }

  properties {
    identifier = "transitEncryptionEnabled"
    type       = "boolean"
    title      = "Transit Encryption Enabled"
  }

  properties {
    identifier = "atRestEncryptionEnabled"
    type       = "boolean"
    title      = "At Rest Encryption Enabled"
  }

  properties {
    identifier = "nodeType"
    type       = "string"
    title      = "Node Type"
  }
  
  properties {
    identifier = "link"
    type       = "string"
    title      = "Link"
    format     = "url"
  }

  properties {
    identifier = "subnetGroupName"
    type       = "string"
    title      = "Subnet Group Name"
  }

  properties {
    identifier = "numNodes"
    type       = "number"
    title      = "Number of Nodes"
  }

  properties {
    identifier = "securityGroups"
    type       = "array"
    title      = "Security Groups"
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
