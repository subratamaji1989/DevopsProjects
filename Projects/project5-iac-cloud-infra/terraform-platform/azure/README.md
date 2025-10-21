# 🚀 Terraform Platform Overview -- Azure

---

## 📑 Table of Contents

1. [Introduction](#introduction)
2. [Infrastructure Flow (GitOps IaC)](#infrastructure-flow-gitops-iac)
3. [Modules](#modules)
    - [Network Module](#network-module)
    - [VM Module](#vm-module)
    - [Storage Module](#storage-module)
    - [Load Balancer Module](#load-balancer-module)
4. [Compositions](#compositions)
5. [Schemas](#schemas)
6. [Tools](#tools)
7. [Pipelines](#pipelines)
8. [Usage](#usage)
9. [RBAC Permissions](#rbac-permissions)

---

## 🏁 Introduction

The Terraform Platform provides a set of reusable modules and compositions for managing Azure infrastructure using Terraform. This project aims to streamline the process of deploying and managing cloud resources, ensuring best practices and modularity.

---

## 🌊 Infrastructure Flow (GitOps IaC)

The infrastructure deployment utilizes a Code Repository for all declarative configuration, ensuring Git is the Single Source of Truth (SSOT).

| Step | Component        | Tool/Service                                | Description & DevSecOps Principle                                                                                                                                                           |
| :--- | :--------------- | :------------------------------------------ | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1.   | **Commit IaC**   | `infra-repo` Git (e.g., Azure Repos/GitHub) | Developer commits Terraform code (for VNet, AKS, App Gateway) to a main branch via Pull Request (PR).                                                                                       |
| 2.   | **Validate IaC** | CI/CD Pipeline (Azure Pipelines)            | **IaC Scanning (Shift-Left Security):** Runs `Checkov` to scan for misconfigurations (e.g., public storage accounts, permissive NSGs) and `TFLint` for syntax validation.                   |
| 3.   | **Approval**     | PR Review (Azure Repos/GitHub)              | Requires a DevSecOps Architect and SRE approval to ensure security and operational best practices.                                                                                        |
| 4.   | **Apply IaC**    | CD Tool (Terraform)                         | Merged PR triggers the pipeline to run `terraform apply`. The AKS cluster, its Node Pools, and supporting services (VNet, App Gateway) are provisioned.                                     |
| 5.   | **Bootstrap GitOps** | Terraform / Helm                          | ArgoCD is installed into the new AKS cluster, and its configuration is pointed to the `app-manifests-repo`.                                                                               |

---

## 🛠️ Modules

-   ### Network Module

The Network module defines resources such as Virtual Networks (VNets), subnets, and Network Security Groups (NSGs). It allows for the creation and management of network infrastructure.

-   ### VM Module

The VM module is responsible for defining Virtual Machines and their associated disks. It provides a way to manage virtual machines in the Azure environment.

-   ### Storage Module

The Storage module defines resources for managing Azure Storage Accounts and blob containers. It facilitates the storage and retrieval of data in the cloud.

-   ### Load Balancer Module

The Load Balancer module manages resources for Application Gateways or Azure Load Balancers. It ensures high availability and scalability for applications.

---

## 🏗️ Compositions

Compositions are the top-level infrastructure definitions that assemble reusable modules into a complete, deployable stack (e.g., a `vm-stack` that combines the `network`, `vm`, and `load-balancer` modules).
*   **Why it's needed**: Compositions allow you to define a complete environment by orchestrating modules, promoting reuse and preventing configuration drift. They represent the "what to build," while modules represent the "how to build it."
*   **Usage**: A developer defines a new stack by creating a directory under `compositions/`. Inside, a `main.tf` file calls the necessary modules and passes variables to them. The CI/CD pipeline targets a specific composition using the `COMPOSITION_PATH` variable defined in `pipeline-vars.yml`.

---

## 📜 Schemas

The `schemas` directory contains JSON Schema files used to validate the structure and data types of your YAML variable files.
*   **Why it's needed**: Schemas enforce a contract for your configuration, catching errors like typos, incorrect data types, or missing required fields *before* Terraform runs. This "shift-left" approach to validation prevents simple configuration mistakes from causing a pipeline failure during the `plan` or `apply` stage.
*   **Usage**: For a given YAML file (e.g., `vm-stack.yml`), you create a corresponding `vm-stack.schema.json` file. The `azure-pipelines.yml` automatically uses the `ajv-cli` tool during the `VALIDATE` stage to check that the YAML file conforms to its schema.
*   **Reference**: This is implemented in the `validate_yaml_files` function within the `build` phase of the pipeline template.

---

## 🛠️ Tools

This directory contains helper scripts that provide "glue" logic for the CI/CD pipeline.
*   **`yaml2tfvars.py`**: A Python script that merges a directory of YAML variable files into a single `all.tfvars.json` file.
*   **Why it's needed**: This tool bridges the gap between human-friendly YAML (which supports comments and a cleaner structure) and Terraform's required JSON format for variable files (`-var-file`). It allows developers to manage configuration in a more readable format.
*   **Usage**: The script is called automatically by the pipeline template during the `build` phase before any `terraform` commands are run.

---

## 🔄 Pipelines

The pipelines directory contains build specifications for the CI/CD pipeline, defining the steps for validation, planning, applying, and post-validation of Terraform configurations.

### Key Features

-   **Dynamic Configuration**: The pipeline's behavior is controlled by a `pipeline-vars.yml` file. This file defines environment variables (`CLOUD`, `STACK_NAME`, `TF_VERSION`, etc.) that are loaded at runtime, allowing the same pipeline template to be used for multiple environments and stacks.
-   **Staged Execution**: The pipeline can be run in different modes by setting the `PIPELINE_STAGE` environment variable. This allows for granular control over the workflow. Supported stages are:
    -   `VALIDATE`: Performs schema validation, security scans, and a dry-run `terraform plan`.
    -   `PLAN`: Initializes the backend and generates a production `terraform plan`.
    -   `APPLY`: Applies a previously generated plan file.
    -   `POST_VALIDATE`: Runs checks after a successful deployment.
    -   `ALL` (default): Runs all stages sequentially.
-   **Automated Tooling**: The `install` phase automatically downloads and caches specific versions of `terraform`, `tflint`, `tfsec`, and other dependencies, ensuring a consistent and fast execution environment.
-   **Integrated Security (DevSecOps)**: During the `VALIDATE` stage, the pipeline automatically runs `tflint` and `tfsec` to scan the Terraform code for misconfigurations and security vulnerabilities.
-   **Schema Validation**: Before running Terraform, the pipeline uses `ajv-cli` to validate the `.yml` variable files against their corresponding JSON schemas located in the `schemas` directory. This prevents invalid configurations from ever reaching the plan stage.

### Build Phases Explained

1.  **`install` Phase**:
    -   Sets up a local cache directory (`.local/bin`) for tools.
    -   Loads all variables from the `pipeline-vars.yml` file.
    -   Installs pinned versions of Terraform, `tflint`, `tfsec`, `yq`, and `ajv-cli`.
    -   Verifies that all tools were installed correctly.

2.  **`pre_build` Phase**:
    -   Re-exports the environment variables loaded in the `install` phase.

3.  **`build` Phase**:
    -   **Path Resolution**: Dynamically constructs the path to the correct Terraform composition based on the `CLOUD` and `STACK_NAME` variables.
    -   **Variable Merging**: Uses the `tools/yaml2tfvars.py` script to merge all relevant `.yml` files into a single `all.tfvars.json` file for Terraform.
    -   **Staged Execution**: Executes the `VALIDATE`, `PLAN`, `APPLY`, and `POST_VALIDATE` logic based on the `PIPELINE_STAGE` variable.

### How Variables are Loaded

The pipeline template uses `yq` to parse the `pipeline-vars.yml` file and `eval` to export its keys as environment variables. This happens in both the `install` and `pre_build` phases to ensure the variables are available throughout the build.

An example `pipeline-vars.yml` might look like this:

```yaml
pipeline-parameters:
  # -- Infrastructure Definition --
  APP: "app-ovr-infra"
  CLOUD: "azure"
  ENVIRONMENT: "dev"

```

The `eval` command in the pipeline ensures that a variable like `COMPOSITION_PATH` is resolved at runtime, correctly substituting `${CLOUD}` and `${STACK_NAME}` with their values.

---

## 📖 Usage  -- How to start with

To use the Terraform Platform, clone the repository and follow the instructions in the respective module and composition README files. Ensure that you have the necessary Azure credentials and permissions to create and manage resources.
1.  **Centralized Pipeline Templates:**
    -   Your `terraform-platform/azure/pipelines/` directory contains your reusable templates. They contain the logic for installing tools, running scans, and executing Terraform commands.

2.  **Pipeline Definition in `app-ovr-infra` (The "Caller"):**
    -   You define your pipeline in the `app-ovr-infra` repository using an `azure-pipelines.yml` file.
    -   This pipeline is specific to the application's deployment lifecycle.

**Example `azure-pipelines.yml` Configuration:**

Here is how you would configure your `azure-pipelines.yml` to call the "template" from the platform repository.

```yaml
# In app-ovr-infra/azure-pipelines.yml

trigger:
- main

resources:
  repositories:
    - repository: platform # Alias for the platform repo
      type: git
      name: YourProject/terraform-platform # Name of the platform repo

stages:
- stage: Deploy
  jobs:
  - template: azure/pipelines/templates/terraform-deploy.yml@platform # Call the template
    parameters:
      # Pass application-specific details to the generic template
      VARS_PATH: '$(System.DefaultWorkingDirectory)/azure/dev/vars'
      SCHEMA_PATH: '$(Build.SourcesDirectory)/platform/azure/schemas/vm.schema.json'
      COMPOSITION_PATH: '$(Build.SourcesDirectory)/platform/azure/infra-stack'
      ADO_SERVICE_CONNECTION: 'Your-Azure-Service-Connection'
```

By using this method, you maintain a clean separation of concerns:
-   **`terraform-platform`** owns the *how* (the build logic and templates).
-   **`app-ovr-infra`** owns the *what* (the pipeline definition and the specific parameters for the application).

This allows you to have many different application pipelines in different repositories all calling the same, centrally managed build templates.

---

## 🔐 RBAC Permissions

To run this Terraform platform securely, especially within a CI/CD pipeline, it's crucial to follow the principle of least privilege. The pipeline should use different Service Connections (backed by Service Principals) for different stages.

### `validate-connection`

This connection is used during the initial validation and security scanning stages. The underlying Service Principal requires **no Azure RBAC roles**.

-   **Permissions:**
    -   Read access to the source code repositories (granted by Azure DevOps).

### `plan-connection`

This connection is used to generate a Terraform plan. It needs read-only access to the Terraform state and the target subscription.

-   **Required RBAC Roles:**
    -   `Storage Blob Data Reader` on the Terraform state storage container.
    -   `Reader` on the target subscription or resource group.

**Example `az cli` Role Assignment:**
```bash
az role assignment create \
  --assignee <PLAN_SP_APP_ID> \
  --role "Storage Blob Data Reader" \
  --scope "/subscriptions/.../resourceGroups/.../providers/Microsoft.Storage/storageAccounts/.../blobServices/default/containers/tfstate"

az role assignment create \
  --assignee <PLAN_SP_APP_ID> \
  --role "Reader" \
  --scope "/subscriptions/<YOUR_SUBSCRIPTION_ID>"
```

### `apply-connection`

This is the most privileged connection, used to apply changes to your infrastructure. It needs permissions to read/write the Terraform state and manage the specific Azure resources defined in your modules.

-   **Required RBAC Roles:**
    -   `Storage Blob Data Contributor` on the Terraform state storage container.
    -   `Contributor` (or a more restrictive custom role) on the target resource group or subscription.

**Example `az cli` Role Assignment:**
```bash
az role assignment create \
  --assignee <APPLY_SP_APP_ID> \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/.../resourceGroups/.../providers/Microsoft.Storage/storageAccounts/.../blobServices/default/containers/tfstate"

az role assignment create \
  --assignee <APPLY_SP_APP_ID> \
  --role "Contributor" \
  --scope "/subscriptions/<YOUR_SUBSCRIPTION_ID>/resourceGroups/<YOUR_TARGET_RG>"
```

> **Note:** For production environments, it is highly recommended to create custom RBAC roles with only the necessary permissions (`Microsoft.Compute/virtualMachines/write`, etc.) instead of using the broad `Contributor` role.

--- 

This README serves as a guide to understanding the structure and purpose of the Terraform Platform within the Azure infrastructure as code project.
