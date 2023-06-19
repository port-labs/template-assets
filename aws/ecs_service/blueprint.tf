terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "0.10.4"
    }
  }
}

resource "port-labs_blueprint" "ecs_service" {
  title      = "ECS Service"
  icon       = "Service"
  identifier = "ecs_service"

  properties {
    identifier = "link"
    type       = "string"
    format     = "url"
    title      = "Link"
  }

  properties {
    identifier = "desiredCount"
    type       = "number"
    title      = "Desired Count"
  }

  properties {
    identifier = "cluster"
    type       = "string"
    title      = "Cluster"
  }

  properties {
    identifier = "taskDefinition"
    type       = "string"
    title      = "Task Definition"
  }

  properties {
    identifier = "launchType"
    type       = "string"
    enum       = ["EC2", "FARGATE", "EXTERNAL"]
    title      = "Launch Type"
  }

  properties {
    identifier = "schedulingStrategy"
    type       = "string"
    enum       = ["REPLICA", "DAEMON"]
    title      = "Scheduling Strategy"
  }

  properties {
    identifier = "loadBalancers"
    type       = "array"
    title      = "Load Balancers"
  }

  properties {
    identifier = "securityGroups"
    type       = "array"
    title      = "Security Groups"
  }

  properties {
    identifier = "subnets"
    type       = "array"
    title      = "Subnets"
  }

  properties {
    identifier = "iamRole"
    type       = "string"
    format     = "url"
    title      = "IAM Role"
    icon       = "Unlock"
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
}

output "exporter_config" {
  value = jsondecode(file("${path.module}/config.json"))
}

output "iam_policy" {
  value = jsondecode(file("${path.module}/policy.json"))
}

