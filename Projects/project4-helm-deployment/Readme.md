# 🧭 Helm — End-to-End DevSecOps Guide

**Purpose:** This document serves as a comprehensive guide for building, packaging, and deploying containerized applications to Kubernetes using Helm, following enterprise-grade DevSecOps standards.

---

## 📘 Table of Contents

1.  [Introduction to Helm](#-1-introduction-to-helm)
2.  [Helm Installation](#️-2-helm-installation)
3.  [Helm Concepts Overview](#-3-helm-concepts-overview)
4.  [Creating and Structuring a Helm Chart](#-4-creating-and-structuring-a-helm-chart)
5.  [Converting Kubernetes Manifests to Helm Charts](#-5-converting-kubernetes-manifests-to-helm-charts)
6.  [Building and Deploying with Helm](#-6-building-and-deploying-with-helm)
7.  [Helm Commands Cheat Sheet](#-7-helm-commands-cheat-sheet)
8.  [Helm Plugin Ecosystem](#-8-helm-plugin-ecosystem)
9.  [Security & DevSecOps Best Practices](#️-9-security--devsecops-best-practices)
10. [CI/CD Integration](#️-10-cicd-integration)
11. [Troubleshooting](#-11-troubleshooting)
12. [Appendix: Example Java App Helm Project](#-12-appendix--example-java-app-helm-project)

---

## 🧩 1. Introduction to Helm

### 🔹 What is Helm?

Helm is the package manager for Kubernetes, similar to how `apt`/`yum` works for Linux. It simplifies the deployment, upgrade, and rollback of complex Kubernetes applications by packaging manifests into **Helm charts**.

### 🔹 Why Use Helm?

| Benefit                   | Description                                                  |
| ------------------------- | ------------------------------------------------------------ |
| **Simplifies Deployment** | One command to deploy entire applications.                   |
| **Version Control**       | Helm charts are versioned and reusable.                      |
| **Environment Management**| Manage multiple environments (dev/stage/prod) via `values.yaml`. |
| **Rollbacks**             | Helm keeps a release history for easy rollbacks.             |
| **Declarative + Reproducible** | Ensures consistent and immutable deployments.                |

---

## ⚙️ 2. Helm Installation

### 🧩 Linux / macOS
```bash
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
# OR
brew install helm
```

### 🪟 Windows (PowerShell)
```powershell
choco install kubernetes-helm -y
# or
scoop install helm
# or
winget install Helm.Helm
```

### ✅ Verify
```bash
helm version
```

---

## 📚 3. Helm Concepts Overview

| Concept       | Description                                          |
| ------------- | ---------------------------------------------------- |
| **Chart**     | A Helm package containing templates, values, and metadata. |
| **Release**   | A deployed instance of a chart in a Kubernetes cluster. |
| **Repository**| A collection of charts stored for reuse.             |
| `Values.yaml` | Default configuration parameters for your chart.     |
| `Templates/`  | Directory containing Kubernetes YAML templates.      |
| `Chart.yaml`  | Metadata file defining chart name, version, and description. |

---

## 🏗️ 4. Creating and Structuring a Helm Chart

### Step 1 — Create a New Chart
```bash
helm create myapp
```

### Step 2 — Chart Structure
```
myapp/
 ├── Chart.yaml
 ├── values.yaml
 ├── charts/
 └── templates/
     ├── deployment.yaml
     ├── service.yaml
     └── _helpers.tpl
```

### Step 3 — Customize Chart Metadata
Edit `Chart.yaml`:
```yaml
apiVersion: v2
name: myapp
description: A Helm chart for deploying my Java app
version: 1.0.0
appVersion: "v1.0.0"
```

---

## 🔁 5. Converting Kubernetes Manifests to Helm Charts

If you already have plain Kubernetes YAMLs, you can Helmify them.

### Step 1 — Create Chart
```bash
helm create java-webapp
```

### Step 2 — Copy Your Existing YAMLs
```bash
mv k8s/*.yaml java-webapp/templates/
```

### Step 3 — Replace Hardcoded Values with Helm Templates
**Before:**
```yaml
replicas: 3
image: myrepo/app:latest
```
**After:**
```yaml
replicas: {{ .Values.replicaCount }}
image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

### Step 4 — Update `values.yaml`
```yaml
replicaCount: 3
image:
  repository: myrepo/app
  tag: latest
  pullPolicy: IfNotPresent
service:
  type: NodePort
  port: 8080
  nodePort: 30080
```

### Step 5 — Validate
```bash
helm lint java-webapp
helm template java-webapp
```

---

## 🚀 6. Building and Deploying with Helm

### Step 1 — Package Chart
```bash
helm package ./java-webapp
```

### Step 2 — Install or Upgrade Release
```bash
helm upgrade --install java-webapp ./java-webapp -f values.yaml \
  --namespace dev --create-namespace --atomic
```

### Step 3 — Check Release Status
```bash
helm list -n dev
kubectl get pods -n dev
```

### Step 4 — Rollback
```bash
helm rollback java-webapp 1
```
### Step 4 — Uninstall
```bash
helm uninstall java-webapp -n dev
```

---

## 🧠 7. Helm Commands Cheat Sheet

| Command                 | Description                  |
| ----------------------- | ---------------------------- |
| `helm create`           | Create a new chart           |
| `helm lint`             | Validate chart syntax        |
| `helm template`         | Render templates locally     |
| `helm install`          | Install a release            |
| `helm upgrade --install`| Upgrade or install           |
| `helm rollback`         | Roll back to a previous version |
| `helm history`          | View release history         |
| `helm uninstall`        | Delete a release             |
| `helm diff upgrade`     | Compare before upgrading     |

---

## 🧩 8. Helm Plugin Ecosystem
Install useful plugins:
```bash
helm plugin install https://github.com/databus23/helm-diff
helm plugin install https://github.com/jkroepke/helm-secrets
helm plugin install https://github.com/quintush/helm-unittest
```
| Plugin          | Purpose                        |
| --------------- | ------------------------------ |
| `helm-diff`     | Show differences before upgrades |
| `helm-secrets`  | Encrypt/decrypt values files   |
| `helm-unittest` | Test chart logic               |

---

## 🛡️ 9. Security & DevSecOps Best Practices

| Area                | Recommendation                                       |
| ------------------- | ---------------------------------------------------- |
| **Image Security**  | Use SHA256 digests and scan with `trivy`             |
| **RBAC**            | Limit privileges using dedicated `ServiceAccounts`   |
| **Secrets**         | Use `SealedSecrets` or `SOPS` integration            |
| **Chart Signing**   | `helm package --sign` with GPG                       |
| **CIS Benchmark**   | Validate with `kubescape scan`                       |
| **Atomic Upgrades** | Always use `--atomic` to prevent partial deployments |
| **GitOps Ready**    | Commit only Helm sources, not generated manifests    |

---

## ⚙️ 10. CI/CD Integration

### Example GitHub Actions Workflow
```yaml
name: Deploy with Helm

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Helm
        uses: azure/setup-helm@v4
      - name: Helm Lint
        run: helm lint ./chart
      - name: Template & Scan
        run: helm template ./chart | kubescape scan --stdin
      - name: Deploy to Kubernetes
        run: |
          helm upgrade --install myapp ./chart \
            --namespace prod --create-namespace --atomic
```

---

## 🧯 11. Troubleshooting

| Problem               | Solution                                       |
| --------------------- | ---------------------------------------------- |
| `ImagePullBackOff`    | Verify Docker image tag and registry credentials |
| Helm upgrade fails    | Use `--atomic` or `rollback`                   |
| Service not reachable | Check `NodePort` or `ingress`                  |
| Validation errors     | Run `helm lint`                                |
| Secrets not loading   | Check `helm-secrets` or Kubernetes `Secret` mounts |

---

## 🧩 12. Appendix — Example: Java App Helm Project

### Project Structure
```
├── helm-deploy.ps1
├── Dockerfile
└── ovr-web-app-chart/
    ├── Chart.yaml
    ├── values.yaml
    └── templates/
        ├── deployment.yaml
        ├── service.yaml
        └── _helpers.tpl
```

### Example `values.yaml`
```yaml
replicaCount: 2
image:
  repository: myregistry/ovr-web-app
  tag: "v1.0.0"
service:
  type: NodePort
  port: 8080
  nodePort: 30080
```

### PowerShell Deployment Script (`helm-deploy.ps1`)
```powershell
param(
  [string]$Action = "deploy",
  [string]$Tag = "latest",
  [string]$Namespace = "ovr-ns"
)

function Build-App {
    Write-Host "🔧 Building Java app..."
    mvn clean package -DskipTests
    if ($LASTEXITCODE -ne 0) { Write-Error "❌ Build failed."; exit 1 }
}

function Build-Image {
    Write-Host "🐳 Building Docker image..."
    docker build -t myregistry/ovr-web-app:$Tag .
}

function Deploy-App {
    Write-Host "🚀 Deploying via Helm..."
    helm upgrade --install ovr-web-app ./ovr-web-app-chart `
      --set image.tag=$Tag `
      --namespace $Namespace --create-namespace --atomic
}

function Delete-App {
    Write-Host "🧹 Cleaning up..."
    helm uninstall ovr-web-app -n $Namespace
}

switch ($Action) {
    "deploy" { Build-App; Build-Image; Deploy-App }
    "delete" { Delete-App }
    default { Write-Host "Usage: .\helm-deploy.ps1 [-Action deploy|delete] [-Tag v1.0] [-Namespace ns]" }
}
```

---

## 🏁 Final Command Summary

**Create a chart**
```bash
helm create myapp
```

**Validate and render**
```bash
helm lint ./myapp && helm template ./myapp
```

**Deploy**
```bash
helm upgrade --install myapp ./myapp -f values.yaml --atomic
```

**Rollback**
```bash
helm rollback myapp 1
```

**Uninstall**
```bash
helm uninstall myapp -n prod
```

---

## 💎 Conclusion

This structured Helm workflow provides:
-   Reproducible, secure deployments
-   Environment consistency
-   Full automation support
-   CI/CD and security integration
-   Scalable Helm-based DevSecOps pattern