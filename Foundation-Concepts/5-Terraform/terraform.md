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

## 3.1 Data Types in HCL

Terraform configurations use various data types, which can be categorized as primitive, collection, and structural.

### Primitive Types

These are the simplest types, representing a single value.

*   **`string`**: A sequence of Unicode characters.
    ```hcl
    variable "image_id" {
      type    = string
      default = "ami-123456"
    }
    ```
*   **`number`**: A numeric value, which can be an integer or a float.
    ```hcl
    variable "instance_count" {
      type    = number
      default = 2
    }
    ```
*   **`bool`**: A boolean value, either `true` or `false`.
    ```hcl
    variable "enable_monitoring" {
      type    = bool
      default = true
    }
    ```

### Collection Types

These types group multiple values together.

*   **`list(...)`**: An ordered sequence of elements, all of the same type.  [0,1,5,2] --> always return [0,1,5,2]
    ```hcl
    variable "subnet_ids" {
      type    = list(string)
      default = ["subnet-abcde012", "subnet-bcde012a"]
    }
    ```
*   **`map(...)`**: A collection of key-value pairs where all values are of the same type. Keys are always strings.
    ```hcl
    variable "common_tags" {
      type    = map(string)
      default = {
        "Environment" = "dev"
        "Project"     = "MyWebApp"
      }
    }
    ```
*   **`set(...)`**: A set is like a list, but it doesn't keep the order we put in. An unordered collection of unique values, all of the same type. 
    A list has [1,5,1,2], in set it becomes [1,2,5]

### Structural Types

*   **`object(...)`**: A object is like a Map, but each element can have a different type. A collection of named attributes with their own specific types.
    ```hcl
    variable "instance_config" {
      type = object({
        name = string
        type = string
        size = number
      })
    }
    ```
*   **`tuple(...)`**: A Tuple is like a list, but each element can have a different type. An ordered sequence of elements where each element can have a different type.
    ```hcl
    variable "mixed_values" {
      type    = tuple([string, number, bool])
      default = ["a", 1, true]
    }
    ```

---

## 3.2 Common Functions

| Function | Description | Example |
|---|---|---|
| **String Functions** | | |
| `lower(string)` | Converts a string to lowercase. | `lower("Hello")` → `"hello"` |
| `upper(string)` | Converts a string to uppercase. | `upper("Hello")` → `"HELLO"` |
| `join(separator, list)` | Joins list elements with a separator. | `join(",", ["a", "b"])` → `"a,b"` |
| `format(spec, args...)` | Formats a string according to a format spec. | `format("Hello, %s!", "World")` → `"Hello, World!"` |
| **Collection Functions** | | |
| `length(list/map/string)` | Returns the number of elements or characters. | `length(["a", "b"])` → `2` |
| `lookup(map, key, [default])`| Retrieves a value from a map, with an optional default. | `lookup({"a":1}, "b", 0)` → `0` |
| `merge(map1, map2, ...)` | Merges multiple maps into one. Later maps override earlier ones. | `merge({a=1}, {b=2})` → `{a=1, b=2}` |
| `keys(map)` | Returns a list of the keys in a map. | `keys({a=1, b=2})` → `["a", "b"]` |
| `values(map)` | Returns a list of the values in a map. | `values({a=1, b=2})` → `[1, 2]` |
| **Filesystem Functions** | | |
| `file(path)` | Reads the contents of a file at the given path. | `file("script.sh")` |
| `pathexpand(path)` | Expands a tilde `~` in a path to the user's home directory. | `pathexpand("~/.ssh/id_rsa")` |
| **Type Conversion** | | |
| `tostring(value)` | Converts a value to a string. | `tostring(123)` → `"123"` |
| `tolist(value)` | Converts a single value or a set to a list. | `tolist({"a", "b"})` → `["a", "b"]` |
| **Encoding Functions** | | |
| `jsonencode(value)` | Encodes a given value to a JSON string. | `jsonencode({a=1})` → `"{\\"a\\":1}"` |
| `base64encode(string)` | Encodes a string using Base64. | `base64encode("hello")` → `"aGVsbG8="` |

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

