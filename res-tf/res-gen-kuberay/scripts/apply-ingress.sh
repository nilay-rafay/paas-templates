#!/usr/bin/env bash

set -e

rctl download kubeconfig --cluster ${CLUSTER_NAME} -p ${PROJECT} > ztka-user-kubeconfig
export KUBECONFIG=ztka-user-kubeconfig

if ! kubectl --kubeconfig=ztka-user-kubeconfig get namespace kuberay &> /dev/null; then
  kubectl --kubeconfig=ztka-user-kubeconfig create namespace kuberay
fi

##Apply Ingress
kubectl --kubeconfig=ztka-user-kubeconfig create secret generic basic-auth --from-file=auth -n kuberay || true
kubectl --kubeconfig=ztka-user-kubeconfig apply -f kuberay-ingress.yaml -n kuberay

## Apply TLS Secret in Kuberay ns
kubectl --kubeconfig=ztka-user-kubeconfig apply -f tls-secret.yaml -n kuberay

##Enable Authentication
kubectl --kubeconfig=ztka-user-kubeconfig patch ingress ray-dashboard-$CLUSTER_NAME -n kuberay --type='json' -p='[{"op": "add", "path": "/metadata/annotations/nginx.ingress.kubernetes.io~1auth-secret", "value":"basic-auth"}]'
kubectl --kubeconfig=ztka-user-kubeconfig patch ingress ray-dashboard-$CLUSTER_NAME -n kuberay --type='json' -p='[{"op": "add", "path": "/metadata/annotations/nginx.ingress.kubernetes.io~1auth-type", "value":"basic"}]'