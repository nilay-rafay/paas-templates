#!/bin/bash
set -x
    # Download kubectl
        wget https://repo.rafay-edge.net/repository/eks-bootstrap/v1/kubectl >> /dev/null 2>&1

        # Make kubectl executable
        chmod +x kubectl
# Check if jq is installed, if not, install it using wget
if ! command -v jq &> /dev/null
then
    echo "jq could not be found, installing..."
    mkdir -p ~/bin
    wget -O ~/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64
    chmod +x ~/bin/jq
    export PATH=$PATH:~/bin
    echo "jq version: $(jq --version)"
    which jq
fi
        # Wait for the pods to be ready
        sleep 60 && ./kubectl wait po -l app.kubernetes.io/instance=nvidia-gpu-operator -n gpu-operator-resources --for=condition=Ready --timeout=10m --kubeconfig=/tmp/test/kubeconfig.yaml
        if [ $? -ne 0 ]; then
          echo "Pods did not become ready in time"
          exit 1
        fi

        # Get the pod names
        PODS=$(./kubectl get po -n gpu-operator-resources  --kubeconfig=/tmp/test/kubeconfig.yaml | grep nvidia-operator-validator | awk '{print $1}')

        # Check the init containers for validation
        VALIDATION=$(./kubectl get pod -n gpu-operator-resources $PODS -o json  --kubeconfig=/tmp/test/kubeconfig.yaml | jq '.spec.initContainers | .[] | .name' | grep -E 'driver-validation|toolkit-validation|cuda-validation|plugin-validation')
        if [ -n "$VALIDATION" ]; then
          echo "All validations are successful"
        else
          echo "Validation failed"
          exit 1
        fi

        # Check Nvidia smi in Nvidia driver daemonset
        sleep 240s &&  POD_NAME=$(./kubectl --kubeconfig=/tmp/test/kubeconfig.yaml get pods -n gpu-operator-resources -l app=nvidia-driver-daemonset -o jsonpath='{.items[0].metadata.name}') && 
        ./kubectl --kubeconfig=/tmp/test/kubeconfig.yaml exec -it -n gpu-operator-resources $POD_NAME -- ./NVIDIA-Linux-x86_64-550.90.12/nvidia-smi

        # Check Nvidia Container Toolkit if Driver related files are present
          sleep 240s && POD_NAME1=$(./kubectl --kubeconfig=/tmp/test/kubeconfig.yaml get pods -n gpu-operator-resources -l app=nvidia-container-toolkit-daemonset -o jsonpath='{.items[0].metadata.name}') && 
          output1=$(./kubectl --kubeconfig=/tmp/test/kubeconfig.yaml exec -n gpu-operator-resources $POD_NAME1 -- ls -al /usr/local/nvidia/toolkit/)
          if [ -z "$output1" ]; then
          echo "Error: Validation failed. The Nvidia toolkit directory doesn't exist"
          exit 1
          else
          echo -ne "Validation successful. The Nvidia toolkit directory exists with these files: \n $output1"
          fi

        # Node validation
        OUTPUT=$(./kubectl get no -l nvidia.com/gpu.deploy.operator-validator=true --kubeconfig=/tmp/test/kubeconfig.yaml)
        if echo "$OUTPUT" | grep -vE '"No resources found"|^$'; then      
        echo "GPU nodes found."
        else
        echo "No GPU nodes found. Failing."
        exit 1 
        fi
set +x