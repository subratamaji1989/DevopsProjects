# Local Development Environment Setup on Windows

This guide provides a complete, step-by-step playbook for setting up a robust local development environment on a Windows machine. It uses WSL2, Docker Desktop, and Kubernetes to create a local cloud-native environment suitable for general application development and MLOps.

## Table of Contents
1. [Part 1: One-Time Infrastructure Setup](#part-1-one-time-infrastructure-setup)
   - [Security Best Practices](#security-best-practices)
2. [Part 2: Example - Deploying a Java Application](#part-2-example---deploying-a-java-application)
   - [Troubleshooting Common Issues](#troubleshooting-common-issues)
3. [Part 3: Advanced - Local MLOps Setup](#part-3-advanced---local-mlops-setup)

---

## Part 1: One-Time Infrastructure Setup

Follow these steps to configure the base infrastructure. This is a one-time setup for your Windows laptop.

### Step 1: Enable Hardware Virtualization (VT-x / AMD-V)

WSL2 and Docker require CPU virtualization to be enabled in the BIOS/UEFI.

1.  **Check if Virtualization is Enabled**:
    Open PowerShell as Administrator and run:
    ```powershell
    systeminfo
    ```
    Look for the `Hyper-V Requirements` section. If `Virtualization Enabled In Firmware` is `Yes`, you can skip to the next step.

2.  **Enable in BIOS/UEFI**:
    If it's disabled, reboot your computer and enter the BIOS/UEFI setup (common keys are `F2`, `Del`, `Esc`). Find the setting for `Intel Virtualization Technology (VT-x)` or `AMD-V (SVM Mode)` and set it to `Enabled`. Save changes and exit.

### Step 2: Install WSL 2 (Windows Subsystem for Linux)

WSL2 provides a full Linux kernel and is the best way to run Linux environments on Windows.

1.  **Install WSL2 and Ubuntu**:
    Open PowerShell as Administrator and run the following command. This will install WSL2, download the latest Linux kernel, and install the Ubuntu distribution.
    ```powershell
    wsl --install -d Ubuntu
    ```
2.  **Set up Ubuntu**:
    Once installed, open `Ubuntu` from the Start Menu. On the first launch, you will be prompted to create a username and password for your Linux environment.

3.  **Update Your Linux Distro**:
    Inside the Ubuntu terminal, run these commands to update your package lists and installed packages:
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

### Step 3: Install and Configure Docker Desktop

Docker Desktop will manage your containers and provide a simple, single-node Kubernetes cluster.

1.  **Download and Install**:
    Download Docker Desktop for Windows. Run the installer, ensuring the **"Use the WSL 2 based engine"** option is selected.

2.  **Configure WSL Integration**:
    After installation, open Docker Desktop. Go to **Settings > Resources > WSL Integration**. Ensure that integration is enabled for your `Ubuntu` distribution. This allows you to use the `docker` command from within WSL.

3.  **Verify Docker Installation**:
    Verify that Docker is running correctly from both PowerShell and your Ubuntu terminal.
    ```bash
    # From either PowerShell or Ubuntu
    docker run --rm hello-world
    ```
    You should see a "Hello from Docker!" message.

### Step 4: Enable and Verify Kubernetes

1.  **Enable Kubernetes**:
    In Docker Desktop, go to **Settings > Kubernetes**. Check the **"Enable Kubernetes"** box and click **"Apply & Restart"**. This will download the necessary components and start a single-node cluster.

2.  **Set Kubectl Context**:
    The Kubernetes command-line tool, `kubectl`, is included with Docker Desktop. Configure it to connect to your new local cluster.
    ```bash
    kubectl config use-context docker-desktop
    kubectl create ns ovr-ns
    kubectl config set-context --current --namespace=<namespace-name>

    kubectl config get-contexts
    ```

3.  **Verify Cluster Status**:
    Check that your node is ready.
    ```bash
    kubectl get nodes
    ```
    The output should show a single node named `docker-desktop` with a `Ready` status.

### Step 5: (Optional) Performance and Resource Tuning

*   **WSL2 Resource Limits**: To control the memory and CPU that WSL2 can use, create a file at `C:\Users\<YourUsername>\.wslconfig` with the following content. Adjust the values based on your machine's specs.
    ```ini
    [wsl2]
    memory=8GB   # Limit memory to 8GB
    processors=4 # Limit to 4 CPU cores
    ```
    Restart WSL to apply the changes by running `wsl --shutdown` in PowerShell.

*   **Docker Desktop Resources**: In Docker Desktop, go to **Settings > Resources** to adjust the CPU, Memory, and Disk Image Size allocated to Docker.

### Security Best Practices

Applying security best practices is crucial, even for a local environment.

*   **Secure Docker**:
    *   Keep the Docker daemon port (`tcp://localhost:2375`) unexposed.
    *   Use a `.dockerignore` file to prevent sensitive files like `.git`, `.env`, or credentials from being included in your container images.
    *   Build images with a non-root user (as shown in the example `Dockerfile`).
*   **Secure Kubernetes**:
    *   Be mindful that `kubectl` with the `docker-desktop` context has admin access to the local cluster. Handle manifests and commands with care.
*   **System & Tooling**:
    *   Keep Docker Desktop, WSL, and your packages up to date to receive security patches.
    *   Use minimal base images for containers (e.g., `alpine`) to reduce the attack surface.
    *   Consider using a local image scanner like `trivy` to check for vulnerabilities before pushing images to a registry.

---

## Part 2: Example - Deploying a Java Application
in Next Project