# 🚀 Multi-Cloud Terraform + GitOps CI/CD Blueprint


## 📑 Table of Contents

1. [Overview & Goals](#overview--goals)
2. [Architecture](#architecture)
3. [Prerequisites](#prerequisites)
4. [CI/CD Pipeline Flow](#-cicd-pipeline-flow)
5. [High-level Flow](#-high-level-flow)
6. [Repository Layout](#-repository-layout)
7. [Step-by-Step Implementation](#-step-by-step-implementation)
    1. [Setup Cloud Provider Access](#61-setup-cloud-provider-access)
    2. [Create Foundational Resources](#62-create-foundational-resources)
    3. [Build Repo A: `terraform-platform`](#63-build-repo-a-terraform-platform)
    4. Build Repo B: `app-ovr-infra`
    5. Implement Orchestration
    6. Configuring the Pipeline
    7. Pipeline Security and Roles
8. Post Validation
9. Operational & Security Best Practices
10. Troubleshooting & FAQs

---

## 🏁 Overview & Goals

**Goal:**  
Implement a reproducible CI/CD for Terraform-driven infrastructure on **AWS** and **Azure**, with robust DevSecOps validation.

- App team edits YAML var files in the application repository.
- Pipelines fetch shared modules, validate YAML schemas, merge YAML into a single JSON file, run static security checks, produce a Terraform plan artifact, require approval for production, then apply and post-validate results.

**Cloud Native Services Used:**

- **Source:** GitHub, AWS CodeCommit, or Azure Repos.
- **CI/CD:** AWS CodePipeline + CodeBuild, or Azure Pipelines.
- **Terraform Remote State:**
  - **AWS:** S3 + DynamoDB (for locking).
  - **Azure:** Azure Storage Account.
- **Compute:** AWS EKS, Azure AKS, or Virtual Machines on either cloud.
- **Notifications:** AWS SNS or other notification services (e.g., Slack via webhook).

This README provides exact commands, sample files, and build specifications for an end-to-end multi-cloud implementation.

---

## 🏗️ Architecture

```
+----------------+         +-------------------+         +---------------------------------+
|   Developer    |  Push   |   Repo B (App)    |         |   Repo A (Terraform Platform)   |
+----------------+ ------> +-------------------+         +---------------------------------+
                                   |                             |
                                   +-------------+---------------+
                                                 |
                                        +-------------------+
                                        |   CodePipeline    |
                                        +-------------------+
                                                 |
         +-------------------+---------+---------+---------+-------------------+
         |                   |         |         |         |                   |
+----------------+  +----------------+  +----------------+  +----------------+
| CodeBuild      |  | CodeBuild      |  | Manual Approval|  | CodeBuild      |
| (Validate)     |  | (Plan)         |  | (Prod Only)    |  | (Apply)        |
+----------------+  +----------------+  +----------------+  +----------------+
                                                 |
                                        +-------------------+
                                        | CodeBuild (Post)  |
                                        +-------------------+
                                                 |
                                        +-------------------+
                                        | SNS / Slack       |
                                        +-------------------+
```

**Key Artifacts:**
- `generated/all.tfvars.json` — merged variables from YAML files in the application repository
- `tfplan` — binary plan artifact published to S3/CodePipeline artifacts
- `precheck.json` / `plan.json` — Terraform show -json outputs for OPA/Conftest

---

## 🚦 CI/CD Pipeline Flow

### How Pipelines Are Created and Used

1. **Source Stage**
    - Triggered by a push to the application repository.
    - CodePipeline fetches both the application and platform repositories.

2. **Validate Stage (CodeBuild)**
    - Validates YAML files against JSON schemas from the platform repository.
    - Merges YAML files into a single `all.tfvars.json` file using a custom script.
    - Runs Terraform init (with a temporary backend) and creates a precheck plan.
    - Runs DevSecOps checks: tflint, tfsec, checkov, conftest.

3. **Plan Stage (CodeBuild)**
    - Runs `terraform init` with the real remote state backend (e.g., AWS S3 or Azure Storage).
    - Runs `terraform plan` and outputs a binary plan file (e.g., `prod.tfplan`).
    - Publishes artifacts to CodePipeline.

4. **Manual Approval Stage**
    - Required for production deployments.
    - Approvers review the plan and approve or reject.

5. **Apply Stage (CodeBuild)**
    - On approval, runs `terraform apply` using the plan artifact from the previous stage.

6. **Post Validation Stage (CodeBuild)**
    - Runs cloud-native CLI commands (e.g., AWS CLI or Azure CLI) and custom scripts to validate resources.
    - Notifies stakeholders via a notification service (e.g., AWS SNS or Slack).

### How to Create the Pipeline

- Use AWS Console or CloudFormation to create a CodePipeline with the above stages.
- Each CodeBuild stage uses its own `buildspec.yml`.
- Artifacts are passed between stages using CodePipeline’s artifact store.
- Manual approval is configured in the pipeline for production environments.

---

## 📝 Prerequisites

- AWS account & administrative permissions to create:
    - S3, DynamoDB, IAM, CodeBuild, CodePipeline, EKS, etc.
- Azure subscription & administrative permissions to create:
    - Storage Accounts, App Service, AKS, etc.
- Tools (local / build images):
    - Terraform 1.4+ (CLI)
    - Python 3.8+ (for custom scripts)
    - `jq`, `aws-cli` v2, `az` CLI, `yq` (optional), `ajv-cli` (for JSON schema), `tflint`, `tfsec`, `checkov`, `conftest`.
- GitHub repo(s) or AWS CodeCommit for:
    - terraform-platform (Repo A)
    - app-ovr-infra (Repo B)
- Slack incoming webhook or other notification channel (optional)
- (Optional) Docker and ECR for building images (if your pipeline scans containers)

> **Tip:** Use a small test AWS account for first bootstrapping.

---

## 🔄 High-level Flow

1. **Developer pushes YAML var files to the application repository.**
2. **Pipeline clones both repositories.**
3. **Validate stage:**
    - Validate YAML files against JSON schemas in the platform repository.
    - Merge YAML into a single JSON file.
    - Run Terraform init (with a temporary backend) and create a precheck plan.
    - Produce `precheck.json` and run static analysis tools.
4. **Plan stage:**
    - Run `terraform init` with the real remote state backend and create a plan.
    - Publish artifacts to CodePipeline.
5. **Approval stage (manual for production).**
6. **Apply stage:**
    - Apply the infrastructure using the approved plan artifact.
7. **Post validation:**
    - Run targeted AWS CLI checks for resources created/changed.
    - Notify stakeholders.

---

## 📁 Repository Layout

### Repo A: terraform-platform (shared)

```
terraform-platform/
├── aws/
│   ├── modules/
│   │   ├── network/
│   │   └── vm/
│   ├── infra-stack/
│   │   └── vm-stack/
│   ├── pipelines/
│   │   └── buildspec.validate.yml
│   └── schemas/
│       └── vm.schema.json
├── azure/
│   ├── modules/
│   │   ├── aks/
│   │   └── network/
│   ├── infra-stack/
│   │   ├── aks-stack/
│   │   └── vm-stack/
│   └── pipelines/
│       └── buildspec.validate.yml
└── tools/
    └── yaml2tfvars.py
```

### Repo B: app-ovr-infra (app config repo)

```
app-ovr-infra/
├── aws/
│   └── dev/
│       ├── backend.tf
│       ├── provider.tf
│       └── vars/
│           ├── network.yaml
│           └── vm.yaml
└── azure/
    └── dev/
        ├── backend.tf
        ├── provider.tf
        └── vars/
            ├── aks.yaml
            └── network.yaml
```

---

## 🛠️ Step-by-Step Implementation

### 6.1. Setup Cloud Provider Access

#### For AWS

For local development, the recommended approach is to use AWS CLI profiles.

1.  **Install AWS CLI**: Ensure the AWS CLI is installed.
2.  **Configure a Profile**: Run `aws configure --profile <profile-name>` (e.g., `dev-iac`) and provide your Access Key ID and Secret Access Key.
    ```bash
    aws configure --profile dev-iac
    ```
3.  **Set Environment Variable**: Before running your scripts, set the `AWS_PROFILE` environment variable.
    ```powershell
    # In PowerShell
    $env:AWS_PROFILE="dev-iac"
    ```
    ```bash
    # In Bash
    export AWS_PROFILE="dev-iac"
    ```

For CI/CD pipelines, use IAM Roles attached to your compute (e.g., CodeBuild) to provide temporary, secure credentials.

#### For Azure

For local development, the recommended approach is to use the Azure CLI.

1.  **Install Azure CLI**: Ensure the Azure CLI is installed.
2.  **Login**: Run `az login` to authenticate interactively through your browser.
    ```bash
    az login
    ```

For CI/CD pipelines, use a Service Principal with a client secret or certificate, and grant it the necessary permissions on your Azure subscription.

### 6.2. Create Foundational Resources

**For AWS:**
- Sign in to the AWS Management Console.
- Choose a region for infrastructure (e.g., `us-east-2`).
- Create an S3 bucket for artifacts & remote state (pick unique name). Use encryption and block public access.
- Create a DynamoDB table for Terraform state locking.

**For Azure:**
- Sign in to the Azure Portal.
- Create a Resource Group.
- Create a Storage Account within the resource group to store Terraform remote state.

### 6.3. Build Repo A: `terraform-platform`

- Create reusable, cloud-specific modules under `aws/modules/` and `azure/modules/`.
- Add JSON Schemas under `aws/schemas/` for YAML validation.
- Create compositions under `aws/infra-stack/` and `azure/infra-stack/` that orchestrate the modules.

### 6.4. Build Repo B: `app-ovr-infra`

- Add cloud-specific directories (`aws/`, `azure/`).
- Within each, create environment directories (`dev/`, `qa/`, etc.).
- Place `provider.tf`, `backend.tf`, and `vars/*.yaml` files within each environment directory.

### 6.5. Implement Orchestration

### 6.5. 🤖 Implementing Orchestration & DevSecOps

This is where the magic happens. We connect our infrastructure code to an automated workflow that validates, secures, and prepares it for deployment. This is achieved through a combination of utility scripts and a detailed build specification.

#### Python Utility Scripts

This project utilizes Python scripts to handle complex logic that would be cumbersome to write in pure shell script.

##### `tools/yaml2tfvars.py`

*   **Purpose**: This script is the bridge between human-friendly YAML configuration and Terraform's required JSON variable format. It recursively finds all `.yaml` and `.yml` files in a specified input directory, merges them into a single dictionary, and outputs a `terraform.tfvars.json` file.
*   **Why it's needed**: It allows developers to split complex configurations into smaller, more manageable YAML files (e.g., `network.yaml`, `vm.yaml`). This is much cleaner than managing a single, monolithic variables file.
*   **Usage (from `buildspec.yml`)**:
    ```bash
    # This command takes the input directory of YAML files and the output path for the JSON file.
    python terraform-platform/tools/yaml2tfvars.py app-ovr-infra/aws/dev/vars generated/all.tfvars.json
    ```

##### Conceptual Orchestration Scripts (`awsIaCplan.py` & `azureIaCplan.py`)

While the current `buildspec.yml` embeds the orchestration logic directly, a more advanced pattern is to use dedicated Python scripts (`awsIaCplan.py`, `azureIaCplan.py`) to act as the main engine. These scripts would be responsible for calling `yaml2tfvars.py`, running the `terraform` commands, and handling error logic, providing a more structured and testable approach to orchestration.

#### The Gauntlet: CI/CD Build Specification (`buildspec.validate.yml`)

*   **What:** This file is a recipe of commands that your build agent (e.g., AWS CodeBuild) follows. It's the heart of your DevSecOps process, designed to run a gauntlet of checks to catch errors and vulnerabilities early.
*   **Where:** A `buildspec.validate.yml` exists for both AWS and Azure under `terraform-platform/aws/pipelines/` and `terraform-platform/azure/pipelines/`.
*   **Key Steps inside the `buildspec`:**
    1.  **Install Phase:** Sets up the build environment by installing Python dependencies and all necessary DevSecOps CLI tools (`tflint`, `tfsec`, `checkov`, `conftest`, `ajv-cli`).
    2.  **Build Phase:** This is where the main logic resides.
        -   **Schema Validation:** Use `ajv-cli` to validate an application's primary YAML file against its JSON schema. This catches structural errors instantly.
            ```bash
            ajv validate -s terraform-platform/aws/schemas/vm.schema.json -d app-ovr-infra/aws/dev/vars/vm.yaml
            ```
        -   **YAML Merging:** Execute the `yaml2tfvars.py` script to combine all YAML files into `generated/all.tfvars.json`.
            ```bash
            python terraform-platform/tools/yaml2tfvars.py app-ovr-infra/aws/dev/vars generated/all.tfvars.json
            ```
        -   **Terraform Dry Run:** The script changes into the target composition directory (e.g., `terraform-platform/aws/infra-stack/vm-stack`) and runs `terraform init` and `terraform plan` with a local backend.
            ```bash
            cd terraform-platform/aws/infra-stack/vm-stack
            terraform init -backend=false
            terraform plan -var-file=../../../generated/all.tfvars.json -out=precheck.tfplan
            ```
        -   **DevSecOps Scanning:** The plan's JSON output is then scanned by a suite of security tools. This is the "Sec" in DevSecOps.
            ```bash
            terraform show -json precheck.tfplan > precheck.json
            tflint
            tfsec .
            checkov -d .
            conftest test precheck.json --policy ../../policies/conftest
            ```
    3.  **Artifacts:** The `artifacts` block packages the `precheck.tfplan` and `precheck.json` files, making them available for review or for the next stage in the pipeline.

### 6.6. 🚀 Configuring the CI/CD Pipeline

A CI/CD pipeline automates the entire process, from code commit to infrastructure deployment. The recommended approach is to have a primary pipeline definition in the application repository (`app-ovr-infra`) that calls reusable templates from the platform repository (`terraform-platform`).

#### Pattern 1: Azure DevOps with YAML Templates

1.  **Create Template Pipeline in `terraform-platform`:**
    -   Create a file like `terraform-platform/azure/pipelines/template.yml`.
    -   This template defines the reusable stages: Validate, Plan, and Apply. It accepts parameters like `compositionPath` and `environmentType`.

2.  **Create Main Pipeline in `app-ovr-infra`:**
    -   Create an `azure-pipelines.yml` file in the root of `app-ovr-infra`.
    -   This file checks out both repositories and calls the template, passing the correct parameters for the specific application and environment.
        ```yaml
        # In app-ovr-infra/azure-pipelines.yml
        trigger:
        - main

        resources:
          repositories:
            - repository: platform # Alias for the platform repo
              type: github # or azuredevops
              name: YourOrg/terraform-platform

        stages:
        - template: azure/pipelines/template.yml@platform # Call the template
          parameters:
            compositionPath: 'terraform-platform/azure/infra-stack/aks-stack'
            varsPath: 'app-ovr-infra/azure/dev/vars'
            environmentType: 'dev'
        ```

#### Pattern 2: AWS CodePipeline with Centralized Buildspecs

While AWS CodePipeline is often configured via the AWS Console or CloudFormation, you can achieve the exact same "template" pattern. Here, the `buildspec.yml` files in your `terraform-platform` repository act as the reusable templates, and the CodePipeline's CodeBuild project definition passes the parameters via environment variables.

1.  **Centralized Buildspecs (The "Templates"):**
    -   Your `terraform-platform/aws/pipelines/buildspec.yml` and other `buildspec` files are your reusable templates. They contain the logic for installing tools, running scans, and executing Terraform commands.

2.  **Pipeline Definition in `app-ovr-infra` (The "Caller"):**
    -   You can define your pipeline using a tool like the AWS CDK or CloudFormation, or configure it via the console. The key is how you configure the CodeBuild project within your pipeline stages.
    -   This pipeline will live in or be associated with the `app-ovr-infra` repository, as it is specific to that application's deployment lifecycle.

**Example CodePipeline Stage Configuration (Conceptual):**

Here is how you would configure the "Validate" stage in your CodePipeline to call the "template" `buildspec.yml` from the platform repository.

-   **Action Provider:** `AWS CodeBuild`
-   **Input Artifacts:**
    -   `AppRepo` (from your `app-ovr-infra` source action)
    -   `PlatformRepo` (from your `terraform-platform` source action)
-   **Project Configuration:**
    -   **Buildspec Location:** Point to the buildspec file inside the `PlatformRepo` input artifact.
        -   `terraform-platform/aws/pipelines/buildspec.yml`
    -   **Environment Variables (The "Parameters"):** This is where you pass the application-specific details to the generic template.

        | Variable Name       | Value                                                | Description                                                              |
        | ------------------- | ---------------------------------------------------- | ------------------------------------------------------------------------ |
        | `COMPOSITION_PATH`  | `terraform-platform/aws/infra-stack/vm-stack`        | Tells the template which infrastructure stack to build.                  |
        | `VARS_PATH`         | `app-ovr-infra/aws/dev/vars`                         | Tells the template where to find the YAML variables for this application.|
        | `SCHEMA_PATH`       | `terraform-platform/aws/schemas/vm.schema.json`      | Specifies the schema for validation.                                     |

By using this method, you maintain a clean separation of concerns:
-   **`terraform-platform`** owns the *how* (the build logic and templates).
-   **`app-ovr-infra`** owns the *what* (the pipeline definition and the specific parameters for the application).

This allows you to have many different application pipelines in different repositories all calling the same, centrally managed build templates, which is the core benefit of the pattern you described.

### 6.7. Pipeline Security and Roles

Following the principle of least privilege is critical for a secure IaC pipeline. Each stage should only have the permissions it absolutely needs.

#### For AWS (using IAM Roles)

Create three distinct IAM Roles for your CodeBuild projects.

-   **`validate-role`**: This role needs minimal permissions. It only requires read access to the source repositories (e.g., CodeCommit) and permissions to write logs to CloudWatch. It should **not** have any permissions to access your cloud resources or Terraform state.
-   **`plan-role`**: This role needs the permissions of the `validate-role`, plus **read-only** access to your Terraform state backend.
    -   `s3:GetObject` on the state file (`arn:aws:s3:::<bucket-name>/path/to/terraform.tfstate`).
    -   `dynamodb:GetItem` on the lock table (`arn:aws:dynamodb:<region>:<account-id>:table/<table-name>`).
-   **`apply-role`**: This is the most privileged role. It needs the permissions of the `plan-role`, plus **write access** to the Terraform state backend and permissions to manage the target cloud resources.
    -   `s3:PutObject` on the state file.
    -   `dynamodb:PutItem` and `dynamodb:DeleteItem` on the lock table.
    -   Permissions to manage target resources (e.g., `ec2:*`, `eks:*`, `vpc:*`).

#### For Azure (using Service Principals)

Create one or more Service Principals (SPs) with specific role assignments.

-   **`validate-principal`**: This SP requires no Azure permissions. It only needs access to the source code repository.
-   **`plan-principal`**: This SP needs read-only access to the Terraform state.
    -   Assign the `Storage Blob Data Reader` role to this SP on the storage container holding the state file.
-   **`apply-principal`**: This is the most privileged SP. It needs the permissions of the `plan-principal`, plus write access to the state and permissions to manage the target resources.
    -   Assign the `Storage Blob Data Contributor` role on the state container.
    -   Assign the `Contributor` role (or a more restrictive custom role) on the subscription or resource group where the infrastructure will be deployed.

---

## 🕵️ Post Validation

After a successful `terraform apply`, the "Post Validation" stage in your pipeline should programmatically verify that the deployed resources are healthy and operational. This provides immediate feedback without requiring manual checks in the cloud console.

#### For AWS

-   **Check EC2 Instance Health:** Verify that a newly created virtual machine has passed its status checks.
    ```bash
    aws ec2 describe-instance-status --instance-ids <instance-id> --query "InstanceStatuses[0].InstanceStatus.Status"
    ```
-   **Verify Load Balancer State:** Ensure the Application Load Balancer is active and ready to receive traffic.
    ```bash
    aws elbv2 describe-load-balancers --names <lb-name> --query "LoadBalancers[0].State.Code"
    ```

#### For Azure

-   **Check VM Power State:** Confirm that a new virtual machine is running.
    ```bash
    az vm get-instance-view --name <vm-name> -g <resource-group> --query "instanceView.statuses[?code=='PowerState/running']"
    ```
-   **Verify Application Gateway Health:** Check the health of the backend pool associated with the Application Gateway.
    ```bash
    az network application-gateway show-backend-health --name <app-gateway-name> -g <resource-group>
    ```

---

## 🔒 Operational & Security Best Practices

-   **State Management:**
    -   **AWS:** Always use an S3 bucket with encryption at rest (`aws:kms`), versioning, and "Block public access" enabled. Use a DynamoDB table for state locking to prevent concurrent modifications.
    -   **Azure:** Use a dedicated Azure Storage Account with encryption at rest enabled and access restricted to specific service principals or IP ranges.
-   **Secrets Management:**
    -   Never hardcode secrets (passwords, API keys) in your `.tf` or `.tfvars` files.
    -   **AWS:** Use AWS Secrets Manager or SSM Parameter Store (SecureString) and reference them using `data` sources in Terraform.
    -   **Azure:** Use Azure Key Vault and reference secrets using `data` sources.
-   **Network Security:**
    -   **AWS:** Employ a multi-layered approach with Security Groups (stateful) to control traffic to instances and Network ACLs (stateless) to control traffic at the subnet level.
    -   **Azure:** Use Network Security Groups (NSGs) to filter traffic to and from Azure resources in a virtual network. Use Application Security Groups (ASGs) to group VMs and define network security policies based on those groups.
-   **Cost Management:**
    -   Apply a consistent tagging strategy to all resources for both AWS and Azure. Use tags to track costs by project, team, or environment.

---

## 🛠️ Troubleshooting & FAQs

-   **Error: `Provider version mismatch` or `Unsupported argument`**
    -   **Cause:** Your local Terraform environment or a module is using a different provider version than what is defined in the configuration.
    -   **Solution:** Delete the `.terraform` directory and the `.terraform.lock.hcl` file in your composition directory, then run `terraform init` again. This forces Terraform to re-evaluate all provider dependencies based on your configuration's version constraints.
-   **Error: `Error acquiring the state lock`**
    -   **Cause:** Another Terraform process (or a failed one) is holding a lock on your remote state file.
    -   **Solution:** First, ensure no other pipeline or user is running `apply`. If you are certain the lock is stale, you can use `terraform force-unlock <LOCK_ID>` to manually remove it. Use this command with extreme caution.
-   **Pipeline `plan` or `apply` stage fails with `403 Forbidden` or `Unauthorized` errors.**
    -   **Cause:** The IAM Role (for AWS) or Service Principal (for Azure) used by your CI/CD pipeline's build agent lacks the necessary permissions to read the state file or modify cloud resources.
    -   **Solution:** Review the permissions for your `plan-role` and `apply-role` as described in the "Pipeline Security and Roles" section. Ensure they have the correct read/write access to the state backend and the target resources.