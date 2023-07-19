# Port AWS Exporter Module

This Terraform module deploys the Port AWS Exporter in your AWS account.

## Prerequisites

Before using this module, make sure you have completed the following prerequisites:

1. Install and configure the AWS Command Line Interface (CLI) on your local machine. 
   
   Refer to the [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for instructions.
2. Export the `PORT_CLIENT_ID` and `PORT_CLIENT_SECRET` environment variables with your [Port credentials](https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/api/#find-your-port-credentials). These credentials are necessary for the module to authenticate with Port.

   You can export the variables using the following commands in your terminal:

   ```bash
   export PORT_CLIENT_ID="your-port-client-id"
   export PORT_CLIENT_SECRET="your-port-client-secret"

## Variables
The following variables can be configured for this module:

- `stack_name`: The name of the CloudFormation stack.
- `secret_name`: secret name for Port credentials, in case you don't provide your own (custom_port_credentials_secret_arn).
- `create_bucket`: Flag to control if to create a new bucket for the exporter configuration or use an existing one.
- `bucket_name`: Bucket name for the exporter configuration. Lambda also use it to write intermediate temporary files.
- `config_s3_key` - Required s3 key name of the exporter configuration.
- `config_json`: Required file path / JSON formatted string of the exporter config.
- `function_name`: The name of the AWS Lambda function.
- `iam_policy_name`: Optional policy name for Port exporter's role
- `custom_port_credentials_secret_arn`: Optional Secret ARN for Port credentials (client id and client secret). 

   The secret value should be in the pattern: 
   
   {\"id\":\"<PORT_CLIENT_ID>\",\"clientSecret\":\"<PORT_CLIENT_SECRET>\"}
- `lambda_policy`: Optional path or JSON formatted string of the AWS policy json to grant to the Lambda function. If not passed, using the default exporter policies.
- `events_queue_name`: The name of the events queue to the Port exporter.
- `schedule_state`: schedule state - 'ENABLED' or 'DISABLED'. We recommend to enable it only after one successful run. Also make sure to update the schedule expression interval to be longer than the execution time.
- `schedule_expression`: Required schedule expression to define an event schedule for the exporter, according to the following [spec](https://docs.aws.amazon.com/lambda/latest/dg/services-cloudwatchevents-expressions.html).
       

## Exporter AWS policies 
By default, the exporter will be granted with the [default exporter policy](./defaults/policy.json).

If you wish to pass your custom [AWS policy](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies.html),

create a new policy file, and pass it's path to the `lambda_policy_file` variable.

### After Installation 
* You should see your the Port exporter in your CloudFormation Stacks with the name: 

   `serverlessrepo-<your_stack_name>`


* To remove the resources when they are no longer needed use the `destroy` command:

   ```bash
   terraform destroy --var-file=path/to/variables.tfvars
   ```


## Further Information
- See the [examples](./examples/) folder for examples about deploying the module and deploying EventBridge rules for your exporter.
- See the [AWS exporter docs](https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/aws/)
