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

manifest="$(mktemp)"

echo "--- :kubernetes: Shipping"

# define kaniko variables
CONTEXT=$(sed "s/:/\//; s/git@/https:\/\/${BITBUCKET_USER}:${BITBUCKET_TOKEN}@/" <<< "$BITBUCKET_CONTEXT_REPO")
DESTINATION=${REGISTRY}/${REGISTRY_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG:-latest}
vars="CONTEXT=$CONTEXT DESTINATION=$DESTINATION"

env "$vars" envsubst < "$(dirname "$0")/pod.yaml" > "${manifest}"
kubectl apply -f "$manifest"

echo "--- :zzz: Waiting for deployment"
kubectl wait --for condition=complete --timeout=300s -f "${manifest}"
