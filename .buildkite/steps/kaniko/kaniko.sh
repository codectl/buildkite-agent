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
manifest="$(mktemp)"
downloads="$(mktemp -d)"
trap 'rm -f -- "$manifest";' EXIT
trap 'rm -rf -- "$downloads";' EXIT

echo "--- :kubernetes: Shipping"

# download repository
buildkite-agent artifact download "*.tar.gz" "$downloads" --build "${BUILDKITE_TRIGGERED_FROM_BUILD_ID}"

# define kaniko variables
CONTEXT="tar://$(ls "${downloads}/*.tar.gz")"
DESTINATION=${REGISTRY}/${REGISTRY_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG:-latest}

CONTEXT="$CONTEXT" \
DESTINATION="$DESTINATION" \
envsubst < "$(dirname "$0")/pod.yaml" > "${manifest}"

kubectl apply -f "$manifest"

echo "--- :zzz: Waiting for deployment"
kubectl wait --for condition=complete --timeout=300s -f "${manifest}"

rm "${manifest}"
