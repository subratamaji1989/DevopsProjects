<#
.SYNOPSIS
    Builds and runs the Java web application locally.

.DESCRIPTION
    This script automates the process of building a Java Maven project
    and running the resulting executable JAR file.

.EXAMPLE
    .\app-build-run.ps1
    Builds and then runs the application.

.NOTES
    Requires Java (JDK) and Maven to be installed and available in the system's PATH.
#>

# --- Configuration ---
# The script assumes the Java project is in a subdirectory named 'ovr-web-app'
$JavaAppDir = Join-Path $PSScriptRoot "ovr-web-app"

# --- Function to Check for Required Tools ---
function Check-Dependencies {
    Write-Host "Verifying required tools (java, mvn)..." -ForegroundColor Cyan
    $requiredTools = @("java", "mvn")
    foreach ($tool in $requiredTools) {
        if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
            Write-Error "❌ Required command '$tool' not found. Please ensure it is installed and in your system's PATH."
            exit 1
        }
    }
    Write-Host "✅ All tools verified." -ForegroundColor Green
} # This closing brace was missing

# --- Function to Build the Application ---
function Build-JavaApp {
    Write-Host "Building the Java application in '$JavaAppDir'..." -ForegroundColor Cyan
    
    # Temporarily change to the Java project directory to run Maven
    Push-Location $JavaAppDir
    
    mvn clean package -DskipTests
    
    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ Maven build failed."
        Pop-Location # Ensure we return to the original directory even on failure
        exit 1
    }
    
    Pop-Location
    Write-Host "✅ Build completed successfully." -ForegroundColor Green
}

# --- Function to Run the Application ---
function Run-JavaApp {
    # Find the JAR file in the target directory
    $jarFile = Get-ChildItem -Path (Join-Path $JavaAppDir "target") -Filter "*.jar" | Select-Object -First 1

    if (-not $jarFile) {
        Write-Error "❌ JAR file not found. Please run the 'build' action first."
        exit 1
    }

    Write-Host "🚀 Running the application: $($jarFile.Name)" -ForegroundColor Cyan
    Write-Host "   You can access the web app at http://localhost:8080"
    Write-Host "   Press CTRL+C to stop the application"
    
    # Execute the JAR file
    java -jar $jarFile.FullName
    # mvn spring-boot:run
}

# --- Main Logic ---
Check-Dependencies
Build-JavaApp
Run-JavaApp