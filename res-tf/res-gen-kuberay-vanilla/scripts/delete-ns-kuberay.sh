#!/usr/bin/env bash

set -e

rctl download kubeconfig --cluster ${CLUSTER_NAME} -p ${PROJECT} > ztka-user-kubeconfig
export KUBECONFIG=ztka-user-kubeconfig

kubectl --kubeconfig=ztka-user-kubeconfig delete ns kuberay --ignore-not-found