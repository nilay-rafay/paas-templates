
#!/bin/bash
set -e

# Configuration
MAX_WAIT_MINUTES=10
MAX_ITERATIONS=$((MAX_WAIT_MINUTES * 4))

## Install RCTL
wget https://rafay-prod-cli.s3-us-west-2.amazonaws.com/publish/rctl-linux-amd64.tar.bz2
tar -xf rctl-linux-amd64.tar.bz2
wget https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O ./jq
chmod +x ./jq

#sleep 60
if [ "$CLUSTER_TYPEP" == "eks" ];
then
  OUTPUT=`./rctl convert2managed cluster $CLUSTER_TYPEP $CLUSTER_NAME --source-cluster $CLUSTER_NAME --region $REGION --credential $CLOUD_CREDENTIAL -p $PROJECT_NAME`
else
  if [ "$CLUSTER_TYPEP" == "aks" ];
  then
    OUTPUT=`./rctl convert2managed cluster $CLUSTER_TYPEP $CLUSTER_NAME --source-cluster $CLUSTER_NAME --resource-group $RESOURCE_GROUP --credential $CLOUD_CREDENTIAL -p $PROJECT_NAME`
  fi
fi
# if $OUTPUT ; then
#     echo "[+] Fail To Convert The Cluster To Manage"
# else
CLUSTER_CONVERT_STATUS_ITERATIONS=1
echo "[+] Checking $CLUSTER_NAME Convert To Managed Status"
CLUSTER_TYPE=`./rctl get cluster $CLUSTER_NAME -p $PROJECT_NAME --v3 -o json |./jq '.spec.type'|cut -d'"' -f2 `
while [[ "$CLUSTER_TYPE" != "aws-eks" && "$CLUSTER_TYPE" != "aks" ]]
do
  #CLUSTER_TYPE=`./rctl get cluster $CLUSTER_NAME -p $PROJECT_NAME --v3 -o json |./jq '.spec.type'|cut -d'"' -f2 `
  # Fail if the cluster convert2managed takes more than 10 min.
  if [ $CLUSTER_CONVERT_STATUS_ITERATIONS -ge 40 ];
  then
    echo "FAILED: Cluster $CLUSTER_NAME Take More Than 10 Mins To Convert To Managed"
    exit 1
  fi
  sleep 15
  CLUSTER_TYPE=`./rctl get cluster $CLUSTER_NAME -p $PROJECT_NAME --v3 -o json |./jq '.spec.type'|cut -d'"' -f2 `
  echo "Cluster $CLUSTER_NAME Convert To Managed Status #$CLUSTER_CONVERT_STATUS_ITERATIONS: $CLUSTER_TYPE"
  CLUSTER_CONVERT_STATUS_ITERATIONS=$((CLUSTER_CONVERT_STATUS_ITERATIONS+1))
  if [[ "$CLUSTER_TYPE" == "aws-eks"  || "$CLUSTER_TYPE" == "aks" ]];
  then
    echo "COMPLETE: Cluster $CLUSTER_NAME Successfully Convert To Managed"
    exit 0
  fi
done
