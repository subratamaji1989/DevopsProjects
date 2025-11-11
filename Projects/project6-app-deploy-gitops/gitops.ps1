# Application Deployment Setup Script for DevSecOps GitOps Pipeline on Azure
# Prerequisites: Azure CLI installed and logged in (az login), Helm 3.x installed, kubectl installed, AKS credentials configured.

# --- Configuration Variables (Customize these) ---
$SKIP_INFRA = "true"  # Set to "true" if AKS, ACR, etc., are already created
$RESOURCE_GROUP = "ovr-rg"
$LOCATION = "South India"
$AKS_CLUSTER_NAME = "dev-aks-cluster"
$ACR_NAME = "ovrcontainerregistry"
$ARGOCD_NAMESPACE = "argocd"
$APP_SOURCE_REPO_URL = "https://OVRINDA@dev.azure.com/OVRINDA/ovr-devops/_git/ovr-web-app"  # Replace with your app-source-repo URL
$APP_MANIFESTS_REPO_URL = "https://OVRINDA@dev.azure.com/OVRINDA/ovr-devops/_git/cicd-manifests"  # Replace with your cicd-manifests-repo URL
# --- End Configuration ---

Write-Host "Starting application deployment setup for DevSecOps GitOps pipeline..."

if ($SKIP_INFRA -ne "true") {
    # 1. Create Resource Group if it doesn't exist
    Write-Host "Creating resource group..."
    try {
        az group create --name $RESOURCE_GROUP --location "$LOCATION"
    } catch {
        Write-Host "Resource group already exists."
    }

    # 2. Create AKS Cluster
    Write-Host "Creating AKS cluster..."
    try {
        az aks create --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --node-count 2 --enable-addons monitoring --generate-ssh-keys
    } catch {
        Write-Host "AKS cluster already exists."
    }

    # 3. Get AKS credentials
    Write-Host "Retrieving AKS credentials..."
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing

    # 4. Create Azure Container Registry (ACR)
    Write-Host "Creating ACR..."
    try {
        az acr create --resource-group $RESOURCE_GROUP --name $ACR_NAME --sku Basic
    } catch {
        Write-Host "ACR already exists."
    }
    az acr update --name $ACR_NAME --anonymous-pull-enabled false

    # 5. Attach ACR to AKS for image pull
    Write-Host "Attaching ACR to AKS..."
    az aks update --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --attach-acr $ACR_NAME
} else {
    Write-Host "Skipping infrastructure creation as SKIP_INFRA is set to true."
    # Ensure AKS credentials are available
    az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --overwrite-existing
}

# 6. Check and Install ArgoCD using Helm
Write-Host "Checking ArgoCD installation..."
$argocdExists = kubectl get deployment argocd-server -n $ARGOCD_NAMESPACE --ignore-not-found=true
if ($argocdExists) {
    Write-Host "ArgoCD is already installed, skipping installation."
} else {
    Write-Host "Installing ArgoCD..."
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm install argocd argo/argo-cd --namespace $ARGOCD_NAMESPACE --create-namespace --set server.service.type=LoadBalancer --wait
}

# 7. Wait for ArgoCD pods to be ready
Write-Host "Waiting for ArgoCD to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $ARGOCD_NAMESPACE

# 8. Retrieve ArgoCD admin password
$ARGOCD_PASSWORD_ENCODED = kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE -o jsonpath="{.data.password}"
$ARGOCD_PASSWORD = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($ARGOCD_PASSWORD_ENCODED))
Write-Host "ArgoCD admin password: $ARGOCD_PASSWORD"

# 9. Port-forward ArgoCD UI for access (run in background)
Write-Host "Port-forwarding ArgoCD UI to localhost:8080..."
$portForwardJob = Start-Job -ScriptBlock {
    kubectl port-forward svc/argocd-server -n argocd 8080:443
}
Start-Sleep -Seconds 5  # Wait for port-forward to establish
Write-Host "Port-forward is running in the background. Access the UI at https://localhost:8080"
Write-Host "To stop the port-forward later, run: Stop-Job -Job `$portForwardJob (or close the PowerShell session)"

# 10. Install ArgoCD CLI if not present
Write-Host "Checking for ArgoCD CLI..."
if (-not (Get-Command argocd -ErrorAction SilentlyContinue)) {
    Write-Host "Installing ArgoCD CLI..."
    $argocdVersion = (Invoke-RestMethod -Uri "https://api.github.com/repos/argoproj/argo-cd/releases/latest").tag_name
    $downloadUrl = "https://github.com/argoproj/argo-cd/releases/download/$argocdVersion/argocd-windows-amd64.exe"
    $argocdPath = "$env:TEMP\argocd.exe"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $argocdPath
    # Add to PATH for this session
    $env:PATH += ";$env:TEMP"
    Write-Host "ArgoCD CLI installed."
} else {
    Write-Host "ArgoCD CLI is already installed."
}

