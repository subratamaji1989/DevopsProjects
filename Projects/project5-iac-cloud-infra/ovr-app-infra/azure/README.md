# OVR Application - Azure Infrastructure Definitions

This directory contains the environment-specific configurations for deploying the OVR application's infrastructure on Microsoft Azure.

This repository follows a GitOps methodology. As a developer, you only need to declare the desired state of your infrastructure in the YAML files within this directory. The CI/CD pipeline, which uses modules from the `terraform-platform` repository, will automatically build, validate, and deploy the resources.

---

## 🏗️ How It Works

1.  **You**: Define *what* to build by editing the `.yaml` files in the `vars/` directory for a specific environment (e.g., `dev`).
2.  **CI/CD Pipeline**: Takes your definitions and uses the shared modules from the `terraform-platform` repository to figure out *how* to build it.
3.  **Automation**: The pipeline validates your changes, runs security checks, generates a Terraform plan, and (after approval for production) applies the changes to your Azure account.

---

## 📁 Directory Structure

The infrastructure for each environment is isolated in its own directory.

```
azure/
└── dev/
    ├── backend.tf      # Configures Terraform's remote state in Azure Storage.
    ├── provider.tf     # Defines the Azure provider and region.
    └── vars/           # Environment-specific variable definitions.
        ├── network.yaml
        ├── security.yaml
        ├── aks.yaml
        ├── app_gateway.yaml
        └── ...
```

---

## 📖 How to Modify Infrastructure

Follow these steps to add or change infrastructure resources for your application.

### Example: Adding a User Node Pool to AKS

1.  **Navigate to the Environment**:
    Open the directory for the environment you want to change, for example: `azure/dev/`.

2.  **Edit the Correct YAML File**:
    Open the relevant variable file inside the `vars/` directory. For this example, you would edit `vars/aks.yaml`.

3.  **Declare Your Change**:
    Add a new entry to the `node_pools` map. The key (`workload_pool` in this case) must be unique.

    ```yaml
    # In app-ovr-infra/azure/dev/vars/aks.yaml
    cluster:
      # ... existing cluster config
      node_pools:
        ovr_pool: # ... existing node pool
        workload_pool: # <-- Add a new unique key
          name: "workloadpool"
          vm_size: "Standard_D4s_v3"
          node_count: 2
    ```

4.  **Commit and Create a Pull Request**:
    Commit your changes to a new branch and open a pull request. The CI/CD pipeline will automatically trigger, and you will see the Terraform plan directly in your PR.

5.  **Merge**:
    Once your PR is reviewed and approved, merge it. The pipeline will then proceed to apply the changes to the `dev` environment.
