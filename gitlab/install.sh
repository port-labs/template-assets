#!/bin/bash
set -e

###################################################
# Author: Matan Levi
# Company: Port
# Date: 10/4/2023
# Version: v1.0
#
# Description:
#   This script is responsible for installing Port's GitLab exporter.
#   Documentation: To Be Added
# 
# Prerequisites:
#   - The variables 'PORT_CLIENT_ID' and 'PORT_CLIENT_SECRET' must be passed to the script
# 
# Variables:
#   PORT_CLIENT_ID - Your Port organization Client ID (required)
#   PORT_CLIENT_SECRET - Your Port organization Client Secret (required)
#   GITLAB_API_TOKEN - Your GitLab API token (required)
#   GROUP_ID - The ID of the GitLab group to sync (required)
#
###################################################

# Enter your GitLab API token and group ID here
REPO_BASE_URL="https://raw.githubusercontent.com/port-labs/template-assets/main"
COMMON_FUNCTIONS_URL="${REPO_BASE_URL}/common.sh"
GITLAB_EXPORTER_SCRIPT_URL="${REPO_BASE_URL}/gitlab/gitlab_exporter.py"

# Create temporary folder
temp_dir=$(mktemp -d)

echo "Importing common functions..."
curl -s ${COMMON_FUNCTIONS_URL} -o "${temp_dir}/common.sh"
source "${temp_dir}/common.sh"

echo "Checking for prerequisites..."

# Check if port_client_id and port_client_secret are defined
check_port_credentials "${PORT_CLIENT_ID}" "${PORT_CLIENT_SECRET}"

echo "Checking GitLab variables!"
echo ""
if [[ -z "${GITLAB_API_TOKEN}" ]] || [[ -z "${GROUP_ID}" ]]
then
  echo "GITLAB_API_TOKEN or GROUP_ID variables are not defined"
  exit 1
fi

echo "Beginning setup..."
echo ""

# Download gitlab exporter file into temporary folder
save_endpoint_to_file ${GITLAB_EXPORTER_SCRIPT_URL} "${temp_dir}/gitlab_exporter.py"
python "${temp_dir}/gitlab_exporter.py" --port_client_id "${PORT_CLIENT_ID}" --port_client_secret "${PORT_CLIENT_SECRET}" --gitlab_api_token "${GITLAB_API_TOKEN}" --group_id "${GROUP_ID}"

echo ""
echo "Finished installation!"
echo ""