# Azure DevOps Cheat Sheet (Beginner → Expert)

[![Azure DevOps](https://img.shields.io/badge/Azure%20DevOps-0078D4?style=for-the-badge&logo=azure-devops&logoColor=white)](https://dev.azure.com)
[![YAML](https://img.shields.io/badge/YAML-000000?style=for-the-badge&logo=yaml&logoColor=white)](https://yaml.org)
[![Git](https://img.shields.io/badge/Git-F05032?style=for-the-badge&logo=git&logoColor=white)](https://git-scm.com)

> Covers setup, projects, repos, pipelines, boards, artifacts, security, CLI, and best practices.

## 🚀 Quick Start

- [Sign in to Azure DevOps](https://dev.azure.com)
- Install Azure DevOps CLI: `az extension add --name azure-devops`

---

## Table of Contents

1. [Introduction & Setup](#1-introduction--setup)
2. [Azure DevOps Projects](#2-azure-devops-projects)
3. [Repos (Git)](#3-repos-git)
4. [Pipelines (CI/CD)](#4-pipelines-cicd)
5. [Pipeline Syntax Examples (YAML)](#5-pipeline-syntax-examples-yaml)
6. [Boards (Agile Planning)](#6-boards-agile-planning)
7. [Artifacts (Packages)](#7-artifacts-packages)
8. [Test Plans](#8-test-plans)
9. [Security & Permissions](#9-security--permissions)
10. [Service Connections & Integrations](#10-service-connections--integrations)
11. [CLI & REST API](#11-cli--rest-api)
12. [Monitoring & Logs](#12-monitoring--logs)
13. [Best Practices & Tips](#13-best-practices--tips)

---

# 1. Introduction & Setup

**What is Azure DevOps?**

* Microsoft’s DevOps platform for source control, CI/CD, project management, and artifacts.

**Sign in**

* [https://dev.azure.com](https://dev.azure.com)

**Install Azure DevOps CLI**

```bash
az extension add --name azure-devops
az devops configure --defaults organization=https://dev.azure.com/MyOrg project=MyProject
```

---

# 2. Azure DevOps Projects

**Create a project**

```bash
az devops project create --name MyProject --visibility private
```

**List projects**

```bash
az devops project list --output table
```

---

# 3. Repos (Git)

**Clone repo**

```bash
git clone https://dev.azure.com/MyOrg/MyProject/_git/MyRepo
```

**Create repo**

```bash
az repos create --name MyRepo
```

**Branch policies**

* Require PR reviews
* Enforce build validation
* Limit force pushes

---

# 4. Pipelines (CI/CD)

**Create pipeline**

```bash
az pipelines create --name MyPipeline --repository MyRepo --branch main --yml-path azure-pipelines.yml
```

**Run pipeline**

```bash
az pipelines run --name MyPipeline
```

**List pipelines**

```bash
az pipelines list --output table
```

---

# 5. Pipeline Syntax Examples (YAML)

**Basic CI**

```yaml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- script: echo "Hello Azure DevOps"
  displayName: 'Run a one-line script'
```

**Build + Test + Deploy**

```yaml
stages:
- stage: Build
  jobs:
  - job: BuildJob
    pool:
      vmImage: 'ubuntu-latest'
    steps:
    - script: mvn clean install

- stage: Test
  jobs:
  - job: TestJob
    steps:
    - script: mvn test

- stage: Deploy
  jobs:
  - deployment: DeployWeb
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo Deploying...
```

**Matrix builds**

```yaml
strategy:
  matrix:
    linux:
      vmImage: 'ubuntu-latest'
    windows:
      vmImage: 'windows-latest'
```

### 5.4 Reusable Templates

Reusable templates allow you to define common pipeline components in separate YAML files and reference them in your main pipeline.

**Example: Job Template (templates/build-job.yml)**

```yaml
parameters:
- name: buildTool
  type: string
  default: 'maven'
- name: testCommand
  type: string
  default: 'mvn test'

jobs:
- job: BuildAndTest
  pool:
    vmImage: 'ubuntu-latest'
  steps:
  - script: |
      if [ "${{ parameters.buildTool }}" == "maven" ]; then
        mvn clean install
      elif [ "${{ parameters.buildTool }}" == "gradle" ]; then
        ./gradlew build
      fi
    displayName: 'Build with ${{ parameters.buildTool }}'
  - script: ${{ parameters.testCommand }}
    displayName: 'Run tests'
```

**Using the Template in Main Pipeline**

```yaml
stages:
- stage: Build
  jobs:
  - template: templates/build-job.yml
    parameters:
      buildTool: 'gradle'
      testCommand: './gradlew test'
```

### 5.5 Parameters

Parameters enable dynamic configuration of pipelines at runtime.

**Runtime Parameters Example**

```yaml
parameters:
- name: environment
  displayName: 'Environment'
  type: string
  default: 'dev'
  values:
  - dev
  - staging
  - prod
- name: deploy
  displayName: 'Deploy?'
  type: boolean
  default: false

stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - script: echo "Building for ${{ parameters.environment }}"

- ${{ if parameters.deploy }}:
  - stage: Deploy
    jobs:
    - deployment: DeployJob
      environment: ${{ parameters.environment }}
      strategy:
        runOnce:
          deploy:
            steps:
            - script: echo "Deploying to ${{ parameters.environment }}"
```

**User Input Parameters with Approvals and Timeouts**

This example demonstrates taking user input for environment and functions, with conditional stages: Build and Dev deployment run every time, SIT and UAT stages require approval and timeout.

```yaml
parameters:
- name: env
  displayName: 'Select Environment'
  type: string
  default: 'dev'
  values:
  - dev
  - sit
  - uat
- name: functions
  displayName: 'Select Functions to Execute'
  type: string
  default: 'a'
  values:
  - a
  - b
  - c
  - d

environments:
- name: dev
  resourceType: virtualMachine
  tags: dev
- name: sit
  resourceType: virtualMachine
  tags: sit
  # Configure approval and timeout in environment settings
- name: uat
  resourceType: virtualMachine
  tags: uat
  # Configure approval and timeout in environment settings

stages:
- stage: Build
  jobs:
  - job: BuildJob
    timeoutInMinutes: 30  # Timeout if build takes too long
    steps:
    - script: echo "Building for ${{ parameters.env }}"

- stage: DeployDev
  condition: eq('${{ parameters.env }}', 'dev')
  jobs:
  - deployment: DeployDevJob
    environment: dev
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Deploying to dev"

- stage: DeploySIT
  condition: eq('${{ parameters.env }}', 'sit')
  jobs:
  - deployment: DeploySITJob
    environment: sit
    timeoutInMinutes: 120  # Timeout for SIT deployment
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Waiting for approval and deploying to SIT"
    # Approval configured in environment

- stage: DeployUAT
  condition: eq('${{ parameters.env }}', 'uat')
  jobs:
  - deployment: DeployUATJob
    environment: uat
    timeoutInMinutes: 120  # Timeout for UAT deployment
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Waiting for approval and deploying to UAT"
    # Approval configured in environment

- stage: ExecuteFunctions
  dependsOn: [DeployDev, DeploySIT, DeployUAT]
  condition: |
    or(
      eq(dependencies.DeployDev.result, 'Succeeded'),
      eq(dependencies.DeploySIT.result, 'Succeeded'),
      eq(dependencies.DeployUAT.result, 'Succeeded')
    )
  jobs:
  - job: ExecuteJob
    timeoutInMinutes: 60  # Timeout if execution takes too long
    steps:
    - script: |
        case "${{ parameters.functions }}" in
          a)
            echo "Executing function A"
            # Add function A logic here
            ;;
          b)
            echo "Executing function B"
            # Add function B logic here
            ;;
          c)
            echo "Executing function C"
            # Add function C logic here
            ;;
          d)
            echo "Executing function D"
            # Add function D logic here
            ;;
        esac
```

### 5.6 Modular Pipelines

Modular pipelines use templates to break down complex pipelines into manageable components.

**Example: Multi-Stage Modular Pipeline**

```yaml
# Main pipeline
trigger:
- main

stages:
- template: templates/ci.yml  # Build and test
- template: templates/security-scan.yml  # Security checks
- template: templates/deploy.yml  # Deployment stages
  parameters:
    environments: ['dev', 'staging', 'prod']
```

**ci.yml Template**

```yaml
stages:
- stage: CI
  jobs:
  - job: Build
    steps:
    - script: mvn clean compile
  - job: Test
    dependsOn: Build
    steps:
    - script: mvn test
```

### 5.7 Loops and Conditions

Use loops for repetitive tasks and conditions for conditional execution.

**Each Loop Example**

```yaml
parameters:
- name: environments
  type: object
  default:
  - name: dev
    vmImage: 'ubuntu-latest'
  - name: prod
    vmImage: 'windows-latest'

stages:
- ${{ each env in parameters.environments }}:
  - stage: Build_${{ env.name }}
    jobs:
    - job: Build
      pool:
        vmImage: ${{ env.vmImage }}
      steps:
      - script: echo "Building on ${{ env.vmImage }} for ${{ env.name }}"
```

**Conditions Example**

```yaml
stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - script: echo "Always runs"

- stage: Test
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - job: TestJob
    steps:
    - script: echo "Runs only on main branch"

- stage: Deploy
  condition: |
    and(
      succeeded(),
      or(
        eq(variables['Build.SourceBranch'], 'refs/heads/main'),
        startsWith(variables['Build.SourceBranch'], 'refs/tags/')
      )
    )
  jobs:
  - deployment: DeployJob
    environment: production
    strategy:
      runOnce:
        deploy:
          steps:
          - script: echo "Conditional deployment"
```

### 5.8 Multiple Environments and Deployments

Define multiple environments for staged deployments with approvals.

**Multi-Environment Deployment Example**

```yaml
environments:
- name: dev
  resourceType: virtualMachine
  tags: dev
- name: staging
  resourceType: virtualMachine
  tags: staging
- name: prod
  resourceType: virtualMachine
  tags: prod

stages:
- stage: Build
  jobs:
  - job: BuildJob
    steps:
    - script: mvn clean package
    - publish: $(System.DefaultWorkingDirectory)/target/*.jar
      artifact: drop

- stage: DeployDev
  dependsOn: Build
  jobs:
  - deployment: DeployDev
    environment: dev
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: drop
          - script: echo "Deploy to dev"

- stage: DeployStaging
  dependsOn: DeployDev
  condition: succeeded()
  jobs:
  - deployment: DeployStaging
    environment: staging
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: drop
          - script: echo "Deploy to staging"

- stage: DeployProd
  dependsOn: DeployStaging
  condition: succeeded()
  jobs:
  - deployment: DeployProd
    environment: prod
    strategy:
      runOnce:
        deploy:
          steps:
          - download: current
            artifact: drop
          - script: echo "Deploy to prod"
```

---

# 6. Boards (Agile Planning)

* Work items: Epics → Features → User Stories → Tasks → Bugs
* Backlogs: Plan work hierarchically
* Sprints: Iteration planning
* Kanban boards: Drag-and-drop workflow

**CLI example**

```bash
az boards work-item create --title "Fix login bug" --type Bug --assigned-to user@contoso.com
```

---

# 7. Artifacts (Packages)

* Supports Maven, npm, NuGet, Python, Universal Packages

**Create feed**

```bash
az artifacts universal publish --feed MyFeed --package-name mypkg --package-version 1.0.0 --path ./mypkg
```

**Install package**

```bash
pip install --index-url https://pkgs.dev.azure.com/MyOrg/_packaging/MyFeed/pypi/simple/ mypkg
```

---

# 8. Test Plans

* Manual testing workflows
* Exploratory testing
* Automated test integration

**CLI example**

```bash
az test plan create --name MyTestPlan --project MyProject
```

---

# 9. Security & Permissions

* Use Azure AD for SSO
* RBAC: Reader, Contributor, Project Admin
* Limit PAT (Personal Access Token) scopes
* Secure pipelines with approvals & gates

---

# 10. Service Connections & Integrations

* Connect to: GitHub, Docker Hub, Kubernetes, AWS, GCP

**Example: Docker Service Connection**

```bash
az devops service-endpoint create --service-endpoint-configuration docker.json
```

---

# 11. CLI & REST API

**CLI examples**

```bash
az pipelines run --name MyPipeline
az boards query --wiql "SELECT [System.Id], [System.Title] FROM WorkItems"
```

**REST API**

```bash
GET https://dev.azure.com/{organization}/{project}/_apis/build/builds?api-version=7.1-preview.7
```

---

# 12. Monitoring & Logs

* Build logs available per pipeline run
* Export logs with CLI:

```bash
az pipelines runs artifact download --run-id 100 --artifact-name logs --path ./logs
```

* Integrate with Application Insights, Log Analytics

---

# 13. Best Practices & Tips

* Store pipelines as code in `azure-pipelines.yml`
* Use variable groups for secrets
* Leverage environments with approvals
* Keep builds fast & incremental
* Use caching for dependencies
* Rotate PATs and credentials
* Use branch policies + PR validation
* Implement reusable templates for common pipeline components
* Use parameters for runtime configuration and flexibility
* Design modular pipelines to improve maintainability
* Apply conditions and loops for dynamic pipeline execution
* Define multiple environments for staged deployments with gates
* Use matrix builds for cross-platform testing

---

# Quick Reference: One-liners

* Create pipeline:

```bash
az pipelines create --name CI --yml-path azure-pipelines.yml
```

* Run pipeline:

```bash
az pipelines run --name CI
```

* List repos:

```bash
az repos list --output table
```

* Create bug work item:

```bash
az boards work-item create --title "Bug: Fix crash" --type Bug
```

---

*End of cheat sheet — happy DevOps with Azure DevOps!*
