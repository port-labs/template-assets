#!/bin/bash
set -e

###################################################
# Author: Matan Heled
# Company: Port
# Date: 28/2/2023
# Version: v1.0
#
# Description:
#   This script is responsible for installing Port's Kubernetes exporter using helm.
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
REPO_BASE_URL="https://raw.githubusercontent.com/port-labs/template-assets/main"
REPO_BRANCH=${REPO_BRANCH:-"main"}
COMMON_FUNCTIONS_URL="${REPO_BASE_URL}/common.sh"

# Exporter installation variables
CONFIG_YAML_URL=${CONFIG_YAML_URL:-}
CUSTOM_BP_PATH=${CUSTOM_BP_PATH:-}
HELM_REPO_NAME="port-labs"
HELM_REPO_URL="https://port-labs.github.io/helm-charts"
HELM_K8S_CHART_NAME="port-k8s-exporter"


TARGET_NAMESPACE=${TARGET_NAMESPACE:-"port-k8s-exporter"}
DEPLOYMENT_NAME=${DEPLOYMENT_NAME:-"port-k8s-exporter"}
CLUSTER_NAME=${CLUSTER_NAME:-"my-cluster"}

# Event listener variables
EVENT_LISTENER_TYPE=${EVENT_LISTENER_TYPE:-"POLLING"}

if [[ "${EVENT_LISTENER_TYPE}" != "POLLING" ]] && [[ "${EVENT_LISTENER_TYPE}" != "KAFKA" ]]; then
  echo "Invalid event listener type: '${EVENT_LISTENER_TYPE}'. Valid types are: 'POLLING' or 'KAFKA'."
  exit 1
fi

# Polling event listener variables
EVENT_LISTENER_POLLING_RATE=${EVENT_LISTENER_POLLING_RATE:-}

# Kafka event listener variables
EVENT_LISTENER_KAFKA_BROKERS=${EVENT_LISTENER_KAFKA_BROKERS:-}
EVENT_LISTENER_KAFKA_SECURITY_PROTOCOL=${EVENT_LISTENER_KAFKA_SECURITY_PROTOCOL:-}
EVENT_LISTENER_KAFKA_AUTHENTICATION_MECHANISM=${EVENT_LISTENER_KAFKA_AUTHENTICATION_MECHANISM:-}

function cleanup {
  rm -rf "${temp_dir}"
}
trap cleanup EXIT

# Create temporary folder
temp_dir=$(mktemp -d)

echo "Importing common functions..."
curl -s ${COMMON_FUNCTIONS_URL} -o "${temp_dir}/common.sh"

source "${temp_dir}/common.sh"

cat << EOF


**** Install infromation ****
Docs Reference for Port's K8s Exporter - https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/kubernetes/

The following script will ensure a connection to the Kubernetes Cluster which is currently
referenced in your ~/.kubeconfig file.

It will add Port's helm chart ($HELM_REPO_URL) under the name "$HELM_REPO_NAME" locally,
and then install the chart to your Kubernetes cluster under the namespace: "$TARGET_NAMESPACE", 
and the Deployment name: "$DEPLOYMENT_NAME".

By default, the exporter is given *read* permissions on all API groups and resources
using the "$DEPLOYMENT_NAME" Cluster Role:

####
rules:
- apiGroups:
  - '*'
  resources:
  - '*'
  verbs:
  - get
  - watch
  - list
####

For advanced security configuration - https://docs.getport.io/build-your-software-catalog/sync-data-to-catalog/kubernetes/advanced#security-configuration


In Port, the current K8s cluster will be referenced as "$CLUSTER_NAME".

For further information, don't hesitate to reach out using our in-site Intercom system!
EOF

trigger_continue_prompt

echo "Checking for prerequisites..."

