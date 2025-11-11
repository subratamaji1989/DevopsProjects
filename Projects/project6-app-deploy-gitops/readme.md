# 🚀 AKS Application Deployment with Azure DevOps GitOps

This document provides a complete, step-by-step guide for implementing a secure and automated CI/CD pipeline to deploy a containerized Java application onto an Azure Kubernetes Service (AKS) cluster using GitOps with ArgoCD for continuous deployment.

## 📑 Table of Contents

1. [Core Concepts & Workflow](#-core-concepts--workflow)
2. [Repository Structure](#-repository-structure)
3. [Prerequisites](#-prerequisites)
4. [Step 1: The Application Source (`app-source-repo`)](#-step-1-the-application-source-app-source-repo)
5. Step 2: The Kubernetes Manifests (`cicd-manifests-repo`)
6. Step 3: The CI Pipeline (Azure DevOps Pipelines)
7. Step 4: The CD Pipeline (ArgoCD)
8. End-to-End Flow in Action

---

## 🌊 Core Concepts & Workflow

This guide implements a workflow that separates **Continuous Integration (CI)** from **Continuous Deployment (CD)**.

*   **CI Pipeline**: Responsible for building, testing, scanning, and publishing a container image. Its final job is to update the GitOps manifests with the new image tag.
*   **CD Pipeline (ArgoCD)**: Responsible for deploying the containerized application to AKS using GitOps principles for automated, declarative deployments.

### Workflow Diagram

```
+----------------+   PR   +----------------+  CI Pipeline   +----------------+
|   Developer    | -----> | app-source-repo|-------------->| Azure Pipelines |
+----------------+        +----------------+              +----------------+
        ^                                                        |
        |                                                        | 1. Code Commit & Scan
        |                                                        | 2. Build & Scan Image
        |                                                        | 3. Push Image to ACR
        |                                                        |
        |                                                        v
+----------------+   Sync   +----------------+  GitOps Sync  +----------------+
| Azure AKS      |<------ |     ArgoCD       |<---------|  Git Manifests    |
| (Running App)  |        |   (CD Tool)      |          +----------------+
+----------------+        +----------------+
        ^                                                        ^ 4. Deploy new version
        |                                                        |    automatically
        +--------------------------------------------------------+ 5. Rollback via Git
                                                                    revert if needed
```

### Application Deploy Flow (CI/CD with GitOps)

| Step | Component | Tool/Service | Description & DevSecOps Principle |
|:---|:---|:---|:---|
| 1. | **Code Commit** | `app-repo` (Git) | Developer commits Java code (via PR). |
| 2. | **Security Scan I** | CI Pipeline (Azure Pipelines) | **SAST (Shift-Left):** Runs SonarQube Scanner and OWASP Dependency-Check to analyze Java code for vulnerabilities and library license issues. `Gitleaks` scans for secrets. |
| 3. | **Build** | Maven/Gradle & Docker | Builds the Java application (`.jar`) and then builds the Docker image using a hardened, minimal base image. |
| 4. | **Security Scan II** | CI Pipeline (Azure Pipelines) | **Container Scanning:** Runs `Trivy` to scan the newly created Docker image for OS and application dependencies (SBOM/Vulnerability checks). |
| 5. | **Publish Image** | Azure Container Registry (ACR) | The validated, tagged Docker image (e.g., `app:1.0.0-1234`) is pushed to a private ACR repository. |
| 6. | **Update Manifests** | CI Pipeline (Azure Pipelines) | CI pipeline updates the Kubernetes manifests in the GitOps repository with the new image tag. |
| 7. | **GitOps Sync** | ArgoCD | ArgoCD detects the manifest changes and automatically deploys the new version to AKS with zero downtime. |

---

## 📁 Repository Structure

This workflow uses two separate Git repositories to enforce separation of concerns:

1.  **`app-source-repo`**: Contains the Java application source code and its `Dockerfile`.
2.  **`cicd-manifests-repo`**: Contains the Kubernetes manifests (Deployment, Service, etc.) that define how the application runs. The CI pipeline updates these manifests, and ArgoCD uses them for deployments.

---

## ✅ Prerequisites

1.  An **Azure Kubernetes Service (AKS) Cluster**: Provisioned using Azure Resource Manager or Terraform templates, ensuring Azure security benchmarks compliance.
2.  **ArgoCD**: Installed on the AKS cluster for GitOps deployments.
3.  **Git Repository**: `app-source-repo` and `cicd-manifests-repo` (e.g., on GitHub or Azure Repos). Enable branch protection, required reviews, and secret scanning.
4.  **Azure Container Registry (ACR)**: A private registry to store your container images, with image scanning enabled and lifecycle policies for vulnerability management.
5.  **Azure DevOps Organization**: For CI pipelines, with service connections for ACR and AKS.
6.  **DevSecOps Tools**: Install SonarQube, Trivy, Gitleaks, OWASP Dependency-Check. Ensure tools are updated and configured for compliance (e.g., NIST SP 800-53).
7.  **Security Monitoring**: Integrate Azure Security Center, Azure Monitor, and Prometheus for monitoring and alerting on security events.

---

## 🛠️ Step 1: The Application Source (`app-source-repo`)

This repository contains your simple Java application.

### `Dockerfile`

A multi-stage Dockerfile is critical for creating small, secure images.

```dockerfile
# Stage 1: Build the application with Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Create the final, minimal runtime image
FROM gcr.io/distroless/java17:nonroot
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### `pipeline-vars.yml`
This file defines the configuration variables for the CI pipeline. The pipeline loads these variables dynamically using `yq` to avoid hardcoding and improve maintainability. Variables are loaded from `pipeline-vars.yml` in the `app-source-repo` root directory.

```yaml
# In ovr-web-app/pipeline-vars.yml
# --- Global Application & Build Configuration ---
APP_NAME: "ovr-web-app"
APP_TYPE: "java"
JAVA_VERSION: "17"
DOCKERFILE_PATH: "."
APP_PORT: 8080
HEALTH_CHECK_PATH: "/actuator/health"

# --- Global Azure & Container Registry Configuration ---
AZURE_REGION: "East US"
ACR_REPO_URI: "ovrakscicd.azurecr.io/ovr-web-app"

# --- Global Security & GitOps Configuration ---
SONAR_HOST_URL: "https://your-sonarqube-server.com"
SONAR_PROJECT_KEY: "ovr-web-app"
MANIFEST_REPO_URL: "https://dev.azure.com/your-org/your-project/_git/app-manifests"

# --- Environment-Specific Configurations ---
# The CI pipeline will select one of these blocks based on the Git branch or trigger.
dev:
  AKS_CLUSTER_NAME: "ovr-aks-cluster-dev"
  K8S_NAMESPACE: "web-apps-dev"
  JAVA_OPTS: "-Xmx512m -Xms256m"
  TRIVY_SEVERITY: "HIGH,CRITICAL"
  MANIFEST_REPO_BRANCH: "develop"
  KUSTOMIZE_PATH: "k8s/overlays/dev"

staging:
  AKS_CLUSTER_NAME: "ovr-aks-cluster-staging"
  K8S_NAMESPACE: "web-apps-staging"
  JAVA_OPTS: "-Xmx1g -Xms512m"
  TRIVY_SEVERITY: "HIGH,CRITICAL"
  MANIFEST_REPO_BRANCH: "staging"
  KUSTOMIZE_PATH: "k8s/overlays/staging"

prod:
  AKS_CLUSTER_NAME: "ovr-aks-cluster-prod"
  K8S_NAMESPACE: "web-apps-prod"
  JAVA_OPTS: "-Xmx2g -Xms1g"
  TRIVY_SEVERITY: "CRITICAL"
  MANIFEST_REPO_BRANCH: "main"
  KUSTOMIZE_PATH: "k8s/overlays/prod"
```

**Note:** The CI pipeline installs `yq` and loads variables from this file using commands like `ACR_REPO_URI=$(yq '.ACR_REPO_URI' pipeline-vars.yml)`. This replaces hardcoded values in the pipeline for better maintainability. Ensure `pipeline-vars.yml` is present in the `app-source-repo` root.

## 🛠️ Step 2: The Platform Repository (`cicd-manifests-repo`)

This repository defines the desired state of all applications in Kubernetes and contains the reusable CI logic. The CI pipeline will update manifests here, and ArgoCD will handle deployments.

### Directory Structure

```
app-manifests-repo/
└── k8s/
    ├── base/
    │   ├── app/
    │   │   ├── deployment.yaml
    │   │   ├── kustomization.yaml
    │   │   └── service.yaml
    └── overlays/
        └── dev/
            └── kustomization.yaml
└── pipelines/
    └── azure/
        └── azure-pipelines-ci.yml
```

### `k8s/base/deployment.yaml`

A secure deployment manifest with resource limits, security contexts, and probes for health checks.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ovr-web-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: ovr-web-app
  template:
    metadata:
      labels:
        app: ovr-web-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      containers:
      - name: ovr-web-app
        image: placeholder # This will be patched by Kustomize
        ports:
        - containerPort: 8080
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

### `k8s/base/kustomization.yaml`

Defines the resources that make up the base application.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
```

### `k8s/overlays/dev/kustomization.yaml`

This file points to the base and applies the patch to update the image tag. **This is the file our CI pipeline will modify.**

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- ../../base

images:
- name: placeholder
  newName: ovrakscicd.azurecr.io/ovr-web-app
  newTag: latest # This tag will be updated by the CI pipeline
```

---

## 🛠️ Step 3: The CI Pipeline (Azure DevOps Pipelines)

This pipeline, defined in a shared `azure-pipelines-ci.yml` file within `app-manifests-repo`, automates the CI process for all applications.

### `azure-pipelines-ci.yml`

```yaml
trigger:
  branches:
    include:
    - main
    - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  SONAR_HOST_URL: 'https://your-sonarqube-server.com'
  SONAR_TOKEN: $(SONAR_TOKEN)

stages:
- stage: Build
  jobs:
  - job: CI
    steps:
    - task: UseJavaVersion@1
      inputs:
        versionSpec: '17'
        addToPath: true

    - script: |
        echo "Installing security tools..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
        wget https://github.com/gitleaks/gitleaks/releases/download/v8.17.0/gitleaks_8.17.0_linux_x64.tar.gz -O /tmp/gitleaks.tar.gz && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin
        wget https://github.com/jeremylong/DependencyCheck/releases/download/v8.4.0/dependency-check-8.4.0-release.zip -O /tmp/dc.zip && unzip /tmp/dc.zip -d /opt && ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check
        curl -sSLo /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv5.0.1/kustomize_v5.0.1_linux_amd64.tar.gz | tar xzf - -C /usr/local/bin
        chmod +x /usr/local/bin/*
      displayName: 'Install Security Tools'

    - script: |
        echo "Loading pipeline variables..."
        # Parse YAML variables (use yq or similar)
        # For simplicity, hardcode or use Azure DevOps variables
        TARGET_ENV="dev"
        APP_NAME="ovr-web-app"
        ACR_REPO_URI="ovrakscicd.azurecr.io/ovr-web-app"
        MANIFEST_REPO_URL="$(MANIFEST_REPO_URL)"
        APP_PORT=8080
        HEALTH_CHECK_PATH="/actuator/health"
        SONAR_PROJECT_KEY="ovr-web-app"
        COMMIT_HASH=$(Build.SourceVersion | cut -c 1-7)
        IMAGE_TAG=${COMMIT_HASH:=latest}
        echo "Logging in to Azure Container Registry..."
        az acr login --name ovrakscicd
        echo "Cloning app-manifests repository..."
        git clone $(MANIFEST_REPO_URL) app-manifests
        echo "Replacing placeholders in manifests..."
        sed -i "s/{{APP_NAME}}/$APP_NAME/g" app-manifests/k8s/base/app/deployment.yaml app-manifests/k8s/base/app/service.yaml app-manifests/k8s/overlays/dev/kustomization.yaml
        sed -i "s/{{APP_PORT}}/$APP_PORT/g" app-manifests/k8s/base/app/deployment.yaml app-manifests/k8s/base/app/service.yaml
        sed -i "s/{{HEALTH_CHECK_PATH}}/$HEALTH_CHECK_PATH/g" app-manifests/k8s/base/app/deployment.yaml
        sed -i "s/{{ACR_REPO_URI}}/$ACR_REPO_URI/g" app-manifests/k8s/overlays/dev/kustomization.yaml
      displayName: 'Pre-build Setup'

    - script: |
        echo "Running SAST scans (SonarQube, Gitleaks, OWASP Dependency-Check)..."
        sonar-scanner -Dsonar.projectKey=$SONAR_PROJECT_KEY -Dsonar.sources=. -Dsonar.host.url=$SONAR_HOST_URL -Dsonar.login=$SONAR_TOKEN
        gitleaks detect --verbose --redact --config .gitleaks.toml || exit 1
        dependency-check --scan . --format JSON --out /tmp/dependency-check-report.json || exit 1
        echo "Building the Java application and Docker image..."
        mvn clean package
        docker build -t $ACR_REPO_URI:$IMAGE_TAG -f app-manifests/Dockerfile .
        echo "Running container scan (Trivy)..."
        trivy image --exit-code 1 --no-progress --format json --output /tmp/trivy-report.json $ACR_REPO_URI:$IMAGE_TAG || exit 1
        echo "Running DAST (ZAP baseline scan)..."
        docker run --rm -v $(pwd):/zap/wrk/:rw owasp/zap2docker-stable zap-baseline.py -t http://localhost:$APP_PORT -r /zap/wrk/zap-report.html || exit 1
      displayName: 'Build and Scan'

    - script: |
        echo "Pushing the Docker image to ACR..."
        docker push $ACR_REPO_URI:$IMAGE_TAG
        echo "Updating Kustomize image tag..."
        cd app-manifests/k8s/overlays/dev
        kustomize edit set image $ACR_REPO_URI:$IMAGE_TAG
        echo "Committing and pushing manifest changes..."
        git config user.name "Azure Pipelines"
        git config user.email "azuredevops@example.com"
        git add kustomization.yaml
        git commit -m "Update image to $IMAGE_TAG [Security scans passed]"
        git push
      displayName: 'Publish and Update Manifests'

    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '/tmp/trivy-report.json'
        artifactName: 'TrivyReport'
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: '/tmp/dependency-check-report.json'
        artifactName: 'DependencyCheckReport'
    - task: PublishBuildArtifacts@1
      inputs:
        pathToPublish: 'zap-report.html'
        artifactName: 'ZAPReport'
```

---

## 🛠️ Step 3.5: Integrating with Azure DevOps Pipelines

To use the two repositories (`app-source-repo` and `app-manifests-repo`) with Azure DevOps Pipelines, follow these steps:

### Setting Up the CI Pipeline
1. **Create a Pipeline in Azure DevOps**:
   - Go to your Azure DevOps project.
   - Navigate to Pipelines > New Pipeline.
   - Select "Azure Repos Git" and choose your `app-source-repo` (e.g., `ovr-web-app`).
   - Choose "Existing Azure Pipelines YAML file".
   - Set the path to the pipeline YAML. Since the shared pipeline is in `app-manifests-repo`, you have two options:
     - **Option 1: Copy the YAML** - Copy `app-manifests-repo/pipelines/azure-pipelines-ci.yml` into `app-source-repo` (e.g., as `.azure-pipelines.yml`) and reference it.
     - **Option 2: Use a Remote YAML** - If Azure DevOps supports remote YAML (via extensions or manual setup), reference the YAML from `app-manifests-repo`. Otherwise, use Option 1 for simplicity.

2. **Configure Pipeline Variables**:
   - In the pipeline settings, add any required variables (e.g., `SONAR_TOKEN`, `MANIFEST_REPO_URL`).
   - Ensure `pipeline-vars.yml` is present in the root of `app-source-repo` (as it is in `ovr-web-app`).

3. **Service Connections**:
   - Set up service connections for Azure Container Registry (ACR) and any other Azure resources.
   - Grant the pipeline permissions to access ACR and the `app-manifests-repo`.

4. **Triggers**:
   - The pipeline is configured to trigger on pushes to `main` and `develop` branches in `app-source-repo`.
   - For environment-specific deployments, you can add conditions or separate pipelines for staging/prod.

### Repository Usage
- **`app-source-repo`**: Contains the application code, `pipeline-vars.yml`, and triggers the CI pipeline.
- **`app-manifests-repo`**: Contains shared Kubernetes manifests and the pipeline YAML. The CI pipeline clones this repo to update manifests.

This setup ensures separation of concerns: code changes in `app-source-repo` trigger builds, while infrastructure changes in `app-manifests-repo` are managed separately.

---

## 🛠️ Step 4: The CD Pipeline (ArgoCD)

ArgoCD is the Continuous Deployment (CD) tool that automates the deployment of your containerized Java application to AKS using GitOps principles. It ensures that the desired state defined in the `app-manifests-repo` is always reflected in the Kubernetes cluster, providing automated, declarative deployments with zero downtime.

### 4.1 ArgoCD Installation and Setup

ArgoCD is installed on your Azure Kubernetes Service (AKS) cluster. It runs as a set of pods in a dedicated namespace (`argocd`) and provides a web UI for management.

#### Prerequisites for Installation
- **AKS Cluster**: Ensure you have an AKS cluster running and `kubectl` configured to access it (`az aks get-credentials --resource-group <rg> --name <cluster>`).
- **Helm**: Install Helm 3.x on your local machine or CI/CD environment.
- **Permissions**: Ensure your user or service account has permissions to create namespaces and deploy resources in AKS.

#### Step-by-Step Installation Steps

1. **Add ArgoCD Helm Repository**:
   - Open a terminal or command prompt.
   - Add the official ArgoCD Helm repository:
     ```bash
     helm repo add argo https://argoproj.github.io/argo-helm
     ```
   - Update your Helm repositories to fetch the latest charts:
     ```bash
     helm repo update
     ```

2. **Install ArgoCD Using Helm**:
   - Install ArgoCD in the `argocd` namespace with a LoadBalancer service for external access:
     ```bash
     helm install argocd argo/argo-cd --namespace argocd --create-namespace --set server.service.type=LoadBalancer
     ```
     - This command deploys ArgoCD with default settings. For production, consider customizing values like enabling HTTPS or integrating with external OIDC providers.
   - Wait for the installation to complete. Check the status:
     ```bash
     kubectl get pods -n argocd
     ```
     - You should see pods like `argocd-application-controller`, `argocd-dex-server`, `argocd-redis`, `argocd-repo-server`, and `argocd-server` in `Running` status.

3. **Retrieve Initial Admin Password**:
   - ArgoCD creates a secret with the initial admin password:
     ```bash
     kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
     ```
     - Copy this password; you'll need it to log in.

4. **Access ArgoCD Web UI**:
   - Port-forward the ArgoCD server service to your local machine:
     ```bash
     kubectl port-forward svc/argocd-server -n argocd 8080:443
     ```
     - This forwards local port 8080 to the ArgoCD server.
     - **Note**: If using the automation script, the port-forward runs in the background. If it doesn't connect, try running the command manually in a separate terminal.
   - Open a web browser and navigate to `https://localhost:8080`.
   - Log in with:
     - Username: `admin`
     - Password: The password retrieved in Step 3.
   - **Security Note**: Change the default password immediately after first login (Settings > Accounts > Update Password).

   **Troubleshooting UI Access**:
   - Ensure ArgoCD pods are running: `kubectl get pods -n argocd`.
   - Check if the port-forward is active: `ps aux | grep port-forward`.
   - If not connecting, run the port-forward command manually and keep the terminal open.
   - Verify no firewall blocks port 8080.
   - Use `http://localhost:8080` if HTTPS fails, but prefer HTTPS for security.

5. **Verify Installation**:
   - After logging in, you should see the ArgoCD dashboard.
   - Check the version in the bottom-right corner to confirm it's installed (e.g., v2.x.x).

#### Post-Installation Configuration

6. **Configure Repository Access**:
   - In the ArgoCD UI, go to Settings > Repositories > Connect Repo.
   - Choose "VIA HTTPS" or "VIA SSH" and provide the URL of your `app-manifests-repo` (e.g., `https://dev.azure.com/your-org/your-project/_git/app-manifests`).
   - If using SSH, add the private key; for HTTPS, use a personal access token (PAT) with repo read permissions.
   - Test the connection to ensure ArgoCD can access the repository.

7. **Optional: Enable Ingress for External Access**:
   - Instead of port-forwarding, set up an Ingress or use Azure Application Gateway for secure external access.
   - Example Ingress YAML:
     ```yaml
     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       name: argocd-ingress
       namespace: argocd
       annotations:
         kubernetes.io/ingress.class: azure/application-gateway
     spec:
       rules:
       - host: argocd.yourdomain.com
         http:
           paths:
           - path: /
             pathType: Prefix
             backend:
               service:
                 name: argocd-server
                 port:
                   number: 443
     ```
   - Apply it: `kubectl apply -f ingress.yaml`.

8. **Upgrade ArgoCD**:
   - To upgrade, use Helm:
     ```bash
     helm upgrade argocd argo/argo-cd --namespace argocd
     ```

This installation provides a basic ArgoCD setup. For high availability in production, deploy multiple replicas and use external databases. Refer to the [ArgoCD documentation](https://argo-cd.readthedocs.io/en/stable/) for advanced configurations.

### 4.2 Creating ArgoCD Applications

1. **Create an Application for Each Environment**:
   - In the ArgoCD UI, click "New App".
   - **Application Name**: e.g., `ovr-web-app-dev`.
   - **Project**: Default or create a new project for your applications.
   - **Sync Policy**: Set to "Automated" for automatic sync on manifest changes, or "Manual" for controlled deployments.
   - **Repository URL**: Select the connected `app-manifests-repo`.
   - **Revision**: Specify the branch (e.g., `develop` for dev, `main` for prod).
   - **Path**: The path to the Kustomize overlay (e.g., `k8s/overlays/dev`).
   - **Destination**:
     - Cluster: Your AKS cluster (use `https://kubernetes.default.svc` for in-cluster).
     - Namespace: The target namespace (e.g., `web-apps-dev`).
   - **Directory**: Set to "Kustomize" to use Kustomize for manifest processing.

2. **Sync Options**:
   - Enable "Prune Resources" to remove resources not in the manifests.
   - Enable "Self Heal" for automatic correction of drift.
   - Set sync windows if needed for maintenance periods.

3. **Health Checks and Monitoring**:
   - ArgoCD monitors application health based on Kubernetes resource statuses.
   - Configure notifications (e.g., via Slack or email) for sync failures or health issues.

### 4.3 Automated Sync and Deployment Flow

- **Triggering Deployments**: When the CI pipeline commits changes to `app-manifests-repo` (e.g., updating the image tag in `kustomization.yaml`), ArgoCD detects the change via polling or webhooks.
- **Sync Process**:
  1. ArgoCD fetches the latest manifests from the specified branch and path.
  2. It applies Kustomize transformations.
  3. Deploys the resources to AKS, ensuring zero-downtime rollouts via rolling updates.
- **Validation**: ArgoCD checks for successful deployment and reports health status.

### 4.4 Rollback and Troubleshooting

1. **Rollback via Git**:
   - If issues arise (e.g., application crashes), revert the commit in `app-manifests-repo` using Git.
   - ArgoCD will automatically sync to the previous state.

2. **Manual Rollback in ArgoCD**:
   - In the ArgoCD UI, go to the Application > History.
   - Select a previous deployment and click "Rollback".

3. **Troubleshooting**:
   - Check Application status in ArgoCD UI for sync errors.
   - View logs: `kubectl logs -n argocd deployment/argocd-application-controller`.
   - Use `kubectl describe` on failed resources for details.
   - Ensure RBAC permissions allow ArgoCD to manage resources in the target namespace.

### 4.5 Security and Best Practices

1. **RBAC and Access Control**:
   - Use ArgoCD's built-in RBAC to restrict access (e.g., read-only for developers, admin for ops).
   - Integrate with Azure AD for SSO.

2. **Security Scanning Integration**:
   - Integrate ArgoCD with Azure Security Center or Prometheus for monitoring deployments.
   - Ensure secrets are managed via Azure Key Vault or external secret managers, not in Git.

3. **Monitoring and Alerting**:
   - Set up Prometheus and Grafana to monitor ArgoCD metrics.
   - Configure alerts for failed syncs or unhealthy applications.

4. **GitOps Best Practices**:
   - Use branch protection and PR reviews for `app-manifests-repo`.
   - Avoid direct cluster modifications; all changes via Git.
   - Regularly audit ArgoCD configurations and access logs.

This setup ensures reliable, automated deployments while maintaining security and observability. For production, consider high-availability ArgoCD setups and disaster recovery plans.


---

## 🚀 Automation Script for Setup

This script automates the end-to-end setup of the DevSecOps GitOps pipeline on Azure, focusing on application deployment since infrastructure is already created. It includes ArgoCD installation, configuration, and pipeline setup. Customize the variables at the top before running. Set `SKIP_INFRA=true` if your AKS, ACR, etc., are already provisioned.

```bash
#!/bin/bash
# Application Deployment Setup Script for DevSecOps GitOps Pipeline on Azure
# Prerequisites: Azure CLI installed and logged in (az login), Helm 3.x installed, kubectl installed, AKS credentials configured.

# --- Configuration Variables (Customize these) ---
SKIP_INFRA="false"  # Set to "true" if AKS, ACR, etc., are already created
RESOURCE_GROUP="your-resource-group"
LOCATION="East US"
AKS_CLUSTER_NAME="ovr-aks-cluster"
ACR_NAME="ovrakscicd"
ARGOCD_NAMESPACE="argocd"
APP_SOURCE_REPO_URL="https://github.com/your-org/ovr-web-app.git"  # Replace with your app-source-repo URL
APP_MANIFESTS_REPO_URL="https://dev.azure.com/your-org/your-project/_git/app-manifests"  # Replace with your app-manifests-repo URL
AZURE_DEVOPS_ORG="https://dev.azure.com/your-org"
AZURE_DEVOPS_PROJECT="your-project"
SONARQUBE_URL="https://your-sonarqube-server.com"
# --- End Configuration ---

set -e  # Exit on error

echo "Starting application deployment setup for DevSecOps GitOps pipeline..."

if [ "$SKIP_INFRA" != "true" ]; then
  # 1. Create Resource Group if it doesn't exist
  echo "Creating resource group..."
  az group create --name $RESOURCE_GROUP --location "$LOCATION" || echo "Resource group already exists."

  # 2. Create AKS Cluster
  echo "Creating AKS cluster..."
  az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --node-count 2 --enable-addons monitoring --generate-ssh-keys || echo "AKS cluster already exists."

  # 3. Get AKS credentials
  echo "Retrieving AKS credentials..."
  az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

  # 4. Create Azure Container Registry (ACR)
  echo "Creating ACR..."
  az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic || echo "ACR already exists."
  az acr update --name $ACR_NAME --anonymous-pull-enabled false

  # 5. Attach ACR to AKS for image pull
  echo "Attaching ACR to AKS..."
  az aks update --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --attach-acr $ACR_NAME
else
  echo "Skipping infrastructure creation as SKIP_INFRA is set to true."
  # Ensure AKS credentials are available
  az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing
fi

# 6. Install ArgoCD using Helm
echo "Installing ArgoCD..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd --namespace $ARGOCD_NAMESPACE --create-namespace --set server.service.type=LoadBalancer --wait

# 7. Wait for ArgoCD pods to be ready
echo "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $ARGOCD_NAMESPACE

# 8. Retrieve ArgoCD admin password
ARGOCD_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD admin password: $ARGOCD_PASSWORD"

# 9. Port-forward ArgoCD UI for access (run in background)
echo "Port-forwarding ArgoCD UI to localhost:8080..."
kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE 8080:443 &
PORT_FORWARD_PID=$!
sleep 5  # Wait for port-forward to establish

# 10. Configure ArgoCD Repository Access (using PAT or SSH - assumes HTTPS with PAT)
# Note: You need to set ARGOCD_PAT environment variable with a PAT that has repo read access
if [ -z "$ARGOCD_PAT" ]; then
  echo "Warning: ARGOCD_PAT not set. Skipping repository configuration. Set it and run manually."
else
  echo "Configuring repository access in ArgoCD..."
  argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure
  argocd repo add $APP_MANIFESTS_REPO_URL --username dummy --password $ARGOCD_PAT --insecure-skip-server-verification
fi

# 11. Create ArgoCD Application for Dev Environment
echo "Creating ArgoCD application for dev environment..."
argocd app create ovr-web-app-dev \
  --repo $APP_MANIFESTS_REPO_URL \
  --path k8s/overlays/dev \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace web-apps-dev \
  --sync-policy automated \
  --auto-prune \
  --self-heal \
  --insecure-skip-server-verification

# 12. Setup Azure DevOps Pipeline (Basic setup - assumes repos exist)
echo "Setting up Azure DevOps pipeline..."
# Clone app-source-repo and copy pipeline YAML if needed
git clone $APP_SOURCE_REPO_URL temp-app-source
cp app-manifests-repo/pipelines/azure/azure-pipelines-ci.yml temp-app-source/.azure-pipelines.yml
cd temp-app-source
git add .azure-pipelines.yml
git commit -m "Add CI pipeline"
git push
cd ..
rm -rf temp-app-source

# 13. Install DevSecOps Tools (on local machine or CI agent)
echo "Installing DevSecOps tools..."
# Trivy
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
# Gitleaks
wget -q https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64.tar.gz -O /tmp/gitleaks.tar.gz && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin
# OWASP Dependency-Check
wget -q https://github.com/jeremylong/DependencyCheck/releases/latest/download/dependency-check.zip -O /tmp/dc.zip && unzip -q /tmp/dc.zip -d /opt
chmod +x /usr/local/bin/*

# 14. Final Output
echo "Setup complete!"
echo "AKS Cluster: $AKS_CLUSTER_NAME"
echo "ACR: $ACR_NAME.azurecr.io"
echo "ArgoCD UI: https://localhost:8080 (username: admin, password: $ARGOCD_PASSWORD)"
echo "Note: The port-forward is running in the background. Access the UI in your browser."
echo "To stop the port-forward later, run: kill $PORT_FORWARD_PID"
echo "Next steps:"
echo "- Change ArgoCD admin password."
echo "- Configure Azure DevOps service connections and variables."
echo "- Push application code to $APP_SOURCE_REPO_URL to trigger CI."
echo "- Monitor deployments in ArgoCD."
```

---

## 🛠️ Step 5: Integrating with AKS Service and Azure Application Gateway to Browse the URL

After deploying your application to AKS via ArgoCD, you need to expose it externally so users can access it via a URL. This section covers integrating with AKS Services and Azure Application Gateway (App Gateway) for secure, scalable external access.

### 5.1 Overview

- **AKS Service**: Use a Kubernetes Service (e.g., LoadBalancer or ClusterIP) to expose the application within the cluster.
- **Azure Application Gateway**: Acts as an ingress controller or reverse proxy to route external traffic to the AKS service, providing features like SSL termination, WAF, and load balancing.
- **Application Gateway Ingress Controller (AGIC)**: A Kubernetes ingress controller that integrates directly with App Gateway for automated configuration.

### 5.2 Prerequisites

- AKS cluster with AGIC enabled or an existing Azure Application Gateway.
- Public IP or domain for App Gateway.
- Helm for installing AGIC if not already enabled.

### 5.3 Step-by-Step Integration

1. **Expose the Application with a Kubernetes Service**:
   - For integration with Azure Application Gateway via AGIC, use a ClusterIP service (not LoadBalancer, as the Ingress handles external exposure).
   - Ensure your `service.yaml` in `k8s/base/app/service.yaml` is configured as ClusterIP.
   - Example `service.yaml`:
     ```yaml
     apiVersion: v1
     kind: Service
     metadata:
       name: ovr-web-app-service
     spec:
       selector:
         app: ovr-web-app
       ports:
       - port: 80
         targetPort: 8080
       type: ClusterIP  # Use ClusterIP for Ingress-based routing
     ```
   - Apply it: `kubectl apply -f service.yaml`.
   - The service is now accessible only within the cluster; the Ingress will route external traffic to it.
   - **Note**: ClusterIP services are internal to the Kubernetes cluster and not directly routable from outside. To expose them via Azure Application Gateway, you must use an Ingress resource. AGIC uses the Ingress to automatically configure App Gateway routing rules. Manual configuration of App Gateway to point directly to ClusterIP IPs is not supported or feasible due to network isolation.

2. **Create an Ingress Resource**:
   - Create an Ingress to route traffic from App Gateway to your ClusterIP service.
   - Example `ingress.yaml`:
     ```yaml
     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       name: ovr-web-app-ingress
       annotations:
         kubernetes.io/ingress.class: azure/application-gateway
         appgw.ingress.kubernetes.io/ssl-redirect: "true"  # Optional: Force HTTPS
     spec:
       rules:
       - host: your-app.yourdomain.com  # Replace with your domain
         http:
           paths:
           - path: /
             pathType: Prefix
             backend:
               service:
                 name: ovr-web-app-service
                 port:
                   number: 80
     ```
   - Apply it: `kubectl apply -f ingress.yaml`.
   - AGIC will automatically configure App Gateway with the routing rules based on this Ingress.

2. **Set Up Azure Application Gateway**:
   - If not already created, provision an App Gateway in the Azure portal or via CLI:
     ```bash
     az network application-gateway create \
       --resource-group $RESOURCE_GROUP \
       --name ovr-app-gateway \
       --location "$LOCATION" \
       --vnet-name your-vnet \
       --subnet your-appgw-subnet \
       --public-ip-address ovr-appgw-pip \
       --sku Standard_v2 \
       --capacity 2
     ```

3. **Install Application Gateway Ingress Controller (AGIC)**:
   - Add the AGIC Helm repo:
     ```bash
     helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
     helm repo update
     ```
   - Install AGIC:
     ```bash
     helm install ingress-azure application-gateway-kubernetes-ingress/ingress-azure \
       --namespace kube-system \
       --set appgw.name=ovr-app-gateway \
       --set appgw.resourceGroup=$RESOURCE_GROUP \
       --set appgw.subscriptionId=$(az account show --query id -o tsv) \
       --set appgw.shared=false \
       --set rbac.enabled=true
     ```

4. **Create an Ingress Resource**:
   - Create an Ingress to route traffic from App Gateway to your service.
   - Example `ingress.yaml`:
     ```yaml
     apiVersion: networking.k8s.io/v1
     kind: Ingress
     metadata:
       name: ovr-web-app-ingress
       annotations:
         kubernetes.io/ingress.class: azure/application-gateway
         appgw.ingress.kubernetes.io/ssl-redirect: "true"  # Optional: Force HTTPS
     spec:
       rules:
       - host: your-app.yourdomain.com  # Replace with your domain
         http:
           paths:
           - path: /
             pathType: Prefix
             backend:
               service:
                 name: ovr-web-app-service
                 port:
                   number: 80
     ```
   - Apply it: `kubectl apply -f ingress.yaml`.
   - AGIC will automatically configure App Gateway with the rules.

5. **Configure DNS and SSL**:
   - Point your domain (e.g., `your-app.yourdomain.com`) to the App Gateway's public IP.
   - For SSL, upload certificates to App Gateway or use Azure Key Vault integration.
   - Enable WAF on App Gateway for security.

6. **Access the Application**:
   - Once configured, browse to `https://your-app.yourdomain.com` (or the App Gateway IP if no domain).
   - Verify the application loads and responds correctly.

### 5.4 Troubleshooting

- **App Gateway Health Probes**: Ensure probes match your service ports and paths.
- **AGIC Logs**: Check logs: `kubectl logs -n kube-system deployment/ingress-azure`.
- **Firewall/Routing**: Confirm NSGs allow traffic to App Gateway and AKS.
- **SSL Issues**: Verify certificate installation and redirect settings.

This setup provides a secure, external endpoint for your application, integrating seamlessly with your GitOps workflow.

