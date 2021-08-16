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

echo "--- :kubernetes: Shipping"

# download repository
buildkite-agent artifact download "*.tar.gz" "$downloads" --build "${BUILDKITE_TRIGGERED_FROM_BUILD_ID}"

# define pod kaniko variables
ARTIFACT_PATH="${downloads}"
ARTIFACT_FILENAME="$(ls "${downloads}"/*.tar.gz)"
DESTINATION=${REGISTRY}/${REGISTRY_REPOSITORY}/${IMAGE_NAME}:${IMAGE_TAG:-latest}

ARTIFACT_PATH="$ARTIFACT_PATH" \
ARTIFACT_FILENAME="$ARTIFACT_FILENAME" \
DESTINATION="$DESTINATION" \
envsubst < "$(dirname "$0")/pod.yaml" > "${manifest}"

kubectl apply -f "$manifest"

echo "--- :zzz: Waiting for deployment"
kubectl wait --for condition=complete --timeout=300s -f "${manifest}"

# cleanup
rm -f -- "$manifest"
rm -rf -- "$downloads"
