# SonarQube Cheat Sheet (Beginner → Expert)

> Covers installation, configuration, analysis basics, quality gates, integration with CI/CD, security, and best practices.

---

## Table of Contents

1. Introduction & Setup
2. Installation & Configuration
3. SonarQube UI Basics
4. Projects & Sources
5. Analyzers & Supported Languages
6. Quality Profiles & Quality Gates
7. Running Analysis (CLI, Maven, Gradle, Jenkins, Azure DevOps)
8. Integrating with CI/CD
9. SonarQube Scanner Examples
10. Security & Authentication
11. Administration & Plugins
12. Monitoring & Logs
13. Best Practices & Tips

---

# 1. Introduction & Setup

**What is SonarQube?**

* Open-source platform for code quality & security.
* Supports 20+ languages, quality gates, CI/CD integration.

**Key Features**

* Code smells, bugs, vulnerabilities, duplications.
* Quality gates: pass/fail rules.
* Integrations: Jenkins, Azure DevOps, GitHub Actions.

---

# 2. Installation & Configuration

**Docker (quick setup)**

```bash
docker run -d --name sonarqube -p 9000:9000 sonarqube:latest
```

**Login**

* Default: `admin` / `admin`

**Change password:**

* Immediately update after first login.

---

# 3. SonarQube UI Basics

* **Projects** → Code analysis results
* **Issues** → Bugs, vulnerabilities, code smells
* **Quality Gates** → Enforce thresholds
* **Quality Profiles** → Rules per language
* **Administration** → Global/project settings

---

# 4. Projects & Sources

**Create new project**

1. Login → Projects → Create Project
2. Generate token
3. Configure scanner with token

**Tokens (CLI auth)**

```bash
export SONAR_TOKEN=<your_token>
```

---

# 5. Analyzers & Supported Languages

* Java, C#, JavaScript, Python, Go, PHP, C/C++, etc.
* Rules grouped into Quality Profiles.
* Extend with plugins.

---

# 6. Quality Profiles & Quality Gates

**Quality Profiles**

* Define coding rules per language.
* Can inherit from built-in profiles.

**Quality Gates**

* Example rules:

  * Coverage > 80%
  * Duplications < 3%
  * No blocker/critical issues

**Set default gate** → Admin → Quality Gates → Set as Default.

---

# 7. Running Analysis

**Sonar Scanner CLI**

```bash
sonar-scanner \
  -Dsonar.projectKey=myProject \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=$SONAR_TOKEN
```

**Maven**

```bash
mvn sonar:sonar \
  -Dsonar.projectKey=myProject \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=$SONAR_TOKEN
```

**Gradle**

```bash
gradle sonarqube \
  -Dsonar.projectKey=myProject \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=$SONAR_TOKEN
```

---

# 8. Integrating with CI/CD

**Jenkins Pipeline Example**

```groovy
stage('SonarQube Analysis') {
  steps {
    withSonarQubeEnv('MySonarQube') {
      sh 'mvn sonar:sonar'
    }
  }
}
```

**Azure DevOps Example (YAML)**

```yaml
- task: SonarQubePrepare@5
  inputs:
    SonarQube: 'MySonarQube'
    scannerMode: 'Other'
    configMode: 'manual'
    cliProjectKey: 'myProject'

- task: SonarQubeAnalyze@5

- task: SonarQubePublish@5
  inputs:
    pollingTimeoutSec: '300'
```

---

# 9. SonarQube Scanner Examples

**Basic CLI**

```bash
sonar-scanner -Dsonar.projectKey=myApp -Dsonar.sources=src
```

**Custom properties file** (`sonar-project.properties`)

```properties
sonar.projectKey=myApp
sonar.projectName=My Application
sonar.sources=src
sonar.language=java
sonar.java.binaries=target/classes
```

---

# 10. Security & Authentication

* Default admin/admin → change immediately.
* Use tokens instead of passwords.
* Integrate with LDAP, SAML, or Azure AD.
* Enforce project-level permissions.

---

# 11. Administration & Plugins

* Plugins extend analysis capabilities.
* Install via *Administration → Marketplace*.
* Examples: SonarCFamily, SonarJS, SonarPython.

---

# 12. Monitoring & Logs

**Logs (Docker)**

```bash
docker logs sonarqube
```

**Default log files (Linux)**

```
/opt/sonarqube/logs/sonar.log
/opt/sonarqube/logs/es.log
/opt/sonarqube/logs/web.log
/opt/sonarqube/logs/ce.log
```

**System health**: Administration → System → Health

---

# 13. Best Practices & Tips

* Always use tokens for authentication
* Apply strict quality gates (coverage, duplication)
* Use project-specific Quality Profiles
* Automate scanning in CI/CD
* Regularly update SonarQube & plugins
* Monitor performance (heap size, DB tuning)
* Backup DB & configuration

---

# Quick Reference: One-liners

* Run analysis:

```bash
sonar-scanner -Dsonar.projectKey=myApp -Dsonar.sources=.
```

* Maven analysis:

```bash
mvn sonar:sonar
```

* Show logs (Docker):

```bash
docker logs sonarqube -f
```

---

*End of cheat sheet — improve code quality with SonarQube!*
