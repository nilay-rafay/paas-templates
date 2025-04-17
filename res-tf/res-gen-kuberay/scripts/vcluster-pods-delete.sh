#!/bin/bash

set -e

rctl download kubeconfig --cluster ${CLUSTER_NAME} -p ${PROJECT} > ztka-user-kubeconfig
export KUBECONFIG=ztka-user-kubeconfig

##Cleanup vcluster pods on Host cluster
kubectl --kubeconfig=ztka-user-kubeconfig get ns -l vcluster.loft.sh/vcluster-name=${VCLUSTER_NAME} \
 | awk '/vcluster/ {print $1}' | xargs kubectl --kubeconfig=ztka-user-kubeconfig delete ns