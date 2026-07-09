#!/bin/bash

KIND_CLUSTER_NAME="test-cluster"
NO_COLOR='\033[0m'
OK_COLOR='\033[32;01m'
ERR_COLOR='\033[0;31m'

# check that kind is installed
if ! command -v kind &> /dev/null
then
    printf "${ERR_COLOR}kind binary could not be found ${NO_COLOR}\n"
    exit 1
fi

# check that kubectl is installed
if ! command -v kubectl &> /dev/null
then
    printf "${ERR_COLOR}kubectl binary could not be found${NO_COLOR}\n"
    exit 1
fi

kind get clusters|grep  $KIND_CLUSTER_NAME &>/dev/null && printf "${ERR_COLOR}Cluster with name: ${KIND_CLUSTER_NAME} already exists....${NO_COLOR}\n" && exit 1


kind create cluster --name $KIND_CLUSTER_NAME --config ./kind/kind.yaml

# sleep for 15 seconds to allow the cluster to come up
sleep 15


# check that k8s context is correctly set
if kubectl config get-contexts |tail -n +2|awk {'print $2'}|grep -q "kind-${KIND_CLUSTER_NAME}"; then
    printf "${OK_COLOR}Cluster with name: ${KIND_CLUSTER_NAME} found and k8s context is correctly set. Continuing...${NO_COLOR}\n"
else
    printf "${ERR_COLOR}Cluster with name: ${KIND_CLUSTER_NAME} not found or k8s context is incorrect. Exiting...${NO_COLOR}\n"
    exit 1
fi


# install envoy gw-api
kubectl create -f envoy-gw/envoy-install.yaml && \
kubectl wait --namespace envoy-gateway-system \
  --for=condition=ready pod \
  --selector=control-plane=envoy-gateway \
  --timeout=90s

kubectl label nodes test-cluster-worker gputype=rtx4060

# create namespaces
kubectl apply -f ./spec/namespaces.yaml

# configure the envoy gateway: GatewayClass, EnvoyProxy infra config, Gateway, ReferenceGrant
kubectl apply -f ./envoy-gw/envoy-ing-ctl.yaml
kubectl apply -f ./envoy-gw/envoy-proxy-config.yaml
kubectl apply -f ./envoy-gw/main-gateway.yaml
kubectl apply -f ./envoy-gw/ref-grants.yaml

# wait for envoy gateway to provision the proxy service for main-gw
printf "Waiting for the envoy proxy service for gateway main-gw...\n"
GW_SVC=""
for i in $(seq 1 30); do
    GW_SVC=$(kubectl get svc -n basic-gw \
      -l gateway.envoyproxy.io/owning-gateway-namespace=basic-gw,gateway.envoyproxy.io/owning-gateway-name=main-gw \
      -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    [ -n "$GW_SVC" ] && break
    sleep 2
done

if [ -z "$GW_SVC" ]; then
    printf "${ERR_COLOR}Envoy proxy service for gateway main-gw was not created in time${NO_COLOR}\n"
    exit 1
fi

# pin the NodePort to 30080 so it matches kind's hostPort 80 -> containerPort 30080 mapping
kubectl patch svc "$GW_SVC" -n basic-gw --type=json \
  -p '[{"op": "replace", "path": "/spec/ports/0/nodePort", "value": 30080}]'

# create tasks
kubectl apply -f ./spec/task1/
sleep 10

kubectl apply -f ./spec/task2/
kubectl apply -f ./spec/task3/
kubectl apply -f ./spec/task4/
kubectl apply -f ./spec/99_deploy4.yaml
kubectl apply -f ./spec/task5/

