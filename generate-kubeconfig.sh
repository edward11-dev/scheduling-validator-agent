#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <EC2_INSTANCE_IP> <PATH_TO_PEM_FILE>"
    exit 1
fi

INSTANCE_IP=$1
PEM_FILE=$2

echo "Fetching kubeconfig details from $INSTANCE_IP..."

# Get the server IP address from the remote kubeconfig
SERVER=$(ssh -i "$PEM_FILE" ubuntu@"$INSTANCE_IP" "grep 'server:' /home/ubuntu/.kube/config | awk '{print \$2}'")
if [ -z "$SERVER" ]; then
    echo "Failed to retrieve server address. Please check your IP and PEM file."
    exit 1
fi

# Get the certificate authority data
CA_DATA=$(ssh -i "$PEM_FILE" ubuntu@"$INSTANCE_IP" "cat /home/ubuntu/.minikube/ca.crt | base64 | tr -d '\n'")

# Get the client certificate data
CLIENT_CERT_DATA=$(ssh -i "$PEM_FILE" ubuntu@"$INSTANCE_IP" "cat /home/ubuntu/.minikube/profiles/minikube/client.crt | base64 | tr -d '\n'")

# Get the client key data
CLIENT_KEY_DATA=$(ssh -i "$PEM_FILE" ubuntu@"$INSTANCE_IP" "cat /home/ubuntu/.minikube/profiles/minikube/client.key | base64 | tr -d '\n'")

echo "Assembling the new, self-contained kubeconfig..."

# Create a timestamped directory
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
DIR_NAME="kubeconfig-$TIMESTAMP"
mkdir "$DIR_NAME"

# Assemble the new, self-contained kubeconfig
FILE_PATH="$DIR_NAME/kubeconfig"
cat > "$FILE_PATH" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: minikube
  cluster:
    server: $SERVER
    certificate-authority-data: $CA_DATA
contexts:
- name: minikube
  context:
    cluster: minikube
    user: minikube
current-context: minikube
users:
- name: minikube
  user:
    client-certificate-data: $CLIENT_CERT_DATA
    client-key-data: $CLIENT_KEY_DATA
EOF

echo "Successfully created '$FILE_PATH'."
