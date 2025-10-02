# Jenkins Cheat Sheet (Beginner → Expert)

> Covers Jenkins setup, pipeline basics, declarative pipelines, freestyle jobs, plugins, security, scaling, and best practices.

---

## Table of Contents

1. Introduction & Setup
2. Jenkins UI & Basics
3. Freestyle Jobs
4. Pipelines (Scripted & Declarative)
5. Pipeline Syntax Examples
6. Plugins
7. Credentials Management
8. Distributed Builds (Master/Agent)
9. Jenkinsfile Best Practices
10. Security & Hardening
11. Monitoring & Logs
12. Advanced Usage & Tips
13. Useful CLI Commands

---

# 1. Introduction & Setup

**What is Jenkins?**

* Open-source automation server for CI/CD.
* Supports pipelines, plugins, and integrations.

**Installation (Linux)**

```bash
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update && sudo apt install jenkins -y
```

**Start service**

```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

---

# 2. Jenkins UI & Basics

* Dashboard → Manage Jenkins → Plugins/Nodes/Credentials
* Job Types: Freestyle, Pipeline, Multibranch, Folder
* Build Triggers: SCM Polling, Webhooks, Timers (cron)

---

# 3. Freestyle Jobs

**Steps:**

1. New Item → Freestyle Project
2. Source Code Management → Git
3. Build Steps → Shell / Windows Batch
4. Post-build actions → Archive, Deploy, Notify

**Example build step:**

```bash
echo "Building project..."
mvn clean install
```

---

# 4. Pipelines (Scripted & Declarative)

**Declarative (preferred)**

```groovy
pipeline {
  agent any
  stages {
    stage('Build') {
      steps {
        echo 'Building...'
        sh 'mvn clean install'
      }
    }
    stage('Test') {
      steps {
        sh 'mvn test'
      }
    }
    stage('Deploy') {
      steps {
        echo 'Deploying...'
      }
    }
  }
}
```

**Scripted**

```groovy
node {
  stage('Build') {
    sh 'mvn clean install'
  }
  stage('Test') {
    sh 'mvn test'
  }
}
```

---

# 5. Pipeline Syntax Examples

**Parallel stages**

```groovy
stage('Tests') {
  parallel {
    stage('Unit Tests') { steps { sh 'mvn test' } }
    stage('Integration Tests') { steps { sh './run_integration.sh' } }
  }
}
```

**Post actions**

```groovy
post {
  always { echo 'Cleanup' }
  success { echo 'Success!' }
  failure { echo 'Build failed' }
}
```

**Parameters**

```groovy
parameters {
  string(name: 'BRANCH', defaultValue: 'main')
  booleanParam(name: 'RUN_TESTS', defaultValue: true)
}
```

---

# 6. Plugins

* **SCM**: Git, GitHub, Bitbucket
* **Build tools**: Maven, Gradle, NodeJS
* **Notifications**: Slack, Email-ext
* **Pipeline**: Blue Ocean, Pipeline Utility Steps
* **Security**: Role Strategy Plugin

**Install plugin:** Manage Jenkins → Manage Plugins → Available

---

# 7. Credentials Management

* Store secrets under *Manage Jenkins → Credentials*
* Types: Username/Password, SSH Keys, Secret text, AWS Credentials

**Using credentials in pipeline**

```groovy
withCredentials([usernamePassword(credentialsId: 'mycreds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
  sh 'echo $USER && echo $PASS'
}
```

---

# 8. Distributed Builds (Master/Agent)

* **Master**: orchestrates builds
* **Agents**: run builds (Linux/Windows/Docker)

**Launch agent (SSH):**

```bash
java -jar agent.jar -jnlpUrl http://jenkins:8080/computer/my-agent/slave-agent.jnlp -secret <secret>
```

---

# 9. Jenkinsfile Best Practices

* Always use **Declarative pipeline**
* Store `Jenkinsfile` in project repo
* Use shared libraries for reusable code
* Run builds inside Docker agents for consistency
* Fail fast, add retries where needed

---

# 10. Security & Hardening

* Enable Matrix-based security
* Use Role Strategy Plugin for RBAC
* Enforce HTTPS
* Rotate credentials & tokens
* Restrict anonymous access

---

# 11. Monitoring & Logs

**Logs location (Linux):**

```bash
/var/log/jenkins/jenkins.log
```

**CLI logs**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ list-jobs
```

**Plugins for monitoring:**

* Monitoring Plugin
* Prometheus Plugin

---

# 12. Advanced Usage & Tips

* **Blue Ocean**: modern UI for pipelines
* **Multibranch Pipelines**: auto-detect branches
* **Pipeline Libraries**: shared Groovy code
* **Docker agents**: run isolated builds
* **Jenkins X**: cloud-native Jenkins on Kubernetes

---

# 13. Useful CLI Commands

**Connect to Jenkins**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ -auth user:token help
```

**List jobs**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ list-jobs
```

**Build a job**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ build myJob
```

**Get build log**

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ console myJob 15
```

---

# Quick Reference: One-liners

* Restart Jenkins (safe):

```bash
sudo systemctl restart jenkins
```

* List plugins:

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ list-plugins
```

* Backup config:

```bash
tar -czvf jenkins_backup.tar.gz /var/lib/jenkins
```

* Reload config without restart:

```bash
java -jar jenkins-cli.jar -s http://localhost:8080/ reload-configuration
```
---

*End of cheat sheet — happy aut
