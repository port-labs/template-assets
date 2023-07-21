# Configure template assets with terraform

Template assets is for ingesting cloud resources into port

## Terraform cloud variables

AWS_DEFAULT_REGION = us-east-1
PORT_CLIENT_ID in port, click on the ... menu at the top right and select credentials
PORT_CLIENT_SECRET
resources = ["ecs_service", "rds_db_instance", "load_balancer", "vpc", "hosted_zone", "ecr"] select the HCL option
TFC_AWS_PROVIDER_AUTH = true
TFC_AWS_RUN_ROLE_ARN = arn:aws:iam::036438099243:role/TerraformOIDC be sure to update the account number

## Terraform cloud settings

Terraform Working Directory: aws
branch: main

## Terraform OIDC role config

This project was configured with AWS OIDC.  

https://aws.amazon.com/blogs/apn/simplify-and-secure-terraform-workflows-on-aws-with-dynamic-provider-credentials/  

### Trust relationship in role `TerraformOIDC`  

Be sure to update the account number in this policy.

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::036438099243:oidc-provider/app.terraform.io"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "app.terraform.io:aud": "aws.workload.identity"
                },
                "StringLike": {
                    "app.terraform.io:sub": "organization:AutoFi:project:*:workspace:*:run_phase:*"
                }
            }
        }
    ]
}
```

### Attach policies to `TerraformOIDC` role

```
AdministratorAccess
``` 