check_commands "helm" "kubectl" "yq" "jq"

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
if [[ -n ${CONFIG_YAML_URL} ]]; then
  echo "Custom config.yaml file configuration found."
  config_path_type=$(check_path_or_url ${CONFIG_YAML_URL}) # 'local' or 'url'
  if [[ "${config_path_type}" == 'local' ]]; then
    cp "${CONFIG_YAML_URL}" "${temp_dir}/template_config.yaml"
  elif [[ "${config_path_type}" == 'url' ]]; then
    save_endpoint_to_file ${CONFIG_YAML_URL} "${temp_dir}/template_config.yaml"
  else
    echo "Failed to retrieve custom \`config.yaml\` ${CONFIG_YAML_URL}. Is the path/URL valid?"
    exit 1
  fi
else
  echo "" > "${temp_dir}/template_config.yaml"
fi
# Validate config.yaml is a valid yaml
(cat ${temp_dir}/template_config.yaml | yq > /dev/null) || (echo "Failed to 'yq' parse the config.yaml. Is it a valid yaml? Exiting..." && exit 1)

echo ""
if [[ -n ${CUSTOM_BP_PATH} ]]; then
  echo "Found custom a blueprints file configuration. Attempting to create blueprints defined in: ${CUSTOM_BP_PATH}"
  bp_path_type=$(check_path_or_url ${CUSTOM_BP_PATH}) # 'local' or 'url'
  if [[ "${bp_path_type}" == 'local' ]]; then
    cp "${CUSTOM_BP_PATH}" "${temp_dir}/blueprints.json"
  elif [[ "${bp_path_type}" == 'url' ]]; then
    save_endpoint_to_file ${CUSTOM_BP_PATH} "${temp_dir}/blueprints.json"
  else
    echo "Failed to retrieve blueprints file \`${CUSTOM_BP_PATH}\`. Is the path/URL valid?"
    exit 1
  fi

  (cat ${temp_dir}/blueprints.json | jq . > /dev/null) || (echo "Failed to 'jq' parse the blueprints.json. Is it a valid json? Exiting..." && exit 1)
  cat ${temp_dir}/blueprints.json | jq -c '.[]' | while read blueprint; do
    post_port_blueprint "${PORT_CLIENT_ID}" "${PORT_CLIENT_SECRET}" "$blueprint" 
  done
fi

echo ""
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
helm_upgrade_command="helm upgrade --install ${DEPLOYMENT_NAME} ${HELM_REPO_NAME}/${HELM_K8S_CHART_NAME} \
  --create-namespace --namespace ${TARGET_NAMESPACE} \
  --set secret.secrets.portClientId=${PORT_CLIENT_ID} --set secret.secrets.portClientSecret=${PORT_CLIENT_SECRET} \
  --set createDefaultResources=false \
  --set-file configMap.config=${temp_dir}/template_config.yaml \
  --set extraEnv[0].name=CLUSTER_NAME \
  --set extraEnv[0].value=${CLUSTER_NAME} \
  --set stateKey=${CLUSTER_NAME} \
  --set eventListener.type=${EVENT_LISTENER_TYPE}"

if [ -n "${EVENT_LISTENER_KAFKA_BROKERS}" ]; then
  helm_upgrade_command="${helm_upgrade_command} --set eventListener.brokers=${EVENT_LISTENER_KAFKA_BROKERS}"
fi

if [ -n "${EVENT_LISTENER_KAFKA_SECURITY_PROTOCOL}" ]; then
  helm_upgrade_command="${helm_upgrade_command} --set eventListener.securityProtocol=${EVENT_LISTENER_KAFKA_SECURITY_PROTOCOL}"
fi

if [ -n "${EVENT_LISTENER_KAFKA_AUTHENTICATION_MECHANISM}" ]; then
  helm_upgrade_command="${helm_upgrade_command} --set eventListener.authenticationMechanism=${EVENT_LISTENER_KAFKA_AUTHENTICATION_MECHANISM}"
fi

if [ -n "${EVENT_LISTENER_POLLING_RATE}" ]; then
  helm_upgrade_command="${helm_upgrade_command} --set eventListener.pollingRate=${EVENT_LISTENER_POLLING_RATE}"
fi

eval "${helm_upgrade_command}"
echo ""

echo "Finished installation!"
echo ""
echo "To check out the exporter's logs, run:"
echo "kubectl logs deploy/${DEPLOYMENT_NAME} -n ${TARGET_NAMESPACE}"
