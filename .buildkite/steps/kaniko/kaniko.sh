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

#envsubst < deployment.yml > "${manifest}"
kubectl apply -f pod.yaml

echo "--- :zzz: Waiting for deployment"
kubectl wait --for condition=available --timeout=300s -f "${manifest}"
