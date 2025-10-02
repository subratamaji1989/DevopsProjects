# Terraform Cheat Sheet (Beginner → Expert)

> A practical reference covering installation, basics, HCL syntax, providers, resources, modules, state management, workspaces, Terraform Cloud, debugging, and best practices.

---

## Table of Contents

1. Introduction & Installation
2. Terraform CLI Basics
3. HCL Language & Syntax
4. Providers & Resources
5. Variables & Outputs
6. State Management
7. Modules
8. Workspaces & Environments
9. Provisioners & Data Sources
10. Terraform Cloud & Remote Backends
11. Debugging & Troubleshooting
12. Security & Best Practices
13. Useful Commands Summary

---

# 1. Introduction & Installation

**What is Terraform?**

* Open-source Infrastructure as Code (IaC) tool by HashiCorp.
* Declaratively provisions and manages infrastructure across cloud providers and services.

**Core concepts**

* Provider: plugin for a service (AWS, Azure, GCP, etc).
* Resource: infrastructure object managed by Terraform.
* Module: collection of resources as a reusable unit.
* State: snapshot of current infrastructure.

**Install**

* Download binary from [terraform.io](https://www.terraform.io/downloads).
* Or use package managers: `brew install terraform` (macOS), `choco install terraform` (Windows).
* Verify: `terraform -version`

---

# 2. Terraform CLI Basics

**Workflow**

1. Write `.tf` configuration files.
2. `terraform init` → initialize provider plugins.
3. `terraform plan` → preview changes.
4. `terraform apply` → apply changes.
5. `terraform destroy` → destroy resources.

**Common commands**

```bash
terraform init
terraform plan
terraform apply
terraform destroy
terraform validate
terraform fmt
terraform providers
```

---

# 3. HCL Language & Syntax

**Basic resource**

```hcl
resource "aws_instance" "web" {
  ami           = "ami-123456"
  instance_type = "t2.micro"
}
```

**Blocks**

* `provider` → configure provider.
* `resource` → declare infrastructure object.
* `variable` → define input variable.
* `output` → define outputs.
* `module` → use external module.

**Expressions**

* Interpolation: `${var.name}` or simply `var.name`
* Functions: `length(list)`, `lower(string)`, `file(path)`, `lookup(map,key)`
* Conditionals: `condition ? true_val : false_val`

---

# 4. Providers & Resources

**Provider example (AWS)**

```hcl
provider "aws" {
  region = "us-east-1"
}
```

**Resource example**

```hcl
resource "aws_s3_bucket" "mybucket" {
  bucket = "my-unique-bucket"
  acl    = "private"
}
```

**Multiple providers**

```hcl
provider "aws" {
  region = "us-east-1"
}
provider "aws" {
  alias  = "west"
  region = "us-west-2"
}

resource "aws_instance" "east" {
  provider = aws
  # ...
}

resource "aws_instance" "west" {
  provider = aws.west
  # ...
}
```

---

# 5. Variables & Outputs

**Variable definition**

```hcl
variable "instance_type" {
  type    = string
  default = "t2.micro"
  description = "EC2 instance type"
}
```

**Usage**

```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type
}
```

**Output**

```hcl
output "public_ip" {
  value = aws_instance.web.public_ip
}
```

**Passing variables**

```bash
terraform apply -var="instance_type=t3.small"
terraform apply -var-file=prod.tfvars
```

---

# 6. State Management

**State basics**

* `terraform.tfstate` holds current state of infrastructure.
* Must be stored securely and shared if working in teams.

**Commands**

```bash
terraform state list
terraform state show aws_instance.web
terraform state mv old new
terraform state rm aws_s3_bucket.old
```

**Remote state**

* Store in S3, GCS, or Terraform Cloud.
* Use DynamoDB (AWS) for state locking.

---

# 7. Modules

**Using a module**

```hcl
module "network" {
  source = "./modules/network"
  vpc_cidr = "10.0.0.0/16"
}
```

**From registry**

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  cidr    = "10.0.0.0/16"
}
```

**Best practices**

* Keep modules small and composable.
* Version pinning for registry modules.

---

# 8. Workspaces & Environments

**Workspaces**

* Allow multiple state files within the same config.

**Commands**

```bash
terraform workspace list
terraform workspace new dev
terraform workspace select prod
```

**Use in code**

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "mybucket-${terraform.workspace}"
}
```

---

# 9. Provisioners & Data Sources

**Provisioners (last resort)**

```hcl
resource "aws_instance" "web" {
  provisioner "local-exec" {
    command = "echo Hello from local-exec"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
}
```

**Data sources**

```hcl
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
}
```

---

# 10. Terraform Cloud & Remote Backends

**Remote backends**

* S3, GCS, Azure Storage, Consul, Terraform Cloud.

**Terraform Cloud**

* Remote runs, state storage, versioning, team collaboration.
* Free tier available.

**Backend config example**

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

---

# 11. Debugging & Troubleshooting

**Logging**

```bash
export TF_LOG=DEBUG
terraform apply
```

**Dry run**

```bash
terraform plan -out=tfplan
terraform show tfplan
```

**Inspect state**

```bash
terraform state list
terraform show
```

**Common issues**

* Drift: infra changed outside Terraform → run `terraform plan` to detect.
* Provider version mismatches → pin versions.
* Lock contention on state → use remote locking.

---

# 12. Security & Best Practices

* Never commit `terraform.tfstate` to Git (contains secrets).
* Use `.terraformignore` and `.gitignore`.
* Use remote state with encryption.
* Use variables + secret stores for sensitive data (Vault, AWS Secrets Manager).
* Pin provider and module versions.
* Format & validate configs: `terraform fmt`, `terraform validate`.
* Organize code: separate modules, environments.

---

# 13. Useful Commands Summary

**Init & config**

```bash
terraform init
terraform validate
terraform fmt
```

**Plan & apply**

```bash
terraform plan
terraform apply
terraform destroy
```

**State**

```bash
terraform state list
terraform state show
terraform refresh
```

**Workspaces**

```bash
terraform workspace list
terraform workspace new staging
terraform workspace select staging
```

**Modules & providers**

```bash
terraform providers
terraform get
terraform init -upgrade
```

**Debugging**

```bash
terraform plan -out plan.out
terraform show plan.out
export TF_LOG=DEBUG
```

---

# Quick Reference: One-liners

* Initialize + upgrade providers:

```bash
terraform init -upgrade
```

* Show resources in state:

```bash
terraform state list
```

* Apply only one resource:

```bash
terraform apply -target=aws_instance.web
```

* Destroy specific resource:

```bash
terraform destroy -target=aws_s3_bucket.mybucket
```

---

*End of cheat sheet — happy Terraforming!*
