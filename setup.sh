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
    echo "Cluster name ${KIND_CLUSTER_NAME} found and k8s context is correctly set. Continuing..."
else
    echo "Cluster name ${KIND_CLUSTER_NAME} not found or k8s context is incorrect. Exiting..."
    exit 1
fi


# install ingress
kubectl apply -f ./ingress/ingress.yaml

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

kubectl label nodes test-cluster-worker gputype=rtx4060

# create namespaces
kubectl apply -f ./spec/namespaces.yaml

# create tasks
kubectl apply -f ./spec/task1/ 
sleep 10

kubectl apply -f ./spec/task2/
kubectl apply -f ./spec/task3/
kubectl apply -f ./spec/task4/
kubectl apply -f spec/99_deploy4.yaml

