#!/bin/bash
set -e

###################################################
# Author: Matan Heled
# Company: Port
# Date: 28/2/2023
# Version: v1.0
#
# Description:
#   This script is responsible for installing Port's Kuberenetes exporter using helm.
#   Documentation: https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/kubernetes/)
# 
# Prerequisites(https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/kubernetes/#prerequisites):
#   - Helm must be installed
#   - kubectl must be installed, and an active connection to a Kubernetes cluster is required
#   - The variables 'PORT_CLIENT_ID' and 'PORT_CLIENT_SECRET' must be passed to the script
# 
# Variables:
#   PORT_CLIENT_ID - Your Port organization Client ID (required)
#   PORT_CLIENT_SECRET - Your Port organization Client Secret (required)
#   TARGET_NAMESPACE - The namespace to install Port's Kubernetes exporter (default="port-k8s-exporter")
#   DEPLOYMENT_NAME - The deployment name of the Kubernetes exporter (default="port-k8s-exporter")
#
###################################################

# Global variables
REPO_BRANCH=${REPO_BRANCH:-"main"}
REPO_BASE_URL="https://raw.githubusercontent.com/port-labs/template-assets/${REPO_BRANCH}"
COMMON_FUNCTIONS_URL="${REPO_BASE_URL}/common.sh"

# Exporter installation variables
TEMPLATE_NAME=${TEMPLATE_NAME:-}
BASE_CONFIG_YAML_URL="$REPO_BASE_URL/kubernetes/kubernetes_config.yaml"
CONFIG_YAML_URL=${CONFIG_YAML_URL:-}
HELM_REPO_NAME="port-labs"
HELM_REPO_URL="https://port-labs.github.io/helm-charts"
HELM_K8S_CHART_NAME="port-k8s-exporter"


TARGET_NAMESPACE=${TARGET_NAMESPACE:-"port-k8s-exporter"}
DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-"port-k8s-exporter"}
CLUSTER_NAME=${CLUSTER_NAME:-"my-cluster"}

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

check_commands "helm" "kubectl"

# Check if connected to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null
then
    echo "You are not currently connected to a Kubernetes cluster"
    exit
fi
kcontext=$(kubectl config current-context)
echo "Connected to cluster ${kcontext}."
echo ""

check_port_credentials "${PORT_CLIENT_ID}" "${PORT_CLIENT_SECRET}"

echo "Beginning setup..."
echo ""

# Download config.yaml file into temporary folder
if [[ -z ${CONFIG_YAML_URL} ]]; then
  save_endpoint_to_file ${BASE_CONFIG_YAML_URL} "${temp_dir}/template_config.yaml"

  # Iterate over TEMPLATE_NAMES and download their config.yaml files
  for template in ${TEMPLATE_NAME}
  do
      echo "Downloading config.tmpl file for template '${template}'..."
      CONFIG_YAML_URL="${REPO_BASE_URL}/kubernetes/${template}_config.tmpl"
      save_endpoint_to_file ${CONFIG_YAML_URL} "${temp_dir}/${template}_config.tmpl"
      cat ${temp_dir}/${template}_config.tmpl >> ${temp_dir}/template_config.yaml
      echo "Added ${template}."
  done
else
  echo "Custom config.yaml file found."
  if [[ $(check_path_or_url ${CONFIG_YAML_URL}) == 'local']; then
    cp ${CONFIG_YAML_URL} "${temp_dir}/template_config.yaml" || echo "Failed to copy \"${CONFIG_YAML_URL}\" to temp dir. Does it exist?" && exit 1
    echo "copied"
  else
    save_endpoint_to_file ${CONFIG_YAML_URL} "${temp_dir}/template_config.yaml"
  fi
fi
# Replace the place holder {CLUSTER_NAME} with passed cluster name in the config.yaml
sed "s/{CLUSTER_NAME}/${CLUSTER_NAME}/g" "${temp_dir}/template_config.yaml" > "${temp_dir}/config.yaml"


echo "Adding ${HELM_REPO_NAME} repository to helm..."
helm repo add port-labs ${HELM_REPO_URL}
echo ""

echo "Updating ${HELM_REPO_NAME} helm repository..."
helm repo update ${HELM_REPO_NAME}
echo ""

echo "Deploying Port's Kubernetes exporter to '${kcontext}' using helm."
echo "*** The cluster will be referenced as '${CLUSTER_NAME}' in your Port Environment ***"
echo ""
echo "The exporter will be deployed to namespace: '${TARGET_NAMESPACE}', under the deployment name '${DEPLOYMENT_NAME}'."
echo ""
helm upgrade --install ${DEPLOYMENT_NAME} ${HELM_REPO_NAME}/${HELM_K8S_CHART_NAME} \
--create-namespace --namespace ${TARGET_NAMESPACE} \
--set secret.secrets.portClientId=${PORT_CLIENT_ID} --set secret.secrets.portClientSecret=${PORT_CLIENT_SECRET} \
--set-file configMap.config=${temp_dir}/config.yaml
echo ""

echo "Finished installation!"
echo ""
echo "To check out the exporter's logs, run:"
echo "kubectl logs deploy/${DEPLOYMENT_NAME} -n ${TARGET_NAMESPACE}"