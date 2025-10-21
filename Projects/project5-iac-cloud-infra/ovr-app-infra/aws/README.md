# OVR Application - AWS Infrastructure Definitions

This directory contains the environment-specific configurations for deploying the OVR application's infrastructure on Amazon Web Services (AWS).

This repository follows a GitOps methodology. As a developer, you only need to declare the desired state of your infrastructure in the YAML files within this directory. The CI/CD pipeline, which uses modules from the `terraform-platform` repository, will automatically build, validate, and deploy the resources.

---

## 🏗️ How It Works

1.  **You**: Define *what* to build by editing the `.yaml` files in the `vars/` directory for a specific environment (e.g., `dev`).
2.  **CI/CD Pipeline**: Takes your definitions and uses the shared modules from the `terraform-platform` repository to figure out *how* to build it.
3.  **Automation**: The pipeline validates your changes, runs security checks, generates a Terraform plan, and (after approval for production) applies the changes to your AWS account.

---

## 📁 Directory Structure

The infrastructure for each environment is isolated in its own directory.

```
aws/
└── dev/
    ├── backend.tf      # Configures Terraform's remote state in AWS S3.
    ├── provider.tf     # Defines the AWS provider and region.
    └── vars/           # Environment-specific variable definitions.
        ├── network.yaml
        ├── security.yaml
        ├── eks.yaml
        ├── lb.yaml
        └── ...
```

---

## 📖 How to Modify Infrastructure

Follow these steps to add or change infrastructure resources for your application.

### Example: Adding a Security Group Rule

1.  **Navigate to the Environment**:
    Open the directory for the environment you want to change, for example: `aws/dev/`.

2.  **Edit the Correct YAML File**:
    Open the relevant variable file inside the `vars/` directory. For this example, you would edit `vars/security.yaml`.

3.  **Declare Your Change**:
    Add the new rule to the `rules` list for the appropriate security group.

    ```yaml
    # In app-ovr-infra/aws/dev/vars/security.yaml
    security_groups:
      app_sg:
        # ... existing rules
        rules:
          - type: "ingress"
            from_port: 5432
            to_port: 5432
            protocol: "tcp"
            source_sg_key: "db_sg" # Allow traffic from the DB security group
    ```

4.  **Commit and Create a Pull Request**:
    Commit your changes to a new branch and open a pull request. The CI/CD pipeline will automatically trigger, and you will see the Terraform plan directly in your PR.

5.  **Merge**:
    Once your PR is reviewed and approved, merge it. The pipeline will then proceed to apply the changes to the `dev` environment.

