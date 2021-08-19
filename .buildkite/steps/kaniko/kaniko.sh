#!/usr/bin/env bash

set -euo pipefail

# validate env parameters
if [[ ! -v IMAGE_NAME ]]; then
  echo "--- :boom: Missing 'IMAGE_NAME'" 1>&2
  exit 1
elif [[ ! -v REGISTRY ]]; then
  echo "--- :boom: Missing 'REGISTRY'" 1>&2
  exit 1
elif [[ ! -v REGISTRY_REPOSITORY ]]; then
  echo "--- :boom: Missing 'REGISTRY_REPOSITORY'" 1>&2
  exit 1
fi

# temporary files
tmpdir=$(mktemp -d)
manifest="${tmpdir}/manifest.yaml"
config="${tmpdir}/config.json"
echo "--- :kubernetes: Shipping image :docker:"

# setup registry docker context
HTTP_PROXY="${HTTP_PROXY}" \
  HTTPS_PROXY="${HTTPS_PROXY}" \
  NO_PROXY="${NO_PROXY}" \
  REGISTRY="$REGISTRY" \
  CREDENTIALS=$(echo -n "${REGISTRY_USER}:${REGISTRY_TOKEN}" | base64 | tr -d '\n') \
  envsubst <"$(dirname "$0")/dockerconfig.json" >"${config}"
kubectl delete configmap docker-config --ignore-not-found
kubectl create configmap docker-config --from-file "${config}"

# define pod kaniko variables
artifact="${IMAGE_NAME}:${IMAGE_TAG}.tar.gz"
credentials="${REGISTRY_USER}:${REGISTRY_TOKEN}"
CONTEXT="https://${credentials}@${REGISTRY}/artifactory/${REGISTRY_REPOSITORY}/${artifact}"
DESTINATION="${REGISTRY}/${REGISTRY_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"
  CONTEXT="$CONTEXT" \
  DESTINATION="$DESTINATION" \
  envsubst <"$(dirname "$0")/pod.yaml" >"${manifest}"

# start / restart pod execution
kubectl delete -f "$manifest" --ignore-not-found
kubectl apply -f "$manifest"

echo "--- :zzz: Waiting for completion"
kubectl wait --for condition=complete --timeout=100s -f "${manifest}"

# cleanup
kubectl delete secret registry-context
rm -rf -- "$tmpdir"
