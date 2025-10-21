<#
.SYNOPSIS
    Secure PowerShell script to build a Java web application,
    create a Docker image, and deploy it to a Kubernetes cluster.

.DESCRIPTION
    This script automates Maven build, Docker image creation,
    and Kubernetes deployment/deletion steps for Windows environments.

.PARAMETER Action
    Specifies the primary action to perform.
    Valid options are 'deploy' (builds and deploys the app) or 'delete' (removes the app from Kubernetes).

.PARAMETER Namespace
    The Kubernetes namespace to operate in. (Default: ovr-ns)

.PARAMETER Tag
    The Docker image tag to use. (Default: v1.0)

.EXAMPLE
    .\build-deploy-java-K8s.ps1 deploy -Namespace my-app
    This command builds the Java application, creates a Docker image, and deploys it to the 'my-app' namespace.

.EXAMPLE
    .\build-deploy-java-K8s.ps1 delete
    This command deletes the application resources from the 'ovr-ns' namespace.

.NOTES
    Author: Your Name
    Version: 1.0
    Tested on: PowerShell 7.4+, Windows 10/11
#>

param(
    [Parameter(Position = 0, HelpMessage = "Specifies the action to perform. Valid options: 'deploy' or 'delete'.")]
    [ValidateSet('deploy', 'delete')]
    [string]$Action,

    [string]$Namespace = "ovr-ns",
    # [string]$Registry = "docker.io/acme",
    [string]$Tag = "v1.0",
    [switch]$Help # Kept for -? or -Help functionality
)

# Ensure consistent UTF-8 output for files created by this script
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

# ---------------------------------------------------------------------------
# Global Configuration
# ---------------------------------------------------------------------------
$AppName = "ovr-web-app-image"
$K8sManifestFile = "k8s-manifests.yaml"
$K8sDeploymentName = "ovr-web-app-dep" # Must match metadata.name in the YAML
$JavaAppDir = "C:\VSCodeProjects\DemoApps\ovrinda-web-app" # Path to the Java project


# ---------------------------------------------------------------------------
# Function: Show Help
# ---------------------------------------------------------------------------
function Show-Help {
    Get-Help $PSCommandPath -Detailed
    exit 0
}

# ---------------------------------------------------------------------------
# Function: Check Required Tools
# ---------------------------------------------------------------------------
function Check-Dependencies {
    $required = @("mvn", "docker", "kubectl")
    foreach ($cmd in $required) {
        if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
            Write-Error "Required command '$cmd' not found. Please install it before proceeding."
            exit 1
        }
    }
    Write-Host "All dependencies verified."
}

# ---------------------------------------------------------------------------
# Function: Build Java Application
# ---------------------------------------------------------------------------
function Build-App {
    Write-Host "Building Java app in $JavaAppDir ..."
    Set-Location $JavaAppDir
    mvn clean package -DskipTests
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Maven build failed."
        exit 1
    }
    Write-Host "Build completed."
}

# ---------------------------------------------------------------------------
# Function: Build Docker Image
# ---------------------------------------------------------------------------
function Build-Image {
    Write-Host "Building Docker image..."
    Set-Location $PSScriptRoot
    Write-Host "Current Dir: $PWD"
    $image = "${AppName}:${Tag}"
    docker build --no-cache -t $image -f "$PSScriptRoot\Dockerfile" $JavaAppDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker image build failed."
        exit 1
    }
    Write-Host "Docker image built: $image"
}
# ---------------------------------------------------------------------------
# Function: Push Docker Image
# ---------------------------------------------------------------------------
#
# function Push-Image {
#     Write-Host "Pushing Docker image..."
#     $image = "${AppName}:${Tag}"
#     docker push $image
#     if ($LASTEXITCODE -ne 0) {
#         Write-Error "Docker push failed."
#         exit 1
#     }
#     Write-Host "Docker image pushed to $Registry"
# }
#

# ---------------------------------------------------------------------------
# Function: Validate Kubernetes Access
# ---------------------------------------------------------------------------
function Validate-Access {
    Write-Host "Validating Kubernetes cluster access..."
    kubectl version | Out-Null
    kubectl get pods
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Cannot access Kubernetes cluster. Check kubeconfig or credentials."
        exit 1
    }
    Write-Host "Kubernetes access verified."
}

# ---------------------------------------------------------------------------
# Function: Deploy to Kubernetes
# ---------------------------------------------------------------------------
function Deploy-K8s {
    Write-Host "Deploying to Kubernetes namespace '$Namespace'..."
    $image = "${AppName}:${Tag}"

    # Replace placeholders safely using PowerShell's string method
    $content = Get-Content -Path "$PSScriptRoot\$K8sManifestFile" -Raw
    $updatedContent = $content.Replace('${IMAGE}', $image)
    $updatedFile = Join-Path $env:TEMP "deployment-temp.yaml"
    $updatedContent | Out-File -FilePath $updatedFile -Encoding utf8

    Write-Host "updatedContent: $updatedContent"
    Write-Host "updatedFile: $updatedFile"


    kubectl apply -n $Namespace -f $updatedFile
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Deployment failed."
        exit 1
    }

    Write-Host "Deployment applied successfully."
    # Write-Host "Checking rollout status..."
    # kubectl rollout status deployment/$K8sDeploymentName -n $Namespace --timeout=2m
    # if ($LASTEXITCODE -ne 0) {
    #     Write-Error "Deployment rollout failed. Check pod logs for more details"
    #     exit 1
    # }

    # Clean up the temporary file after deployment
    Remove-Item -Path $updatedFile -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Function: Remove from Kubernetes
# ---------------------------------------------------------------------------
function Remove-K8s {
    Write-Host "Deleting deployment from Kubernetes namespace '$Namespace'..."
    $image = "${AppName}:${Tag}"

    # The delete command also needs the manifest with placeholders replaced
    # to ensure it targets the correct resources, especially if names were dynamic.
    $content = Get-Content -Path "$PSScriptRoot\$K8sManifestFile" -Raw
    $updatedContent = $content.Replace('${IMAGE}', $image)
    $updatedFile = Join-Path $env:TEMP "deployment-temp.yaml"
    $updatedContent | Out-File -FilePath $updatedFile -Encoding utf8

    Write-Host "Deleting resources defined in $updatedFile..."
    # Use --ignore-not-found to prevent errors if the resources are already gone.
    kubectl delete -n $Namespace -f $updatedFile --ignore-not-found
    if ($LASTEXITCODE -ne 0) {
        # This might indicate a problem other than "not found".
        Write-Warning "Deletion command returned a non-zero exit code."
    } else {
        Write-Host "Resources deleted successfully."
    }

    # Clean up the temporary file
    Remove-Item -Path $updatedFile -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# MAIN LOGIC
# ---------------------------------------------------------------------------
function Main {
    # If -Help is specified or no action is provided, show help and exit.
    if ($Help) { Show-Help }
    if ([string]::IsNullOrEmpty($Action)) {
        Write-Host "Error: No action specified." -ForegroundColor Red
        Write-Host "Specifies the action to perform. Valid options: 'deploy' or 'delete'."
        exit 1
    }

    # Validations should only run if an action is requested.
    Check-Dependencies
    Validate-Access
    
    switch ($Action) {
        'deploy' {
            Build-App
            Build-Image
            Deploy-K8s
        }
        'delete' { Remove-K8s }
    }
}

# ---------------------------------------------------------------------------
# Run main
# ---------------------------------------------------------------------------
Main
