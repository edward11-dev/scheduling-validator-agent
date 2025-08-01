# Scheduling Validator Agent

This project contains a scheduling validator agent that interacts with Google Calendar. This document outlines the steps to deploy the agent and its required infrastructure to a Minikube cluster running on an AWS EC2 instance.

## Deployment Workflow

The deployment process is divided into the following stages:

1.  **Infrastructure Provisioning**: Use Terraform to create an AWS EC2 instance and provision it with Minikube, Helm, and other necessary tools. The Sealed Secrets controller is also installed in the cluster.
2.  **Secret Configuration**: Configure the necessary secrets in the GitHub repository. This includes the Google API key, a GitHub Personal Access Token (PAT), and the `kubeconfig` file for accessing the cluster.
3.  **Secret Encryption**: Run a GitHub Actions workflow to encrypt the Google API key and commit the resulting `SealedSecret` manifest to the repository.
4.  **Application Deployment**: Deploy the agent and its database to the Minikube cluster using `kubectl`.

---

## Prerequisites

Before you begin, ensure you have the following:

-   An AWS account with credentials configured for your local environment.
-   [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed on your local machine.
-   [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) installed and configured.
-   A GitHub Personal Access Token (PAT) with `repo` scope.

---

## Step 1: Infrastructure Setup

This step provisions the AWS EC2 instance and the Minikube cluster.

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
    This command will create the EC2 instance and run the user data script to set up the environment. It may take several minutes to complete.

## Step 2: Configure GitHub Secrets

This project uses GitHub Actions to automate the encryption of the API key. This requires several secrets to be configured in your repository's settings (`Settings` > `Secrets and variables` > `Actions`).

1.  **`GOOGLE_CREDENTIALS`**: Your Google Calendar API key.
2.  **`PAT_TOKEN`**: The GitHub Personal Access Token you created as part of the prerequisites.

3.  **`KUBECONFIG`**: The configuration file for accessing your new Kubernetes cluster. Follow these steps to retrieve it:

    a. **Get the public IP of the EC2 instance**:
    ```bash
    terraform output -raw public_ip
    ```

    b. **Generate a self-contained `kubeconfig` file**. The default `kubeconfig` from Minikube contains paths to certificate files on the EC2 instance. These paths are not accessible from the GitHub Actions runner. Use the provided script to generate a new, self-contained `kubeconfig`.

    First, make the script executable:
    ```bash
    chmod +x scheduling-validator-agent/generate-kubeconfig.sh
    ```

    Then, run the script. Replace `INSTANCE_IP` with the IP address from the previous command and `/path/to/your/key.pem` with the path to the private key you used in the Terraform configuration.
    ```bash
    ./scheduling-validator-agent/generate-kubeconfig.sh INSTANCE_IP /path/to/your/key.pem
    ```
    This will create a new directory named `kubeconfig-YYYYMMDD-HHMMSS` containing the `kubeconfig` file.

    c. **Create the `KUBECONFIG` secret**: Copy the entire content of the `kubeconfig` file from the newly created directory and paste it into the value of a new GitHub secret named `KUBECONFIG`.

## Step 3: Encrypt and Store the API Key

Now you can run the GitHub Actions workflow to automatically seal your `GOOGLE_CREDENTIALS` secret.

1.  Navigate to the **Actions** tab of your GitHub repository.
2.  In the left sidebar, click the **Seal and Commit Secret** workflow.
3.  Click the **Run workflow** dropdown, and then click the **Run workflow** button.

This will trigger the workflow, which will generate a new `scheduling-validator-agent/kubernetes/secrets.yaml` file with your encrypted API key and commit it to the repository.

## Step 4: Deploy the Application

Once the infrastructure is running and the secret is sealed, you can deploy the application.

1.  **Configure `kubectl`**: Ensure your local `kubectl` is configured to use the `kubeconfig` file you downloaded in Step 2.
    ```bash
    export KUBECONFIG=$(pwd)/kubeconfig
    ```

2.  **Deploy the database**:
    ```bash
    kubectl apply -f scheduling-validator-agent/kubernetes/database-deployment.yaml
    ```

3.  **Deploy the secret**:
    ```bash
    kubectl apply -f scheduling-validator-agent/kubernetes/secrets.yaml
    ```

4.  **Deploy the agent**:
    ```bash
    kubectl apply -f scheduling-validator-agent/kubernetes/agent-deployment.yaml
    ```

## Step 5: Cleanup

To tear down all the resources created by Terraform, run the following command from the `py-app-otel` directory:

```bash
terraform destroy