# 12. Security Best Practices (DevSecOps)

Integrating security into your IaC workflow is critical.

| Area | Best Practice | Why It's Important |
|---|---|---|
| **State Security** | **Use a Remote Backend with Encryption & Locking.** | The state file contains sensitive data. Using a remote backend (like S3 + DynamoDB) with encryption at rest and state locking prevents data exposure and concurrent modification errors. **Never commit `.tfstate` files to Git.** |
| **Secrets Management** | **Never hardcode secrets.** Use a secrets manager like AWS Secrets Manager, Azure Key Vault, or HashiCorp Vault. | Avoids exposing credentials in your codebase. Use `data` sources to fetch secrets at runtime. Mark sensitive variables with `sensitive = true` to suppress them in CLI output. |
| **Least Privilege** | **Use credentials with minimum required permissions.** | The IAM role or Service Principal running Terraform should only have permissions to manage the resources defined in your configuration. Use separate, more restrictive roles for `plan` (read-only) vs. `apply` (write). |
| **Static Analysis (Shift-Left)** | **Integrate IaC scanning tools** into your CI/CD pipeline. | Tools like **`tfsec`**, **`checkov`**, and **`tflint`** can detect security misconfigurations (e.g., public S3 buckets, overly permissive firewall rules) *before* infrastructure is deployed. |
| **Dependency Pinning** | **Pin provider and module versions.** | Use version constraints in `provider` blocks (`version = "~> 5.0"`) and `module` blocks (`version = "1.2.0"`). Commit the `.terraform.lock.hcl` file to ensure consistent, predictable builds. |
| **Network Security** | **Avoid overly permissive ingress/egress rules.** | Do not use `0.0.0.0/0` for sensitive ports like SSH (22) or RDP (3389). Be explicit about which protocols and IP ranges are allowed. |
| **Code Organization** | **Use modules and a consistent project structure.** | Well-organized code is easier to review for security flaws. Separate environments (`dev`, `prod`) to limit the blast radius of any single change. |

**Example: Sensitive Variable**
```hcl
variable "db_password" {
  type      = string
  sensitive = true
  description = "Database admin password."
}

output "db_password_display" {
  value = var.db_password
  sensitive = true # Also mark outputs as sensitive
}
```

---

## Static Analysis Tool Comparison: `tfsec` vs. `tflint` vs. `checkov`

| Feature | `tflint` | `tfsec` | `checkov` |
|---|---|---|---|
| **Primary Focus** | **Code Quality & Best Practices.** Catches provider-specific errors (e.g., invalid instance types) and enforces conventions. | **Terraform Security.** A dedicated security scanner focused solely on finding vulnerabilities in Terraform code. | **Multi-Framework Security.** Scans many IaC tools (Terraform, CloudFormation, Kubernetes, etc.) for security issues. |
| **Scope** | Terraform only. | Terraform only. | Multi-framework. |
| **Key Strength** | Deep provider integration via plugins. Excellent for catching functional bugs and enforcing code style. | Very fast, with a comprehensive and up-to-date set of security rules specifically for Terraform. | Broad framework support. A single tool for scanning an entire polyglot IaC environment. |
| **When to Use** | **Always.** Use as your primary linter to ensure code is correct, maintainable, and follows best practices. | **Always.** Use as your primary Terraform-specific security scanner to catch vulnerabilities before deployment. | **When you need a unified security tool.** Excellent for organizations that use multiple IaC frameworks and want a single pane of glass for security scanning. |

**Recommendation:** For a robust Terraform pipeline, use **`tflint` and `tfsec` together**.
- `tflint` acts as the code reviewer for correctness and quality.
- `tfsec` acts as the security expert for vulnerability scanning.
- Add `checkov` if your organization manages infrastructure with other tools besides Terraform and you want a single, consistent security scanning solution.

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

# 14. Key Concept Comparisons

## 14.1 Implicit vs. Explicit Dependency

