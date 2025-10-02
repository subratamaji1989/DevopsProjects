# Azure DevOps Cheat Sheet (Beginner → Expert)

> Covers setup, projects, repos, pipelines, boards, artifacts, security, CLI, and best practices.

---

## Table of Contents

1. Introduction & Setup
2. Azure DevOps Projects
3. Repos (Git)
4. Pipelines (CI/CD)
5. Pipeline Syntax Examples (YAML)
6. Boards (Agile Planning)
7. Artifacts (Packages)
8. Test Plans
9. Security & Permissions
10. Service Connections & Integrations
11. CLI & REST API
12. Monitoring & Logs
13. Best Practices & Tips

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
