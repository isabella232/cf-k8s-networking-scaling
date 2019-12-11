#!/bin/bash

source ../vars.sh
source ../scripts/utils.sh

PATH_TO_VALUES=$(pwd)/../values.yaml

pushd $ISTIO_FOLDER
  kubectl apply -f install/kubernetes/helm/helm-service-account.yaml

  helm init --service-account tiller --wait

  helm template install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -

  # wait until istio CRDs are loaded
  until [ $(kubectl get crds | grep -c 'istio.io') -ge "23" ]; do true; done

  helm template install/kubernetes/helm/istio \
    --name istio --namespace istio-system -f $PATH_TO_VALUES | kubectl apply -f -

  sleep 10

  helm install --name node-exporter stable/prometheus-node-exporter

  # wait until Istio is reporting live and healthy
  kubectl wait --for=condition=available --timeout=600s deployment $(kubectl get deployments -n istio-system | grep istio | awk '{print $1}')

  # clean up setup pods
  kubectl delete pod --all-namespaces --field-selector=status.phase==Succeeded

  # install test workloads
  kubectl label namespace default istio-injection=enabled --overwrite=true
popd