*   **Implicit Dependency**: This is the standard and preferred way Terraform manages relationships. When one resource block references an attribute from another (e.g., an instance using a security group's ID), Terraform automatically understands the creation order.

    ```hcl
    resource "aws_security_group" "web_sg" {
      name = "web-server-sg"
    }

    resource "aws_instance" "web" {
      ami           = "ami-123456"
      instance_type = "t2.micro"
      # Terraform knows to create the security group first because it's referenced here.
      vpc_security_group_ids = [aws_security_group.web_sg.id]
    }
    ```

*   **Explicit Dependency**: Used as a last resort when a dependency exists but isn't visible to Terraform through attribute references (e.g., an application needs an external system to be ready). The `depends_on` meta-argument forces a specific creation order.

    ```hcl
    resource "aws_instance" "app" {
      # ...
      # Tells Terraform to wait for the database to be created before creating this instance.
      depends_on = [aws_db_instance.database]
    }
    ```

## 14.2 `terraform show` vs. `terraform state list`

*   **`terraform state list`**: Provides a concise, machine-readable list of all resource addresses tracked in the state file. It's perfect for a quick inventory or for scripting.
    ```bash
    # Example Output:
    # aws_instance.web
    # aws_s3_bucket.mybucket
    ```

*   **`terraform show`**: Provides a detailed, human-readable view of the current state (or a plan file). It shows the attributes and values of all tracked resources, making it ideal for inspecting the configuration of your existing infrastructure.
    ```bash
    # Example Output (abbreviated):
    # # aws_instance.web:
    # resource "aws_instance" "web" {
    #     id            = "i-0123456789abcdef0"
    #     instance_type = "t2.micro"
    #     ...
    # }
    ```

## 14.3 Workspaces vs. Manual State File Management

*   **Workspaces**: A built-in Terraform feature for managing multiple environments (e.g., `dev`, `staging`, `prod`) within a single configuration directory. Each workspace gets its own separate state file, but they all share the same `.tf` files. This is convenient for simple environment separation.
    - **Pro**: Easy to switch between environments (`terraform workspace select dev`).
    - **Con**: Can be risky, as a change to the shared code can impact all environments. Not ideal for significant differences between environments.

*   **Manual Approach (Directory-based)**: The more common and robust pattern for managing environments. You create a separate directory for each environment, which contains its own `main.tf` or variable files. This provides strong isolation.
    ```
    ├── environments/
    │   ├── dev/
    │   │   ├── main.tf
    │   │   └── terraform.tfvars
    │   └── prod/
    │       ├── main.tf
    │       └── terraform.tfvars
    ```
    - **Pro**: Strong isolation, clear separation of concerns, and allows for different code per environment.
    - **Con**: Requires more file structure management.

## 14.4 `variables.tf` vs. `*.tfvars` Files

*   **`variables.tf` (or `variables.tf.json`)**: This file **declares** the input variables for your configuration. It defines the variable's name, type, description, and optional default value and validation rules. It defines *what* inputs are accepted.
*   **`terraform.tfvars` / `*.auto.tfvars` / `custom.tfvars`**: These files **assign values** to the variables declared in `variables.tf`. They provide the actual inputs for a specific deployment. Terraform automatically loads `.auto.tfvars` and `terraform.tfvars` if they exist. You can specify other `.tfvars` files with the `-var-file` flag.


## 14.5 `count` vs. `for_each`

Both `count` and `for_each` are meta-arguments used to create multiple instances of a resource, but they behave very differently.

*   **`count`**: Creates a specified number of identical resource instances. The resources are tracked in the state file as a list, indexed by numbers (`[0]`, `[1]`, `[2]`, etc.).

    ```hcl
    # Creates 3 identical EC2 instances
    resource "aws_instance" "server" {
      count         = 3
      ami           = "ami-123456"
      instance_type = "t2.micro"

      tags = {
        Name = "Server-${count.index}" # count.index gives the current iteration number
      }
    }
    ```
    -   **Problem**: `count` is fragile. If you remove an item from the middle of a list that `count` depends on, Terraform will destroy and recreate all subsequent resources in the list because their indexes have changed.
    -   **When to use**: Only for creating multiple resources that are truly identical and disposable, where re-creation is not an issue.

*   **`for_each`**: Iterates over a map or a set of strings to create multiple resource instances. Each instance is identified by the map key or set value, creating a stable association. This is the recommended approach.

    ```hcl
    # Creates an EC2 instance for each entry in the map
    resource "aws_instance" "server" {
      for_each = {
        "app" = "t2.micro"
        "db"  = "t2.small"
      }

      ami           = "ami-123456"
      instance_type = each.value # 'each.key' is the name ("app", "db"), 'each.value' is the instance type

      tags = {
        Name = "Server-${each.key}"
      }
    }
    ```
    -   **Benefit**: `for_each` is robust. If you remove the `"app"` entry from the map, only the instance associated with the `"app"` key is destroyed. The `"db"` instance is completely unaffected.
    -   **When to use**: In almost all scenarios where you need to create multiple resources. It provides a stable, predictable, and safer way to manage infrastructure.


## 14.6 The `lifecycle` Meta-Argument

The `lifecycle` block is a special nested block within a resource that customizes its behavior during creation, updates, and destruction.

#### `create_before_destroy`

*   **What it does**: By default, when a resource needs to be replaced due to an unchangeable attribute modification, Terraform destroys the old resource first and then creates the new one. Setting `create_before_destroy = true` reverses this order.
*   **Why it's useful**: This is critical for minimizing or eliminating downtime for resources that must remain available, such as a load balancer or a single-instance application. The new resource is provisioned and can become healthy before the old one is terminated.
*   **Example**:
    ```hcl
    resource "aws_instance" "web" {
      # Changing the AMI forces Terraform to replace the instance.
      ami           = "ami-0c55b159cbfafe1f0"
      instance_type = "t2.micro"

      lifecycle {
        create_before_destroy = true
      }
    }
    ```
    > **Note**: This can cause temporary naming conflicts if the resource has a unique name constraint.

#### `prevent_destroy`

*   **What it does**: This is a safety feature that tells Terraform to produce an error if any plan would result in the destruction of this resource.
*   **Why it's useful**: It acts as a safeguard for critical, stateful resources like a production database or a Terraform state bucket, preventing accidental deletion.
*   **Example**:
    ```hcl
    resource "aws_s3_bucket" "terraform_state" {
      bucket = "my-critical-terraform-state-bucket"

      lifecycle {
        prevent_destroy = true
      }
    }
    ```

#### `ignore_changes`

*   **What it does**: Tells Terraform to ignore changes to specific resource attributes. If an attribute in the list is modified outside of Terraform, a `terraform plan` will not show a difference, and `terraform apply` will not attempt to revert it.
*   **Why it's useful**: This is essential when a cloud provider or another process automatically modifies a resource's attributes (e.g., AWS Auto Scaling adding tags to an instance) and you don't want Terraform to fight over the changes.
*   **Example**: To prevent Terraform from managing tags that might be added by an external system:
    ```hcl
    resource "aws_instance" "web" {
      # ...
      lifecycle {
        ignore_changes = [tags] # Can also use all_tags for all tag-related attributes
      }
    }
    ```

## 14.7 The Dependency Lock File (`.terraform.lock.hcl`)

*   **What it is**: The `.terraform.lock.hcl` file is a dependency lock file that is automatically generated or updated by the `terraform init` command. It contains a record of the specific provider versions that Terraform selected for use based on the configuration's version constraints.

*   **Purpose**: Its primary purpose is to ensure that every run of Terraform uses the exact same versions of the required providers. This provides several key benefits:
    *   **Consistency**: Guarantees that you, your teammates, and your CI/CD systems are all using identical provider versions, leading to predictable and repeatable behavior.
    *   **Preventing Unintended Upgrades**: It "locks" the provider versions, preventing `terraform init` from automatically downloading a newer version that might contain breaking changes.
    -   **Security**: By locking the versions, you can verify the checksums (hashes) of the provider plugins, ensuring you are not using a compromised or altered version.

*   **How to use it**:
    *   This file should be **committed to your version control system** (like Git) along with your other `.tf` files.
    *   When another user runs `terraform init`, Terraform will read the lock file and download the exact provider versions specified within it, rather than finding the latest matching version.

*   **Example Entry**:
    ```hcl
    # This file is maintained automatically by "terraform init".
    # Manual edits may be lost in future updates.

    provider "registry.terraform.io/hashicorp/aws" {
      version     = "5.31.0"
      constraints = "~> 5.0"
      hashes = [
        "h1:iF/tV+9A8q2nvEY3YdM2s3aOF2AV3iC2i+a7fJgVfO4=",
        # ... other platform hashes
      ]
    }
    ```

## 14.8 Dynamic Blocks

*   **What it does**: A `dynamic` block generates multiple nested blocks (like `ingress` rules or `setting` blocks) within a resource based on a collection of values. It acts like a `for` loop for creating configuration blocks.

*   **Why it's useful**: It helps you write concise and flexible code when the number of nested blocks is not fixed. Instead of manually writing a block for each item, you can generate them programmatically from a list or map. This is essential for creating resources where parts of their configuration are determined by input variables.

*   **Example**: Creating multiple `ingress` rules for a security group based on a list of ports.

    ```hcl
    variable "ingress_ports" {
      description = "List of ingress ports to open"
      type        = list(number)
      default     = [80, 443, 8080]
    }

    resource "aws_security_group" "web" {
      name = "web-server-sg"

      dynamic "ingress" {
        # Iterate over the list of ports
        for_each = var.ingress_ports

        # The 'content' block defines the structure of each generated block.
        # 'ingress.value' refers to the current item in the iteration (e.g., 80, then 443).
        content {
          from_port   = ingress.value
          to_port     = ingress.value
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
    ```
    
## 14.9 Tainting Complex Resource Addresses (Shell Specifics)

When a resource address contains special characters like `[` `]` or `"`, you need to quote it correctly for your shell. This is common for resources created with `count` or `for_each` inside a module.

**Target Address:** `module.security[0].aws_security_group.this["lb_sg"]`

#### Linux / macOS / WSL (Bash/Zsh)

Use single quotes to wrap the entire address. The double quotes inside will be treated as literal characters.

```bash
terraform taint 'module.security[0].aws_security_group.this["lb_sg"]'
```

#### Windows Command Prompt (CMD)

Wrap the entire address in double quotes and use a backslash `\` to escape the inner double quotes.

```cmd
terraform taint "module.security[0].aws_security_group.this[\"lb_sg\"]"
```

#### Windows PowerShell

Wrap the entire address in single quotes and use a backslash `\` to escape the inner double quotes.

```powershell
terraform taint 'module.security[0].aws_security_group.this[\"lb_sg\"]'

terraform taint 'module.vm[0].aws_instance.this[\"app_server_2\"]'
```

---

# 15. Importing Existing Infrastructure

The `terraform import` command is used to bring existing, manually-created infrastructure under Terraform's management.

**Workflow**

1.  **Write the Resource Configuration**: Write a `resource` block in your `.tf` file that matches the configuration of the existing resource you want to import.
2.  **Find the Resource ID**: Get the unique ID of the resource from your cloud provider's console or CLI (e.g., an EC2 instance ID, S3 bucket name).
3.  **Run the Import Command**: Execute `terraform import` with the resource address and the resource ID.

**Example**

To import an existing AWS S3 bucket named `my-legacy-bucket`:

```hcl
# 1. Add this to your main.tf
resource "aws_s3_bucket" "imported_bucket" {
  # Configuration will be populated after import
}
```
```bash
# 2. Run the import command
terraform import aws_s3_bucket.imported_bucket my-legacy-bucket
```
4.  **Synchronize Configuration**: After importing, run `terraform plan`. Terraform will show differences between your configuration and the imported resource's actual state. Adjust your HCL code to match the resource's attributes until the plan shows no changes.



---

# 16. Provisioners

Provisioners execute scripts on a local or remote machine as part of resource creation or destruction. They are considered a **last resort** because they are not declarative and can make configurations fragile.

**Types of Provisioners**

*   **`remote-exec`**: Executes a script on the remote resource after it's created (e.g., configuring a new VM).
*   **`local-exec`**: Executes a script on the machine running Terraform.

**Example**

```hcl
resource "aws_instance" "web" {
  # ... instance configuration ...

  # Not recommended; prefer user_data or pre-baked AMIs
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y nginx"
    ]
  }
}
```
**Best Practice**: Avoid provisioners. Use custom machine images (Packer), `user_data` scripts, or dedicated configuration management tools (Ansible, Chef) instead.

| **`environments/`** | Contains the "live" configurations for each environment (the "what"). Each environment directory calls modules and provides specific values via `.tfvars` files. Each has its own unique `backend.tf` for state isolation. |

**Workflow**: To manage an environment, `cd` into its directory (e.g., `environments/dev`) and run `terraform plan/apply`. This ensures a mistake in `dev` cannot impact `prod`. This pattern provides stronger isolation and flexibility than using `terraform workspace` for distinct environments.


---

# 17. Recovering from a Lost or Corrupted State File

A lost or corrupted state file is a critical situation. Since Terraform uses the state file to map your configuration to real-world resources, its absence means Terraform has no knowledge of the infrastructure it's supposed to be managing.

**CRITICAL: Do NOT run `terraform apply`!** If you run `apply` with an empty state, Terraform will assume no infrastructure exists and will attempt to create everything from scratch, leading to duplicate resources or errors.

### Scenario 1: Restore from a Backup (The Correct Way)

This is the best-case scenario and highlights the importance of using a remote backend with versioning enabled.

1.  **Identify the Last Good Version**: If you are using a backend like AWS S3 with versioning enabled, navigate to the S3 bucket in the AWS Console. Find your state file (`path/to/your/terraform.tfstate`) and look at its version history.
2.  **Restore the State File**: Select the most recent, non-corrupted version and make it the current version. This effectively "rolls back" the state file to a known good point.
3.  **Verify the Workspace**: Back in your terminal, run `terraform plan`. Terraform will now use the restored state file. It will refresh the state against the real-world infrastructure and show you a plan.
4.  **Analyze the Plan**: The plan may show some "drift" if there were changes made after the restored state was saved. Review these changes carefully. If they are acceptable, you can proceed with `terraform apply`. If not, you may need to adjust your configuration.

### Scenario 2: Rebuild the State Manually (The Painful Last Resort)

If you have no backups, you must manually repopulate the state file by importing every existing resource. This is a tedious and error-prone process.

1.  **Ensure Your Code Matches Reality**: Your Terraform configuration (`.tf` files) must accurately represent the infrastructure that exists in your cloud account.
2.  **Initialize a New, Empty State**: Run `terraform init`. This will create a new, empty state file in your backend.
3.  **Import Each Resource One-by-One**: For every single resource defined in your configuration, you must find its unique ID from your cloud provider and run the `terraform import` command.
    - The command format is: `terraform import <resource_address> <resource_id>`
    - `<resource_address>` is the address from your code (e.g., `aws_instance.web`).
    - `<resource_id>` is the ID from the cloud provider (e.g., `i-0123456789abcdef0`).

    ```bash
    # Example: Import an EC2 instance, an S3 bucket, and a VPC
    terraform import aws_instance.web i-0123456789abcdef0
    terraform import aws_s3_bucket.my_bucket my-unique-bucket-name
    terraform import aws_vpc.main vpc-0fedcba9876543210
    ```
4.  **Verify and Synchronize**: After importing **all** resources, run `terraform plan`.
    - It is very likely that the plan will **not** be empty. This is because `import` only brings the resource into the state; it does not populate all the arguments in your `.tf` files.
    - You must now meticulously update your HCL code to match the attributes of the imported resources until `terraform plan` reports **"No changes. Your infrastructure matches the configuration."**

### Prevention is Better Than Cure

*   **Always Use a Remote Backend**: Never use local state files for any project that is not a temporary experiment.
*   **Enable Backend Versioning**: For backends like AWS S3 or Google Cloud Storage, enable object versioning. This is your primary safety net.
*   **Enable Backend Protection**: Enable soft-delete and purge protection on your storage backend to prevent accidental deletion of the state file itself.
*   **Use State Locking**: Use a locking mechanism like DynamoDB for AWS to prevent concurrent operations from corrupting the state.


---
*End of cheat sheet — happy Terraforming!*
