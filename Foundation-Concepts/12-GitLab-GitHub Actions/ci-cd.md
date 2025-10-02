# GitLab CI/CD & GitHub Actions Cheat Sheet (Beginner → Expert)

> Covers setup, pipelines, YAML syntax, runners, jobs, artifacts, caching, CI/CD best practices, secrets management, and monitoring.

---

## Table of Contents

1. Introduction & Setup
2. GitLab CI/CD Basics
3. GitHub Actions Basics
4. YAML Pipelines Syntax
5. Jobs, Stages, and Runners
6. Artifacts & Caching
7. Environment & Secrets Management
8. Parallelism & Matrix Builds
9. Triggers & Schedules
10. Integration with Docker
11. Notifications & Reports
12. CI/CD Best Practices
13. Monitoring & Debugging

---

# 1. Introduction & Setup

**GitLab CI/CD**

* Integrated with GitLab repositories.
* Requires `.gitlab-ci.yml` in the repo root.
* Runners execute jobs (shared or specific).

**GitHub Actions**

* Integrated with GitHub repositories.
* Requires `.github/workflows/<workflow>.yml`.
* Actions run on GitHub-hosted runners or self-hosted.

---

# 2. GitLab CI/CD Basics

**Define pipeline**

```yaml
stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  script:
    - echo "Building..."
```

**Run pipeline manually or on push**

* Triggers: `only`, `except`, `rules`

**View pipeline:** GitLab → CI/CD → Pipelines

---

# 3. GitHub Actions Basics

**Define workflow**

```yaml
name: CI
on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node
        uses: actions/setup-node@v3
        with:
          node-version: '16'
      - run: npm install
      - run: npm test
```

**View workflow:** GitHub → Actions → select workflow

---

# 4. YAML Pipelines Syntax

**GitLab**

* `stages` → define order of execution
* `jobs` → individual tasks
* `script` → commands
* `tags` → assign to specific runner

**GitHub**

* `jobs` → parallel by default
* `steps` → ordered execution
* `runs-on` → runner type
* `uses` → prebuilt actions
* `run` → shell commands

---

# 5. Jobs, Stages, and Runners

**GitLab**

* Job example:

```yaml
test_job:
  stage: test
  script:
    - npm test
  tags:
    - docker
  only:
    - main
```

**GitHub Actions**

* Job example:

```yaml
build:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - run: echo "Build step"
```

**Runners**

* GitLab: shared or custom runners
* GitHub: hosted or self-hosted runners

---

# 6. Artifacts & Caching

**GitLab Artifacts**

```yaml
artifacts:
  paths:
    - build/
  expire_in: 1 week
```

**GitHub Actions Artifacts**

```yaml
- name: Upload artifact
  uses: actions/upload-artifact@v3
  with:
    name: build-artifact
    path: build/
```

**Caching Dependencies**

* GitLab: `cache:`
* GitHub: `actions/cache@v3`

---

# 7. Environment & Secrets Management

**GitLab**

* Protect variables via Settings → CI/CD → Variables
* Mask sensitive info

**GitHub Actions**

* Repository Secrets: Settings → Secrets and variables → Actions
* Use `secrets.<NAME>` in workflow

---

# 8. Parallelism & Matrix Builds

**GitLab Matrix**

```yaml
test_job:
  stage: test
  script: npm test
  parallel:
    matrix:
      - NODE_VERSION: [14,16]
```

**GitHub Matrix**

```yaml
strategy:
  matrix:
    node: [14,16]
steps:
  - uses: actions/setup-node@v3
    with:
      node-version: ${{ matrix.node }}
```

---

# 9. Triggers & Schedules

**GitLab**

* Trigger pipelines via API, `only`, `except`, or schedules
* Schedule example:

```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

**GitHub Actions**

* Scheduled workflow:

```yaml
on:
  schedule:
    - cron: '0 0 * * *'
```

---

# 10. Integration with Docker

**GitLab**

```yaml
image: node:16
services:
  - docker:dind
before_script:
  - docker info
```

**GitHub Actions**

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: docker/setup-buildx-action@v3
      - run: docker build -t myapp .
```

---

# 11. Notifications & Reports

**GitLab**

* Email notifications, Slack integration
* Use `after_script` for alerts

**GitHub Actions**

* Use `actions/github-script` or third-party actions for notifications
* Integrate with Slack, Teams, or Email

---

# 12. CI/CD Best Practices

* Keep pipelines fast & incremental
* Use caching for dependencies
* Fail fast on errors
* Protect secrets & tokens
* Use separate jobs for build/test/deploy
* Reuse scripts via includes/templates (GitLab) or composite actions (GitHub)
* Run tests in parallel for efficiency

---

# 13. Monitoring & Debugging

**GitLab**

* View pipeline logs in CI/CD → Pipelines → Job Logs
* Retry failed jobs
* Use `debug` traces via `CI_DEBUG_TRACE`

**GitHub Actions**

* Check logs via Actions → Workflow → Job → Steps
* Enable `ACTIONS_STEP_DEBUG` secret for verbose logs
* Use `continue-on-error: true` for debugging specific steps

---

# Quick Reference: One-liners

* Trigger GitLab pipeline manually:

```bash
curl -X POST -F token=<TOKEN> -F ref=main https://gitlab.com/api/v4/projects/<ID>/trigger/pipeline
```

* Trigger GitHub Actions workflow manually:

```bash
gh workflow run ci.yml --ref main
```

* Upload artifact GitLab:

```yaml
artifacts:
  paths:
    - build/
```

* Upload artifact GitHub:

```yaml
- uses: actions/upload-artifact@v3
  with:
    name: build
    path: build/
```

---

*End of cheat sheet — efficient CI/CD with GitLab & GitHub Actions!*
