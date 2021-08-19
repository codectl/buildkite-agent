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
echo "--- :kubernetes: Shipping image :docker:"

# set docker registry credentials
kubectl create secret docker-registry registry-context \
--docker-server="${REGISTRY}" \
--docker-username="${REGISTRY_USER}" \
--docker-password="${REGISTRY_TOKEN}"

# define pod kaniko variables
artifact="${IMAGE_NAME}:${IMAGE_TAG}.tar.gz"
CONTEXT="https://${REGISTRY}/artifactory/${REGISTRY_REPOSITORY}/${artifact}"
DESTINATION="https://${REGISTRY}/${REGISTRY_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG}"

CONTEXT="$CONTEXT" \
DESTINATION="$DESTINATION" \
envsubst < "$(dirname "$0")/pod.yaml" > "${manifest}"

# start / restart pod execution
kubectl delete -f "$manifest" --ignore-not-found
kubectl apply -f "$manifest"

echo "--- :zzz: Waiting for completion"
kubectl wait --for condition=complete --timeout=100s -f "${manifest}"

# cleanup
rm -rf -- "$tmpdir"
