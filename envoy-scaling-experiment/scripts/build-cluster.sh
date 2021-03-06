#!/bin/bash

source ../vars.sh
source ../scripts/utils.sh

CLUSTER_NAME=$1
AVAILABILITY_ZONE=$(gcloud compute instances list | grep "$(hostname) " | awk '{print $2}')

echo "Creating cluster..."
gcloud container clusters create $CLUSTER_NAME \
  --cluster-version $CLUSTER_VERSION \
  --num-nodes $NUM_NODES \
  --machine-type=$MACHINE_TYPE \
  --zone $AVAILABILITY_ZONE \
  --enable-ip-alias \
  --project cf-routing-desserts
  --create-subnetwork name=$CLUSTER_NAME-network,range=10.5.0.0/16 \
  --cluster-ipv4-cidr=10.0.0.0/14 \
  --services-ipv4-cidr=10.4.0.0/16

echo "Getting credentials..."
gcloud container clusters get-credentials $CLUSTER_NAME \
    --zone $AVAILABILITY_ZONE \
    --project cf-routing-desserts

kubectl create clusterrolebinding cluster-admin-binding \
    --clusterrole=cluster-admin \
    --user=$(gcloud config get-value core/account)

kubectl create namespace system
