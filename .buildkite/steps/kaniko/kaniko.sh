#!/usr/bin/env bash

set -euo pipefail

# validate env parameters
if [[ ! -v DOCKER_IMAGE ]]; then
  echo "--- :boom: Missing 'DOCKER_IMAGE'" 1>&2
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

#envsubst < deployment.yml > "${manifest}"
kubectl apply -f pod.yaml

echo "--- :zzz: Waiting for deployment"
kubectl wait --for condition=available --timeout=300s -f "${manifest}"
