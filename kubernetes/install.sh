#!/bin/bash

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
REPO_URL="https://github.com/port-labs/template-assets/blob/main"
TEMPLATE_NAME="kubernetes"
PORT_API_URL="https://api.getport.io"

# Exporter installation variables
CONFIG_YAML_URL="https://raw.githubusercontent.com/port-labs/template-assets/main/kubernetes/config.yaml"
HELM_REPO_NAME="port-labs"
HELM_REPO_URL="https://port-labs.github.io/helm-charts"
HELM_K8S_CHART_NAME="port-k8s-exporter"


TARGET_NAMESPACE=${TARGET_NAMESPACE:-"port-k8s-exporter"}
DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-"port-k8s-exporter"}
CLUSTER_NAME=${CLUSTER_NAME:-"my-cluster"}

echo "Checking for prerequisites..."

# Checks if helm command is installed
if ! command -v helm &> /dev/null
then
    echo "helm could not be found"
    exit
fi
echo "helm command found!"

# Check if kubectl command is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl could not be found"
    exit
fi
echo "kubectl command found!"

# Check if connected to Kubernetes cluster
if ! kubectl cluster-info &> /dev/null
then
    echo "You are not currently connected to a Kubernetes cluster"
    exit
fi
kcontext=$(kubectl config current-context)
echo "Connected to cluster ${kcontext}."


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

echo "Beginning setup..."
echo ""

function cleanup {
  rm -rf "${temp_dir}"
}
trap cleanup EXIT

# Create temporary folder
temp_dir=$(mktemp -d)


# Download config.yaml file into temporary folder
curl ${CONFIG_YAML_URL} -o "${temp_dir}/config.yaml"
sed "s/{CLUSTER_NAME}/${CLUSTER_NAME}/g" "${temp_dir}/config.yaml"

# Replace the place holder {CLUSTER_NAME} with passed cluster name in the config.yaml
sed "s/{CLUSTER_NAME}/${CLUSTER_NAME}/g" "${temp_dir}/config.yaml" > "${temp_dir}/config.yaml"

cat "${temp_dir}/config.yaml"

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
--create-namespace --namespace port-k8s-exporter \
--set secret.secrets.portClientId=${PORT_CLIENT_ID} --set secret.secrets.portClientSecret=${PORT_CLIENT_SECRET} \
--set-file configMap.config=${temp_dir}/config.yaml
echo ""

echo "Finished installation!"