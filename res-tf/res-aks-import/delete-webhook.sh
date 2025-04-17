#!/usr/bin/env bash

# Script to delete rafay-drift-validate-v3 webhook.

# TMP_DIR=$1
# mkdir -p $TMP_DIR
# cd $TMP_DIR

# wget https://rafay-prod-cli.s3-us-west-2.amazonaws.com/publish/rctl-linux-amd64.tar.bz2
# tar -xf rctl-linux-amd64.tar.bz2
# ./rctl download kubeconfig --cluster ${CLUSTER_NAME} -p ${PROJECT} > ztka-user-kubeconfig
# Download kubeconfig using rctl
rctl download kubeconfig --cluster ${CLUSTER_NAME} -p ${PROJECT} > ztka-user-kubeconfig
export KUBECONFIG=ztka-user-kubeconfig

# Determine the system architecture and download the appropriate kubectl binary
# ARCH=$(uname -m)
# if [ "$ARCH" == "x86_64" ]; then
#   KUBECTL_URL="https://dl.k8s.io/release/v1.22.0/bin/linux/amd64/kubectl"
# elif [ "$ARCH" == "aarch64" ]; then
#   KUBECTL_URL="https://dl.k8s.io/release/v1.22.0/bin/linux/arm64/kubectl"
# else
#   echo "Unsupported architecture: $ARCH"
#   exit 1
# fi

# wget $KUBECTL_URL -O kubectl
# chmod +x kubectl
# ./kubectl delete validatingwebhookconfiguration rafay-drift-validate-v3
# Delete the validating webhook configuration using kubectl
kubectl delete validatingwebhookconfiguration rafay-drift-validate-v3

# Keep the rctl binary in the temporary directory for reuse
# echo $TMP_DIR > /tmp/rctl_tmp_dir_path

# Clean up temporary directory but retain rctl
# cd ~
