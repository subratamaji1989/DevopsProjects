import argparse
import subprocess
import json
import sys
import os
import yaml

# Annotate default variables for Azure
PROJECT_ROOT_DIR = os.getcwd()
PRECHECK_PLAN = "precheck.tfplan"
PRECHECK_JSON = "precheck.json"

def abs_path(path):
    """Combine PROJECT_ROOT_DIR with relative path if PROJECT_ROOT_DIR is set."""
    if os.path.isabs(path):
        return path
    return os.path.join(PROJECT_ROOT_DIR, path)

def run_command(command, cwd=None, check=True, capture_output=False):
    """Run a shell command securely and print output."""
    print(f"Running: {command}")
    try:
        # Set stdout and stderr based on capture_output flag
        stdout_pipe = subprocess.PIPE if capture_output else sys.stdout
        stderr_pipe = subprocess.PIPE if capture_output else sys.stderr

        result = subprocess.run(command, shell=True, cwd=cwd, check=check,
                               stdout=stdout_pipe, stderr=stderr_pipe, text=True)
        if capture_output:
            # If capturing, the output is in result.stdout/stderr
            print(result.stdout)
            if result.stderr:
                print(result.stderr, file=sys.stderr)
        return result
    except subprocess.CalledProcessError as e:
        print(f"Error running command: {command}", file=sys.stderr)
        if e.stdout: print(e.stdout)
        if e.stderr: print(e.stderr, file=sys.stderr)
        sys.exit(e.returncode)

def merge_yaml_to_json(vars_dir, output_json, yaml2tfvars_script):
    """Merge YAML files to JSON using provided Python script."""
    print("Merging YAML files to JSON...")
    # Ensure output directory exists
    output_dir = os.path.dirname(output_json)
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir, exist_ok=True)
    merge_script = abs_path(yaml2tfvars_script)
    cmd = f"python {merge_script} {vars_dir} {output_json}"
    run_command(cmd)

def setup_terraform_provider_mirror(comp_dir):
    """Creates a .terraformrc file to use a local provider mirror."""
    print("Setting up local Terraform provider mirror...")
    provider_cache_path = abs_path("terraform-platform/.terraform.d/plugins")
    provider_cache_path_hcl = provider_cache_path.replace('\\', '/')
    rc_content = f'provider_installation {{\n  filesystem_mirror {{\n    path = "{provider_cache_path_hcl}"\n  }}\n  direct = []\n}}'
    rc_path = abs_path("terraform-platform/.terraformrc")
    with open(rc_path, 'w') as f:
        f.write(rc_content)
    print(f"Created Terraform config for local mirror: {rc_path}")

def load_azure_env(env_file_path="C:\\Users\\SUBRATA\\.azure_env"):
    """Loads environment variables from a .env file for Azure authentication."""
    if os.path.exists(env_file_path):
        print(f"Loading Azure credentials from {env_file_path}...")
        with open(env_file_path, 'r') as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith('#') and '=' in line:
                    key, value = line.split('=', 1)
                    key = key.strip()
                    value = value.strip().strip('"').strip("'")
                    os.environ[key] = value
    else:
        print(f"Info: Azure environment file not found at {env_file_path}. Assuming 'az login' or managed identity.")

def terraform_workflow(comp_dir, tfvars_json, plan_file, plan_json, all_vars, action="plan"):
    """Run Terraform init, validate, and the specified action (plan or destroy)."""
    print("Running Terraform workflow...")
    # Load credentials from .azure_env if it exists. Otherwise, assumes 'az login'.
    load_azure_env()

    # Terraform init (no backend for local plan)
    run_command("terraform init -backend=false", cwd=comp_dir)
    # Terraform validate
    if action == "plan":
        run_command("terraform validate", cwd=comp_dir)
        # Terraform plan
        plan_cmd = f"terraform plan -var-file={tfvars_json}"

        # Securely pass sensitive variables like SSH keys via the command line,
        # but only if the composition is the one that needs it (vm-stack).
        if "vm-stack" in comp_dir and "admin_public_key" in all_vars and all_vars["admin_public_key"]:
            plan_cmd += f' -var="admin_public_key={all_vars["admin_public_key"]}"'

        plan_cmd += f" -out={plan_file}"
        run_command(plan_cmd, cwd=comp_dir)
        # Terraform show
        show_cmd = f"terraform show -json {plan_file} > {plan_json}"
        run_command(show_cmd, cwd=comp_dir)

    elif action == "destroy":
        # For destroy, we don't need a plan file, just the variables.
        destroy_cmd = f"terraform destroy -var-file={tfvars_json} -auto-approve"
        run_command(destroy_cmd, cwd=comp_dir)

