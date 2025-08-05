# Scheduling Validator Agent

This project contains a scheduling validator agent that interacts with Google Calendar. This document outlines the steps to deploy the agent and its required infrastructure to a Minikube cluster running on an AWS EC2 instance, using a secure, self-hosted GitHub Actions runner.

## Deployment Workflow

The deployment process is divided into the following stages:

1.  **Infrastructure Provisioning**: Use Terraform to create two AWS EC2 instances: one for the Minikube cluster (`monitoring-server`) and one to act as a self-hosted GitHub Actions runner (`github-runner`).
2.  **Runner Configuration**: Perform a one-time manual setup to register the self-hosted runner with your GitHub repository.
3.  **Secret Configuration**: Configure the necessary secrets in the GitHub repository to allow the workflow to run.
4.  **Secret Encryption**: Run the GitHub Actions workflow. The self-hosted runner will securely connect to the monitoring server, retrieve the kubeconfig, encrypt the API key, and commit the resulting `SealedSecret` manifest to the repository.
5.  **Application Deployment**: Deploy the agent and its database to the Minikube cluster.

---

## Prerequisites

Before you begin, ensure you have the following:

-   An AWS account with credentials configured for your local environment.
-   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine.
-   [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured.
-   A GitHub Personal Access Token (PAT) with `repo` scope.

---

## Step 1: Infrastructure Setup

This step provisions the two EC2 instances.

1.  **Navigate to the Terraform directory**:
    ```bash
    cd ../py-app-otel
    ```

2.  **Initialize Terraform**:
    ```bash
    terraform init
    ```

3.  **Apply the Terraform configuration**:
    ```bash
    terraform apply
    ```
    This command will create the `monitoring-server` and `github-runner` instances. It may take several minutes to complete.

## Step 2: Configure Self-Hosted Runner (One-Time Setup)

You must manually register the new EC2 instance with your GitHub repository using the provided script.

1.  **Get the public IP of the runner instance**:
    ```bash
    terraform output -raw github_runner_public_ip
    ```

2.  **Get your runner registration token**:
    -   In your GitHub repository, go to `Settings` > `Actions` > `Runners`.
    -   Click `New self-hosted runner`.
    -   Select `Linux` as the operating system.
    -   Copy the registration token from the "Configure" section. It's the long string of characters in the `./config.sh ... --token YOUR_TOKEN` command.

3.  **SSH into the runner instance**. Replace `INSTANCE_IP` with the IP from step 1 and `/path/to/your/key.pem` with the path to your private key.
    ```bash
    ssh -i /path/to/your/key.pem ubuntu@INSTANCE_IP
    ```

4.  **Run the configuration script**. Inside the SSH session, run the script you find in the home directory.
    -   Replace `<YOUR_REPO_URL>` with the URL to your repository (e.g., `https://github.com/your-org/your-repo`).
    -   Replace `<YOUR_REGISTRATION_TOKEN>` with the token from step 2.
    ```bash
    ./configure-runner.sh <YOUR_REPO_URL> <YOUR_REGISTRATION_TOKEN>
    ```
    The script will configure, install, and start the runner service. Your runner should now appear as "Idle" in the GitHub Runners settings page.

## Step 3: Configure GitHub Secrets

Navigate to your repository's `Settings` > `Secrets and variables` > `Actions` and ensure the following secrets are created:

1.  **`GOOGLE_CREDENTIALS`**: Your Google Calendar API key.
2.  **`PAT_TOKEN`**: The GitHub Personal Access Token you created.
3.  **`SSH_PRIVATE_KEY`**: The full content of the private PEM key (`.pem` file) that you use to access your EC2 instances.

## Step 4: Encrypt and Store the API Key

Run the workflow to automatically seal your secret.

1.  **Get the private IP of the monitoring server**:
    ```bash
    terraform output -raw monitoring_server_private_ip
    ```

2.  **Run the workflow**:
    -   Navigate to the **Actions** tab of your GitHub repository.
    -   In the left sidebar, click the **Seal and Commit Secret** workflow.
    -   Click the **Run workflow** dropdown.
    -   Enter the private IP address from the previous step into the **Private IP of the monitoring server** field.
    -   Click the **Run workflow** button.

This will trigger the workflow on your self-hosted runner, which will generate the `kubernetes/secrets.yaml` file and commit it to the repository.

## Step 5: Deploy the Application

Once the infrastructure is running and the secret is sealed, you can deploy the application. The easiest way is to SSH into your self-hosted runner (which already has access to the cluster) and run the deployment commands.

1.  **SSH into the runner instance** (if you're not already).

2.  **Clone your repository onto the runner**:
    ```bash
    git clone https://github.com/your-org/your-repo.git
    cd your-repo
    ```

3.  **Copy the kubeconfig from the monitoring server**:
    ```bash
    # You will need the private IP of the monitoring server
    MONITORING_IP="<your-monitoring-server-private-ip>"
    scp -r ubuntu@$MONITORING_IP:/home/ubuntu/.kube ~/
    scp -r ubuntu@$MONITORING_IP:/home/ubuntu/.minikube ~/
    ```

4.  **Deploy the database**:
    ```bash
    kubectl apply -f kubernetes/database-deployment.yaml
    ```

5.  **Deploy the secret**:
    ```bash
    kubectl apply -f kubernetes/secrets.yaml
    ```

6.  **Deploy the agent**:
    ```bash
    kubectl apply -f kubernetes/agent-deployment.yaml
    ```

## Step 6: Cleanup

To tear down all the resources created by Terraform, run the following command from the `py-app-otel` directory:

```bash
terraform destroy
