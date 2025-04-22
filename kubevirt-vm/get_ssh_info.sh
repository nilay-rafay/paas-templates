#!/usr/bin/env bash
set -ex
export KUBECONFIG=kubeconfig.json

OS=$(uname | tr '[:upper:]' '[:lower:]')
ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64) ARCH="amd64" ;;
esac

wget -q "https://dl.k8s.io/release/v1.32.1/bin/${OS}/${ARCH}/kubectl"
chmod +x ./kubectl
KUBECTL="./kubectl"

# Function to get the status of the VM
get_vm_status() {
    "${KUBECTL}" get -n "${NAMESPACE}" vm "${VM_NAME}" -o 'jsonpath={.status.printableStatus}'
}

# Wait for the VM status to become "Ready"
while true; do
    status=$(get_vm_status)
    echo "Current status: $status"
    if [ "$status" == "Running" ]; then
        echo "VM is ready."
        break
    fi
    echo "Waiting for VM to become ready..."
    sleep 5
done

NODE_IP=$("${KUBECTL}" get pod -n "${NAMESPACE}" -l "kubevirt.io/vm=${VM_NAME}" -o jsonpath='{.items[0].status.hostIP}')
SSH_PORT=$("${KUBECTL}" get -n "${NAMESPACE}" service "${SERVICE_NAME}" -o 'jsonpath={.spec.ports[0].nodePort}')
echo "ssh -i <ssh_key> ${USERNAME}@${NODE_IP} -p ${SSH_PORT}" > ssh_login_info
