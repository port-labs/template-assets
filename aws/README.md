# Configure template assets with terraform

Template assets is for ingesting cloud resources into port

## Terraform role config

This project was configured with AWS OIDC.  

https://aws.amazon.com/blogs/apn/simplify-and-secure-terraform-workflows-on-aws-with-dynamic-provider-credentials/  

Trust relationship in role `TerraformOIDC`  

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

# Attach policies to `TerraformOIDC` role

```
AWSCloudFormationFullAccess
IAMFullAccess 
AdministratorAccess
``` 

Create and attach `PortTemplateAssets`

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "CloudControlListActions",
            "Effect": "Allow",
            "Action": [
                "cloudformation:ListResources",
                "cloudformation:GetResource",
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "cloudformation:CreateChangeSet",
                "iam:ListPolicyVersions",
                "iam:DeletePolicyVersion",
                "lambda:InvokeFunction",
                "lambda:PublishLayerVersion",
                "s3:*",
                "secretsmanager:PutSecretValue",
                "serverlessrepo:CreateCloudFormationChangeSet",
                "serverlessrepo:GetApplication",
                "cloudformation:GetTemplateSummary",
                "iam:CreatePolicy",
                "iam:CreatePolicyVersion",
                "iam:ListPolicyVersions"
            ],
            "Resource": "*"
        }
    ]
}
```

delete
PortCredentialsSecret
s3
Port policy
