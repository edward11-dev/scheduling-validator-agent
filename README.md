# Scheduling Validator Agent

This project contains a scheduling validator agent that interacts with Google Calendar. This document outlines the steps to deploy the agent and its required infrastructure to a Minikube cluster running on an AWS EC2 instance, using a simplified and secure workflow with GitHub-hosted runners.

## Deployment Workflow

The deployment process is now simplified and more secure:

1.  **Infrastructure Provisioning**: Use Terraform to create a single AWS EC2 instance for the Minikube cluster (`monitoring-server`).
2.  **Secret Configuration**: Configure the necessary secrets in the GitHub repository, including the sealed secrets public key.
3.  **Secret Encryption**: Run the simplified GitHub Actions workflow. A GitHub-hosted runner will encrypt the API key offline using the public key and commit the resulting `SealedSecret` manifest to the repository.
4.  **Application Deployment**: Deploy the agent and its database to the Minikube cluster.

---

## Prerequisites

Before you begin, ensure you have the following:

-   An AWS account with credentials configured for your local environment.
-   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine.
-   [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured.
-   A GitHub Personal Access Token (PAT) with `repo` scope.

---

## Step 1: Infrastructure Setup

This step provisions the single EC2 instance for your Minikube cluster.

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
    This command will create the `monitoring-server` instance. It may take several minutes to complete.

## Step 2: Configure GitHub Secrets

Navigate to your repository's `Settings` > `Secrets and variables` > `Actions` and ensure the following secrets are created:

1.  **`GOOGLE_CREDENTIALS`**: Your Google Calendar API key.
2.  **`PAT_TOKEN`**: The GitHub Personal Access Token you created.
3.  **`SEALED_SECRETS_PUBLIC_KEY`**: The public key from your sealed secrets controller. To get this, SSH into your `monitoring-server` and run the `get-sealed-secrets-public-key.sh` script.

## Step 3: Encrypt and Store the API Key

Run the simplified workflow to automatically seal your secret.

1.  **Run the workflow**:
    -   Navigate to the **Actions** tab of your GitHub repository.
    -   In the left sidebar, click the **Seal Secret (Simple - No EC2 needed)** workflow.
    -   Click the **Run workflow** dropdown and then the **Run workflow** button.

This will trigger the workflow on a GitHub-hosted runner, which will generate the `kubernetes/secrets.yaml` file and commit it to the repository.

## Step 4: Deploy the Application

Once the infrastructure is running and the secret is sealed, you can deploy the application.

1.  **SSH into the monitoring server**.
    ```bash
    # You will need the public IP of the monitoring server
    MONITORING_IP="<your-monitoring-server-public-ip>"
    ssh -i /path/to/your/key.pem ubuntu@$MONITORING_IP
    ```

2.  **Clone your repository onto the server**:
    ```bash
    git clone https://github.com/your-org/your-repo.git
    cd your-repo
    ```

3.  **Deploy the database**:
    ```bash
    kubectl apply -f kubernetes/database-deployment.yaml
    ```

4.  **Deploy the secret**:
    ```bash
    kubectl apply -f kubernetes/secrets.yaml
    ```

5.  **Deploy the agent**:
    ```bash
    kubectl apply -f kubernetes/agent-deployment.yaml
    ```

## Step 5: Cleanup

To tear down all the resources created by Terraform, run the following command from the `py-app-otel` directory:

```bash
terraform destroy