# 11. Configure ArgoCD Repository Access (using PAT or SSH - assumes HTTPS with PAT)
# Note: You need to set ARGOCD_PAT environment variable with a PAT that has repo read access
# if (-not $env:ARGOCD_PAT) {
#     Write-Host "Warning: ARGOCD_PAT not set. Skipping repository configuration. Set it and run manually."
# } else {
#     Write-Host "Configuring repository access in ArgoCD..."
#     argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure --skip-test-tls
#     argocd repo add $APP_MANIFESTS_REPO_URL --username dummy --password $env:ARGOCD_PAT --insecure --skip-test-tls
# }

if (-not $env:ARGOCD_PAT) {
    Write-Host "Warning: ARGOCD_PAT not set. Skipping repository configuration and application creation. Set it and run manually."
} else {
    Write-Host "Configuring repository access in ArgoCD..."
    argocd login localhost:8080 --username admin --password $ARGOCD_PASSWORD --insecure
    argocd repo add $APP_MANIFESTS_REPO_URL --username dummy --password $env:ARGOCD_PAT --insecure

    # 12. Create ArgoCD Application for Dev Environment (if not exists)
    Write-Host "Checking if ArgoCD application exists..."
    $appExists = argocd app get ovr-web-app-dev --ignore-not-found=true 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "ArgoCD application 'ovr-web-app-dev' already exists, skipping creation."
    } else {
        Write-Host "Creating ArgoCD application for dev environment..."
        argocd app create ovr-web-app-dev `
            --repo $APP_MANIFESTS_REPO_URL `
            --path k8s/overlays/dev `
            --dest-server https://kubernetes.default.svc `
            --dest-namespace web-app-ns `
            --sync-policy automated `
            --auto-prune `
            --self-heal `
            --insecure
    }
}

# # 12. Setup Azure DevOps Pipeline (Basic setup - assumes repos exist)
# Write-Host "Setting up Azure DevOps pipeline..."
# # Clone app-source-repo and copy pipeline YAML if needed
# git clone $APP_SOURCE_REPO_URL temp-app-source
# Copy-Item cicd-manifests/pipelines/azure/azure-pipelines-ci.yml temp-app-source/.azure-pipelines.yml
# Set-Location temp-app-source
# git add .azure-pipelines.yml
# git commit -m "Add CI pipeline"
# git push
# Set-Location ..
# Remove-Item -Recurse -Force temp-app-source

# # # 13. Install DevSecOps Tools (on local machine or CI agent)
# # Write-Host "Installing DevSecOps tools..."
# # # Trivy
# # curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
# # # Gitleaks
# # wget -q https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64.tar.gz -O /tmp/gitleaks.tar.gz && tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin
# # # OWASP Dependency-Check
# # wget -q https://github.com/jeremylong/DependencyCheck/releases/latest/download/dependency-check.zip -O /tmp/dc.zip && unzip -q /tmp/dc.zip -d /opt
# # chmod +x /usr/local/bin/*

# 14. Install Application Gateway Ingress Controller (AGIC) for external access
Write-Host "Installing Application Gateway Ingress Controller (AGIC)..."
helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update
helm install ingress-azure application-gateway-kubernetes-ingress/ingress-azure `
    --namespace kube-system `
    --set appgw.name=ovr-app-gateway `
    --set appgw.resourceGroup=$RESOURCE_GROUP `
    --set appgw.subscriptionId=$(az account show --query id -o tsv) `
    --set appgw.shared=false `
    --set rbac.enabled=true

# 15. Create Ingress for external access via App Gateway
Write-Host "Creating Ingress resource for external access..."
$ingressYaml = @"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ovr-web-app-ingress
  annotations:
    kubernetes.io/ingress.class: azure/application-gateway
    appgw.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
  - host: your-app.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: ovr-web-app-service
            port:
              number: 80
"@
$ingressYaml | Out-File -FilePath "ingress.yaml" -Encoding UTF8
kubectl apply -f ingress.yaml
Remove-Item "ingress.yaml"

# 16. Final Output
Write-Host "Setup complete!"
Write-Host "AKS Cluster: $AKS_CLUSTER_NAME"
Write-Host "ACR: $ACR_NAME.azurecr.io"
Write-Host "ArgoCD UI: https://localhost:8080 (username: admin, password: $ARGOCD_PASSWORD)"
Write-Host "Ingress created for external access via Azure Application Gateway."
Write-Host "Next steps:"
Write-Host "- Change ArgoCD admin password."
Write-Host "- Configure Azure DevOps service connections and variables."
Write-Host "- Push application code to $APP_SOURCE_REPO_URL to trigger CI."
Write-Host "- Monitor deployments in ArgoCD."
Write-Host "- Update the Ingress host to your actual domain and configure DNS to point to App Gateway IP."

# Note: Port-forward is kept running in the background. Do not close this PowerShell session.
# To stop the port-forward later, run: Stop-Job -Job $portForwardJob
