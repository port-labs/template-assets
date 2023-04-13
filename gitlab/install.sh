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
#   - The variables 'PORT_CLIENT_ID', 'PORT_CLIENT_SECRET', 'GITLAB_API_TOKEN' and 'GROUP_ID' must be passed to the script
# 
# Variables:
#   PORT_CLIENT_ID - Your Port organization Client ID (required)
#   PORT_CLIENT_SECRET - Your Port organization Client Secret (required)
#   GITLAB_API_TOKEN - Your GitLab API token (required)
#   GROUP_ID - The ID of the GitLab group to sync (required)
#
###################################################

# Enter your GitLab API token and group ID here
REPO_BASE_URL="https://raw.githubusercontent.com/port-labs/template-assets/add-gitlab-exporter-template" # TODO: change to main
COMMON_FUNCTIONS_URL="${REPO_BASE_URL}/common.sh"
GITLAB_EXPORTER_SCRIPT_URL="${REPO_BASE_URL}/gitlab/gitlab_exporter.py"

function cleanup {
  rm -rf "${temp_dir}"
}
trap cleanup EXIT

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
if command -v python3 &>/dev/null
then
  echo "Python 3 is installed, Running script..."
  python3 -m pip install requests
  python3 "${temp_dir}/gitlab_exporter.py" "${PORT_CLIENT_ID}" "${PORT_CLIENT_SECRET}" "${GITLAB_API_TOKEN}" "${GROUP_ID}"
elif command -v python &>/dev/null 
then
  echo "Python 2 is installed, Running script..."
  python -m pip install requests
  python "${temp_dir}/gitlab_exporter.py" "${PORT_CLIENT_ID}" "${PORT_CLIENT_SECRET}" "${GITLAB_API_TOKEN}" "${GROUP_ID}"
else
  echo "Neither Python 2 nor Python 3 is installed, please install Python and try again"
  exit 1
fi



echo ""
echo "Finished installation!"
echo ""