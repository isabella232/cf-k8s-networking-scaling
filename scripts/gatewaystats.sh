#!/bin/bash

source ../scripts/utils.sh

echo "timestamp,podname,memory,heap"

while True; do
  # dump envoy's memory and heap utilization
  for pod in $(kubectl get pods -n istio-system --template '{{range .items}}{{.metadata.name}}{{"\n"}}{{end}}' | grep ingressgateway); do
    echo "$(udate),$pod,$(kubectl exec -n istio-system "$pod" -c istio-proxy -- pilot-agent request GET stats | yq '."server.memory_allocated",."server.memory_heap_size"' | awk -v ORS=, '{ print $1 }')" | sed 's/,$//' &
  done
  wait
done
