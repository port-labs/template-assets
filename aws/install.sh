#!/bin/bash

###################################################
# Author: Tal Sabag
# Company: Port
# Date: 05/03/2023
# Version: v1.0
#
# Description:
#   This script is responsible for installing Port's AWS exporter using AWS CLI.
#   Documentation: https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/aws/)
# 
# Prerequisites(https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/aws/#prerequisites):
#   - AWS CLI must be installed
#   - AWS SAM CLI should be installed to view test run logs
#   - JQ must be installed
#   - The variables 'PORT_CLIENT_ID' and 'PORT_CLIENT_SECRET' must be passed to the script
# 
# Variables:
#   PORT_CLIENT_ID - Your Port organization Client ID (required)
#   PORT_CLIENT_SECRET - Your Port organization Client Secret (required)
#   EXPORTER_BUCKET_NAME - The bucket name to create for the exporter configuration (required)
#   EXPORTER_APP_NAME - The stack name of the application to create via AWS CloudFormation (default="port-aws-exporter")
#   EXPORTER_LAMBDA_NAME - The function name to create for the exporter Lambda. (default="port-aws-exporter")
#   EXPORTER_SECRET_NAME - The secret name to create for Port credentials (default="port-credentials")
#   EXPORTER_IAM_POLICY_NAME - The IAM policy name to create for Lambda execution role (default="PortAWSExporterPolicy")

###################################################

# Global variables
REPO_URL="https://raw.githubusercontent.com/port-labs/template-assets/main/aws"
PORT_API_URL="https://api.getport.io"

# Exporter installation variables
EXPORTER_APP_NAME=${EXPORTER_APP_NAME:-"port-aws-exporter"}
EXPORTER_LAMBDA_NAME=${EXPORTER_LAMBDA_NAME:-"port-aws-exporter"}
EXPORTER_SECRET_NAME=${EXPORTER_SECRET_NAME:-"port-credentials"}
EXPORTER_IAM_POLICY_NAME=${EXPORTER_IAM_POLICY_NAME:-"PortAWSExporterPolicy"}
EXPORTER_CF_EVENT_RULES_STACK_NAME=${EXPORTER_CF_EVENT_RULES_STACK_NAME:-"port-aws-exporter-event-rules"}

echo "Checking for prerequisites..."

# Checks if AWS CLI is installed and authenticated
if ! aws sts get-caller-identity &> /dev/null
then
    echo "aws command is not exists or no credentials found"
    exit
fi
echo "AWS CLI is valid!"

# Checks if JQ is installed
if ! command -v jq &> /dev/null
then
    echo "aws command is not exists or no credentials found"
    exit
fi
echo "JQ is valid!"

# Check if PORT_CLIENT_ID and PORT_CLIENT_SECRET variables are defined
if [[ -z "${PORT_CLIENT_ID}" ]] || [[ -z "${PORT_CLIENT_SECRET}" ]]
then
    echo "PORT_CLIENT_ID or PORT_CLIENT_SECRET variables are not defined"
    exit
fi

response_code=$(curl -w "%{http_code}" -s -o /dev/null -X POST "${PORT_API_URL}/v1/auth/access_token" \
    --header 'Content-Type: application/json' \
     --data-raw "{\"clientId\": \"${PORT_CLIENT_ID}\", \"clientSecret\": \"${PORT_CLIENT_SECRET}\"}")

# Check if PORT_CLIENT_ID and PORT_CLIENT_SECRET variables are valid
if [[ ${response_code} != "200" ]]; then
    echo "PORT_CLIENT_ID or PORT_CLIENT_SECRET are invalid, could not authenticate with Port API."
    exit
fi
echo "Port credentials are valid!"
echo ""

echo ""
echo "Beginning setup..."

function cleanup {
  rm -rf "${temp_dir}"
}
trap cleanup EXIT

# Create temporary folder
temp_dir=$(mktemp -d)


# Download config.json file into temporary folder
curl -s "${REPO_URL}/config.json" -o "${temp_dir}/config.json" || exit 1
curl -s "${REPO_URL}/policy.json" -o "${temp_dir}/policy.json" || exit 1
curl -s "${REPO_URL}/parameters.json" -o "${temp_dir}/parameters.json" || exit 1
curl -s "${REPO_URL}/event_rules.yaml" -o "${temp_dir}/event_rules.yaml" || exit 1

echo ""
echo "Creating IAM Policy"
if ! aws iam create-policy --policy-name "${EXPORTER_IAM_POLICY_NAME}" --policy-document "file://${temp_dir}/policy.json"
then
    echo "Skip policy creation..."
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r ".Account")
EXPORTER_IAM_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy\/${EXPORTER_IAM_POLICY_NAME}"

echo ""
echo "Preparing parameters json file"

sed -i.backup \
-e "s/\<EXPORTER_BUCKET_NAME>/${EXPORTER_BUCKET_NAME}/" \
-e "s/\<EXPORTER_LAMBDA_NAME>/${EXPORTER_LAMBDA_NAME}/" \
-e "s/\<EXPORTER_SECRET_NAME>/${EXPORTER_SECRET_NAME}/" \
-e "s/\<EXPORTER_IAM_POLICY_ARN>/${EXPORTER_IAM_POLICY_ARN}/" \
"${temp_dir}/parameters.json"

cat "${temp_dir}/parameters.json"

echo ""
echo "Deploying Port's AWS exporter application"

CHANGE_SET_ID=$(aws serverlessrepo create-cloud-formation-change-set \
--application-id arn:aws:serverlessrepo:eu-west-1:185657066287:applications/port-aws-exporter \
--stack-name "${EXPORTER_APP_NAME}" --capabilities CAPABILITY_IAM CAPABILITY_RESOURCE_POLICY \
--parameter-overrides "file://${temp_dir}/parameters.json" | jq -r ".ChangeSetId")

aws cloudformation wait change-set-create-complete --change-set-name "${CHANGE_SET_ID}"

aws cloudformation execute-change-set --change-set-name "${CHANGE_SET_ID}"

aws cloudformation wait stack-create-complete --stack-name "serverlessrepo-${EXPORTER_APP_NAME}"

echo ""
echo "Uploading config.json to S3 bucket"

aws s3api wait bucket-exists --bucket "${EXPORTER_BUCKET_NAME}"

aws s3api put-object --bucket "${EXPORTER_BUCKET_NAME}" --key "config.json" --body "${temp_dir}/config.json" || exit 1

echo ""
echo "Updating Port credentials secret"

aws secretsmanager put-secret-value --secret-id "${EXPORTER_SECRET_NAME}" --secret-string "{\"id\":\"${PORT_CLIENT_ID}\",\"clientSecret\":\"${PORT_CLIENT_SECRET}\"}" || exit 1

echo ""
echo "Creating CloudFormation of event rules for real-time updates"

aws cloudformation deploy --template-file "${temp_dir}/event_rules.yaml" --stack-name "${EXPORTER_CF_EVENT_RULES_STACK_NAME}"

echo ""
echo "Finished installation!"

echo ""
echo "Run first test"

aws lambda invoke --function-name "${EXPORTER_LAMBDA_NAME}" --invocation-type "Event" --payload "{}" "${temp_dir}/outfile" || exit 1

# Checks if AWS SAM CLI is installed
if ! command -v sam &> /dev/null
then
    echo "sam command is not exists"
    exit
fi

echo ""
echo "Tail exporter's lambda logs, press CTRL+C to break"

sam logs --stack-name "serverlessrepo-${EXPORTER_APP_NAME}" --tail
