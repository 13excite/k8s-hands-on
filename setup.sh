#!/bin/bash

KIND_CLUSTER_NAME="test-cluster"

# check that kind is installed
if ! command -v kind &> /dev/null
then
    echo "kind binary could not be found"
    exit 1
fi

# check that kubectl is installed
if ! command -v kubectl &> /dev/null
then
    echo "kubectl binary could not be found"
    exit 1
fi

kind get clusters|grep  $KIND_CLUSTER_NAME &>/dev/null && echo "Cluster $KIND_CLUSTER_NAME already exists...." && exit 1


kind create cluster --name $KIND_CLUSTER_NAME --config ./kind/kind.yaml

# sleep for 15 seconds to allow the cluster to come up
sleep 15


# check that k8s context is correctly set
if kubectl config get-contexts |tail -n +2|awk {'print $2'}|grep -q "kind-${KIND_CLUSTER_NAME}"; then
    echo "Cluster name ${KIND_CLUSTER_NAME} found and k8s context is correctly set"
else
    echo "Cluster name ${KIND_CLUSTER_NAME} not found or k8s context is incorrect. Exiting..."
    exit 1
fi