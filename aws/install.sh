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
#   - The variables 'PORT_CLIENT_ID' and 'PORT_CLIENT_SECRET' must be passed to the script
#   - JQ must be installed
#   - AWS CLI must be installed
#   - AWS SAM CLI should be installed to view live test run logs
#
# Variables:
#   PORT_CLIENT_ID - Your Port organization Client ID (required)
#   PORT_CLIENT_SECRET - Your Port organization Client Secret (required)
#   EXPORTER_APP_NAME - The stack name of the application to create via AWS CloudFormation (default="port-aws-exporter")
#   EXPORTER_BUCKET_NAME - The bucket name to create for the exporter configuration (default="port-aws-exporter-{AWS_ACCOUNT_ID}-{AWS_REGION}")
#   EXPORTER_LAMBDA_NAME - The function name to create for the exporter Lambda. (default="port-aws-exporter")
#   EXPORTER_SECRET_NAME - The secret name to create for Port credentials (default="port-credentials")
#   EXPORTER_IAM_POLICY_NAME - The IAM policy name to create for Lambda execution role (default="PortAWSExporterPolicy")

###################################################

# Global variables
REPO_BRANCH=${REPO_BRANCH:-"main"}
REPO_BASE_URL="https://raw.githubusercontent.com/AutoFi/template-assets/${REPO_BRANCH}"
REPO_AWS_CONTENT_URL="${REPO_BASE_URL}/aws"
COMMON_FUNCTIONS_URL="${REPO_BASE_URL}/common.sh"

# Exporter installation variables
EXPORTER_APP_NAME=${EXPORTER_APP_NAME:-"port-aws-exporter"}
EXPORTER_LAMBDA_NAME=${EXPORTER_LAMBDA_NAME:-"port-aws-exporter"}
EXPORTER_SECRET_NAME=${EXPORTER_SECRET_NAME:-"port-credentials"}
EXPORTER_IAM_POLICY_NAME=${EXPORTER_IAM_POLICY_NAME:-"PortAWSExporterPolicy"}
EXPORTER_CF_EVENT_RULES_STACK_NAME=${EXPORTER_CF_EVENT_RULES_STACK_NAME:-"port-aws-exporter-event-rules"}

function cleanup {
  rm -rf "${temp_dir}"
}
trap cleanup EXIT

# Create temporary folder
temp_dir=$(mktemp -d)

echo "Importing common functions..."
curl -s ${COMMON_FUNCTIONS_URL} -o "${temp_dir}/common.sh"
source "${temp_dir}/common.sh" || exit

echo ""
echo "Checking for prerequisites..."
echo ""
check_commands "aws" "jq"
echo ""
check_port_credentials "${PORT_CLIENT_ID}" "${PORT_CLIENT_SECRET}"

echo "Checking AWS login status..."
echo ""
if ! aws sts get-caller-identity
then
    echo ""
    echo "aws sts get-caller-identity failed. Make sure you are logged in"
    exit 1
fi

# Additional AWS based variables for the exporter installation
AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r ".Account")
AWS_REGION=$(aws ec2 describe-availability-zones --output text --query 'AvailabilityZones[0].[RegionName]') || exit

EXPORTER_BUCKET_NAME=${EXPORTER_BUCKET_NAME:-"port-aws-exporter-${AWS_ACCOUNT_ID}-${AWS_REGION}"}
EXPORTER_IAM_POLICY_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:policy/${EXPORTER_IAM_POLICY_NAME}"

echo ""
echo "Downloading configuration files..."
echo ""
save_endpoint_to_file "${REPO_AWS_CONTENT_URL}/config.json" "${temp_dir}/config.json" || exit
save_endpoint_to_file "${REPO_AWS_CONTENT_URL}/policy.json" "${temp_dir}/policy.json" || exit
save_endpoint_to_file "${REPO_AWS_CONTENT_URL}/parameters.json" "${temp_dir}/parameters.json" || exit
save_endpoint_to_file "${REPO_AWS_CONTENT_URL}/event_rules.yaml" "${temp_dir}/event_rules.yaml" || exit

echo ""
echo "Checking existence of IAM policy: \"${EXPORTER_IAM_POLICY_NAME}\"..."
echo ""

