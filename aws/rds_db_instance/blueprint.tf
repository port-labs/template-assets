terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "~> 1.0.0"
    }
  }
}

resource "port-labs_blueprint" "rds_db_instance" {
  title      = "RDS DB Instance"
  icon       = "SQL"
  identifier = "rds_db_instance"

  properties {
    identifier = "link"
    type       = "string"
    title      = "Link"
    format     = "url"
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
    identifier = "storageType"
    type       = "string"
    title      = "Storage Type"
    enum       = ["gp2", "gp3", "io1", "standard", "aurora"]
  }

  properties {
    identifier = "dbInstanceClass"
    type       = "string"
    title      = "DB Instance Class"
  }

  properties {
    identifier = "availabilityZone"
    type       = "string"
    title      = "Availability Zone"
  }

  properties {
    identifier = "dbParameterGroup"
    type       = "string"
    title      = "DB Parameter Group"
  }

  properties {
    identifier = "optionGroup"
    type       = "string"
    title      = "Option Group"
  }

  properties {
    identifier = "dbSubnetGroup"
    type       = "string"
    title      = "DB Subnet Group"
  }

  properties {
    identifier = "masterUsername"
    type       = "string"
    title      = "Master Username"
  }

  properties {
    identifier = "allocatedStorage"
    type       = "string"
    title      = "Allocated Storage"
  }

  properties {
    identifier = "maxAllocatedStorage"
    type       = "number"
    title      = "Max Allocated Storage"
  }

  properties {
    identifier = "backupRetentionPeriod"
    type       = "number"
    title      = "Backup Retention Period"
  }

  properties {
    identifier = "monitoringInterval"
    type       = "number"
    title      = "Monitoring Interval"
    enum       = [0, 1, 5, 10, 15, 30, 60]
  }

  properties {
    identifier = "multiAZ"
    type       = "boolean"
    title      = "Multi AZ"
  }

  properties {
    identifier = "storageEncrypted"
    type       = "boolean"
    title      = "Storage Encrypted"
  }

  properties {
    identifier = "enablePerformanceInsights"
    type       = "boolean"
    title      = "Enable Performance Insights"
  }

  properties {
    identifier = "autoMinorVersionUpgrade"
    type       = "boolean"
    title      = "Auto Minor Version Upgrade"
  }

  properties {
    identifier = "deletionProtection"
    type       = "boolean"
    title      = "Deletion Protection"
  }

  properties {
    identifier = "publiclyAccessible"
    type       = "boolean"
    title      = "Publicly Accessible"
  }

  properties {
    identifier = "certificateValidTill"
    type       = "string"
    title      = "Certificate Valid Till"
    format     = "date-time"
  }

  properties {
    identifier = "certificateCA"
    type       = "string"
    title      = "Certificate CA"
  }

  properties {
    identifier = "preferredBackupWindow"
    type       = "string"
    title      = "Preferred Backup Window"
  }

  properties {
    identifier = "preferredMaintenanceWindow"
    type       = "string"
    title      = "Preferred Maintenance Window"
  }

  properties {
    identifier = "endpoint"
    type       = "object"
    title      = "Endpoint"
  }

  properties {
    identifier = "tags"
    type       = "array"
    title      = "Tags"
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

     provider = port-labs
}
