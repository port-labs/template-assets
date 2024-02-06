terraform {
  required_providers {
    port-labs = {
      source  = "port-labs/port-labs"
      version = "0.10.4"
    }
  }
}

resource "port-labs_blueprint" "autoscaling_group" {
  title      = "Auto Scaling Group"
  icon       = "AWS"
  identifier = "awsAutoScalingGroup"

  properties {
    identifier = "desiredCapacity"
    type       = "number"
    title      = "Desired Capacity"
  }

  properties {
    identifier = "minimumCapacity"
    type       = "number"
    title      = "Minimum Capacity"
  }

  properties {
    identifier = "maximumCapacity"
    type       = "number"
    title      = "Maximum Capacity"
  }

  properties {
    identifier = "availabilityZones"
    type       = "array"
    title      = "Availability Zones"
  }

  properties {
    identifier = "healthCheckType"
    type       = "string"
    title      = "Health Check Type"
  }

  properties {
    identifier = "serviceRoleArn"
    type       = "string"
    title      = "Service Role ARN"
  }

  properties {
    identifier = "loadBalancerNames"
    type       = "array"
    title      = "Load Balancer Names"
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
