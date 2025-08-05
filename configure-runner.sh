#!/bin/bash

set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <GITHUB_REPO_URL> <RUNNER_REGISTRATION_TOKEN>"
    echo "Example: $0 https://github.com/your-org/your-repo AABBCCDDEEFFGGHHIIJJ"
    exit 1
fi

REPO_URL=$1
TOKEN=$2

echo "Configuring the GitHub Actions runner..."

# Navigate to the runner directory
cd /home/ubuntu/actions-runner

# Run the configuration script
./config.sh --url "$REPO_URL" --token "$TOKEN" --unattended --replace

echo "Installing and starting the runner service..."

# Install and start the runner as a service
sudo ./svc.sh install
sudo ./svc.sh start

echo "Runner configuration complete. It should appear as 'Idle' in your GitHub repository settings."
