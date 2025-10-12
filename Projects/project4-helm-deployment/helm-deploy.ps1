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
$HelmReleaseName = "ovr-web-app-helm" # The name for this specific deployment instance
$HelmChartPath = "$PSScriptRoot\ovr-web-app-chart"
$ImageName = "ovr-web-app-image"
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
    $required = @("mvn", "docker", "kubectl", "helm")
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
    $image = "${ImageName}:${Tag}"
    # Using multi-stage build, the context is the Java project directory
    docker build --no-cache -t $image -f "$PSScriptRoot\Dockerfile" $JavaAppDir # The context is now the Java project dir
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
#     $image = "${ImageName}:${Tag}"
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

    # Use helm upgrade with --install to either install a new release or upgrade an existing one.
    # This is an idempotent command.
    helm upgrade --install $HelmReleaseName $HelmChartPath `
        --namespace $Namespace `
        --create-namespace `
        --set image.tag=$Tag

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Helm deployment failed."
        exit 1
    }

    Write-Host "Helm release '$HelmReleaseName' deployed successfully."
}

# ---------------------------------------------------------------------------
# Function: Remove from Kubernetes
# ---------------------------------------------------------------------------
function Remove-K8s {
    Write-Host "Uninstalling Helm release '$HelmReleaseName' from namespace '$Namespace'..."
    helm uninstall $HelmReleaseName --namespace $Namespace
    if ($LASTEXITCODE -ne 0) {
        # This might indicate a problem other than "not found".
        Write-Warning "Deletion command returned a non-zero exit code."
    } else {
        Write-Host "Resources deleted successfully."
    }

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
            # Build-App is no longer needed as it's part of the multi-stage Docker build
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
