#!/bin/bash
SECRET_NAME="sh.helm.release.v1.kubeflow.v1"
NAMESPACE="kubeflow"

wget https://repo.rafay-edge.net/repository/eks-bootstrap/v1/kubectl >> /dev/null 2>&1
chmod +x kubectl
echo "Checking if namespace $NAMESPACE exists..."
if ./kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
  echo "Namespace $NAMESPACE exists. Hence leaving the secret as it is"
elif ./kubectl get secret "$SECRET_NAME" > /dev/null 2>&1 && ! ./kubectl get namespace "$NAMESPACE" > /dev/null 2>&1; then
  echo "Namespace $NAMESPACE does not exist but secret $SECRET_NAME exists. Deleting the secret."
  ./kubectl delete secret "$SECRET_NAME" > /dev/null 2>&1
  echo "Secret $SECRET_NAME deleted."
else
  echo "Pre-checks successful"  
fi