if ! aws iam get-policy --policy-arn "${EXPORTER_IAM_POLICY_ARN}" &> /dev/null
then
    echo "Policy not exists, creating..."
    echo ""
    aws iam create-policy --policy-name "${EXPORTER_IAM_POLICY_NAME}" --policy-document "file://${temp_dir}/policy.json" || exit
else
    echo "Policy exists"
fi

echo ""
echo "Preparing parameters json file..."
echo ""

sed -i.backup \
-e "s/\<EXPORTER_BUCKET_NAME>/${EXPORTER_BUCKET_NAME}/" \
-e "s/\<EXPORTER_LAMBDA_NAME>/${EXPORTER_LAMBDA_NAME}/" \
-e "s/\<EXPORTER_SECRET_NAME>/${EXPORTER_SECRET_NAME}/" \
-e "s/\<EXPORTER_IAM_POLICY_ARN>/${EXPORTER_IAM_POLICY_ARN//\//\\/}/" \
"${temp_dir}/parameters.json" || exit

cat "${temp_dir}/parameters.json"
echo ""

echo ""
echo "Deploying Port's AWS exporter application..."

# --debug \
CHANGE_SET_ID=$(aws serverlessrepo create-cloud-formation-change-set \
--application-id arn:aws:serverlessrepo:eu-west-1:185657066287:applications/port-aws-exporter \
--stack-name "${EXPORTER_APP_NAME}" --capabilities CAPABILITY_IAM CAPABILITY_RESOURCE_POLICY \
--parameter-overrides "file://${temp_dir}/parameters.json" | jq -r ".ChangeSetId")

if ! aws cloudformation wait change-set-create-complete --change-set-name "${CHANGE_SET_ID}" &> /dev/null
then
    echo ""
    aws cloudformation describe-change-set --change-set-name "${CHANGE_SET_ID}" | jq -c 'with_entries(select([.key] | inside(["Status", "StatusReason"])))'
else
    aws cloudformation execute-change-set --change-set-name "${CHANGE_SET_ID}" || exit
    echo ""
    cloudformation_tail "serverlessrepo-${EXPORTER_APP_NAME}"
fi

echo ""
echo "Checking existence of config.json in S3 bucket..."
echo ""

if ! aws s3api head-object --bucket "${EXPORTER_BUCKET_NAME}" --key "config.json" &> /dev/null
then
    echo "config.json not exists, uploading..."
    echo ""
    aws s3api put-object --bucket "${EXPORTER_BUCKET_NAME}" --key "config.json" --body "${temp_dir}/config.json" || exit
else
    echo "config.json exists"
fi

echo ""
echo "Updating Port credentials secret..."
echo ""

aws secretsmanager put-secret-value --secret-id "${EXPORTER_SECRET_NAME}" --secret-string "{\"id\":\"${PORT_CLIENT_ID}\",\"clientSecret\":\"${PORT_CLIENT_SECRET}\"}" || exit

echo ""
echo "Creating CloudFormation of event rules for real-time updates..."

aws cloudformation deploy --template-file "${temp_dir}/event_rules.yaml" --stack-name "${EXPORTER_CF_EVENT_RULES_STACK_NAME}"

echo ""
echo "Finished installation!"

echo ""
echo "Creating Port entity for region: \"${AWS_REGION}\"..."
echo ""

upsert_port_entity "${PORT_CLIENT_ID}" "${PORT_CLIENT_SECRET}" "region" "{\"identifier\": \"${AWS_REGION}\", \"title\": \"${AWS_REGION}\", \"properties\": {}}" || exit

echo ""
echo "Running exporter's lambda manually..."
echo ""

if ! command -v sam &> /dev/null
then
    echo "sam command for live logs does not exists, will print the execution log's tail when done"
    echo ""
    aws lambda invoke --function-name "${EXPORTER_LAMBDA_NAME}" --log-type "Tail" --payload "{}" "${temp_dir}/outfile" | jq -r ".LogResult" | base64 --decode
else
    aws lambda invoke --function-name "${EXPORTER_LAMBDA_NAME}" --invocation-type "Event" --payload "{}" "${temp_dir}/outfile" || exit
    echo ""
    echo "Tail exporter's lambda logs, press CTRL+C to break..."
    echo ""
    sam logs --stack-name "serverlessrepo-${EXPORTER_APP_NAME}" --tail
fi