def main():
    parser = argparse.ArgumentParser(
        description="Azure DevSecOps Infra Automation Script",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument("action", choices=["plan", "apply", "destroy"], help="Action to perform.")
    parser.add_argument("--app", default="ovr-app-infra", help="Application name.")
    parser.add_argument("--cloud", default="azure", help="Cloud provider (aws or azure).")
    parser.add_argument("--env", default="dev", help="Target environment (e.g., dev, prod).")

    # Show help if no arguments are provided
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)

    args = parser.parse_args()
    app = args.app
    cloud = args.cloud
    environment = args.env

    # Construct paths dynamically
    default_vars_dir = f"{app}/{cloud}/{environment}/vars"
    default_composition_dir = f"terraform-platform/{cloud}/infra-stack"
    yaml2tfvars_script_path = f"terraform-platform/{cloud}/tools/yaml2tfvars.py"
    backend_config_path = f"{app}/{cloud}/{environment}/backend.tf"

    vars_dir = abs_path(default_vars_dir)
    json_path = abs_path("all.tfvars.json")
    composition_dir = abs_path(default_composition_dir)
    plan_file = PRECHECK_PLAN
    plan_json = PRECHECK_JSON

    # --- Shared Steps for Plan and Apply ---
    def run_plan_steps():
        """Executes validation, merge, and terraform plan."""
        # Step 1: Merge YAML files to JSON
        print("\n--- Step 1: Merge YAML files to JSON ---")
        print(f"YAML directory: {vars_dir}")
        print(f"Output JSON file: {json_path}")
        merge_yaml_to_json(vars_dir, json_path, yaml2tfvars_script_path)

        # Step 2: Setup Terraform Provider Mirror
        print("\n--- Step 2: Setup Terraform Provider Mirror ---")
        setup_terraform_provider_mirror(composition_dir)

        # Read the merged JSON to access variables needed for the command line
        all_vars = {}
        if os.path.exists(json_path):
            with open(json_path, 'r') as f:
                all_vars = json.load(f)

        # Step 3: Terraform workflow (plan)
        print("\n--- Step 3: Terraform Plan Workflow ---")
        print(f"Composition directory: {composition_dir}")
        relative_json_path = os.path.relpath(json_path, composition_dir)
        print(f"TFVars JSON: {relative_json_path}")
        terraform_workflow(composition_dir, relative_json_path, plan_file, plan_json, all_vars, action="plan")
        return relative_json_path, all_vars

    # --- Action-based Workflow ---
    if args.action == "plan":
        print("Executing 'plan' workflow...")
        run_plan_steps()
        print("\n'plan' workflow completed successfully.")

    elif args.action == "apply":
        print("Executing 'apply' workflow...")
        # First, run the plan steps to generate the plan file
        run_plan_steps()
        # Now, initialize with the real backend to apply the plan
        print("\n--- Initializing with remote backend for apply ---")
        run_command(f"terraform init -backend-config={abs_path(backend_config_path)}", cwd=composition_dir)

        # Step 4: Terraform Apply
        print("\n--- Step 4: Terraform Apply ---")
        print(f"Applying plan file: {plan_file}")
        run_command(f"terraform apply -auto-approve {plan_file}", cwd=composition_dir)
        print("\n'apply' workflow completed successfully.")

    elif args.action == "destroy":
        print("Executing 'destroy' workflow...")
        # For destroy, we need variables and the real backend to correctly identify resources.
        print("\n--- Step 1: Preparing for destroy ---")
        merge_yaml_to_json(vars_dir, json_path, yaml2tfvars_script_path)
        setup_terraform_provider_mirror(composition_dir)
        run_command(f"terraform init -backend-config={abs_path(backend_config_path)}", cwd=composition_dir)
        relative_json_path = os.path.relpath(json_path, composition_dir)

        # --- Confirmation Step ---
        print("\n" + "="*60)
        print(f"  WARNING: You are about to destroy the infrastructure")
        print(f"  in the '{environment}' environment.")
        print("  This action is irreversible.")
        print("="*60)
        response = input("  Type 'yes' or 'y' to confirm: ").strip().lower()

        if response in ['yes', 'y']:
            # Step 2: Terraform Destroy
            print("\n--- Step 2: Terraform Destroy ---")
            terraform_workflow(composition_dir, relative_json_path, None, None, {}, action="destroy")
        else:
            print("\nDestroy action canceled.")
            sys.exit(0)

        print("\n'destroy' workflow completed successfully.")

    else:
        parser.print_help()

if __name__ == "__main__":
    main()