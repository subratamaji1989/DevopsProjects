# BAU Automation Scripts for DevSecOps Lead and SRE

Here are 10 useful Business As Usual (BAU) automation scripts for each language (Shell, PowerShell, and Python), tailored for a DevSecOps Lead and SRE role, focusing on tasks like security checks, infrastructure health, deployment preparation, and logging/monitoring.


---

## Shell Scripts (Bash/Zsh)
These are ideal for quick system-level tasks, CI/CD pipeline steps, and Linux environment maintenance.

<details>
<summary>1. System Health Check and Reporting</summary>

```bash
#!/bin/bash
# Check CPU, memory, disk usage, and report if any exceed a threshold (e.g., 80%)
THRESHOLD=80
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
DISK_USAGE=$(df / | grep / | awk '{ print $5 }' | sed 's/%//g')

echo "CPU Usage: $CPU_USAGE%"
echo "Memory Usage: $MEM_USAGE%"
echo "Disk Usage: $DISK_USAGE%"

if (( $(echo "$CPU_USAGE > $THRESHOLD" | bc -l) || $(echo "$MEM_USAGE > $THRESHOLD" | bc -l) || $(echo "$DISK_USAGE > $THRESHOLD" | bc -l) )); then
  echo "ALERT: One or more resources are above the $THRESHOLD% threshold." | mail -s "System Health Alert" sre-team@example.com
fi
```
</details>

<details>
<summary>2. Log Rotation and Archival (Enhanced)</summary>

```bash
#!/bin/bash
# Compresses logs older than 7 days and deletes logs older than 30 days
LOG_DIR="/var/log/app_logs"
find "$LOG_DIR" -type f -mtime +7 ! -name "*.gz" -exec gzip {} \;
find "$LOG_DIR" -type f -mtime +30 -name "*.gz" -exec rm {} \;
```
</details>

<details>
<summary>3. Find Files with World-Writable Permissions (Security Audit)</summary>

```bash
#!/bin/bash
# Identifies and logs files/directories with potentially insecure world-writable permissions
echo "Files with world-writable permissions (potential security risk):"
find / -type f -perm -o=w 2>/dev/null
echo "Directories with world-writable permissions (potential security risk):"
find / -type d -perm -o=w 2>/dev/null
```
</details>

<details>
<summary>4. Stale Docker Image Cleanup</summary>

```bash
#!/bin/bash
# Removes all dangling Docker images (images not associated with a container)
echo "Cleaning up dangling Docker images..."
docker image prune -f
```
</details>

<details>
<summary>5. Service Restart on Failure (Basic Self-Healing)</summary>

```bash
#!/bin/bash
# Checks if a specific service is running and attempts to restart it if it's inactive
SERVICE_NAME="app_service"
if ! systemctl is-active --quiet $SERVICE_NAME; then
  echo "$SERVICE_NAME is down. Attempting restart..."
  systemctl restart $SERVICE_NAME
  if systemctl is-active --quiet $SERVICE_NAME; then
    echo "$SERVICE_NAME restarted successfully."
  else
    echo "ERROR: Failed to restart $SERVICE_NAME." | mail -s "Service Failure Alert" oncall@example.com
  fi
fi
```
</details>

<details>
<summary>6. Backup Database and Upload to Remote Storage (Simple)</summary>

```bash
#!/bin/bash
# Dumps a database, compresses it, and securely transfers it
DB_NAME="production_db"
BACKUP_FILE="/tmp/$DB_NAME-$(date +%Y%m%d%H%M%S).sql.gz"

mysqldump -u backup_user -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_FILE"

# Example for secure copy (SCP)
scp "$BACKUP_FILE" backup_user@remote-storage.example.com:/backups/
rm "$BACKUP_FILE"
```
</details>

<details>
<summary>7. Port Scan Check (Security Baseline)</summary>

```bash
#!/bin/bash
# Uses 'netstat' or 'ss' to list all listening ports and compares against an expected list
EXPECTED_PORTS=("22" "80" "443" "8080")
LISTENING_PORTS=$(ss -tuln | grep LISTEN | awk '{print $5}' | sed -E 's/.*:([0-9]+)/\1/' | sort -u)

for PORT in "${EXPECTED_PORTS[@]}"; do
  if ! echo "$LISTENING_PORTS" | grep -w $PORT; then
    echo "ALERT: Expected port $PORT is NOT listening."
  fi
done
```
</details>

<details>
<summary>8. Automated Dependency Vulnerability Scan Trigger (CI/CD)</summary>

```bash
#!/bin/bash
# A placeholder for triggering a security scan tool (e.g., Snyk, Trivy) on a code repository
SCAN_TOOL="trivy"
REPO_PATH="/path/to/app/repo"

echo "Starting dependency vulnerability scan with $SCAN_TOOL..."
"$SCAN_TOOL" fs "$REPO_PATH" --severity CRITICAL,HIGH > scan_report_$(date +%F).txt

if grep -q "Vulnerability ID" scan_report_$(date +%F).txt; then
  echo "Vulnerabilities found. Failing build."
  exit 1
fi
```
</details>

<details>
<summary>9. Clear Temporary/Cache Files</summary>

```bash
#!/bin/bash
# Cleans up files in common temporary directories older than a specified time
TEMP_DIRS=("/tmp" "/var/tmp" "/var/cache/apt/archives")
AGE_DAYS=7

for DIR in "${TEMP_DIRS[@]}"; do
  echo "Cleaning up $DIR (files older than $AGE_DAYS days)..."
  find "$DIR" -type f -mtime +"$AGE_DAYS" -exec rm -f {} \;
done
```
</details>

<details>
<summary>10. Automated User SSH Key Cleanup (Security)</summary>

```bash
#!/bin/bash
# Identifies and notifies/removes SSH keys for users inactive for a long period
INACTIVE_DAYS=90
for USER_HOME in /home/*; do
  USER=$(basename "$USER_HOME")
  LAST_LOGIN=$(last -w $USER | head -n 1 | awk '{print $4, $5, $6}')
  # Simplified check: if last login is older than $INACTIVE_DAYS, or user doesn't exist anymore
  # More robust logic needed for production, this is an example
  echo "Checking keys for user: $USER (Last Login: $LAST_LOGIN)"
  # [Further logic to check authorized_keys modification time and notify]
done
```
</details>

<details>
<summary>11. Log File Searcher</summary>

```bash

#!/bin/bash
# Script: log_searcher.sh
# Description: Reads a specified log file and searches for a specific error keyword.

# --- Configuration ---
LOG_FILE=$1
SEARCH_KEYWORD=$2

# --- Function to display help usage ---
display_usage() {
    echo "Usage: $0 <log_file> <search_keyword>"
    echo ""
    echo "  <log_file>      The full path to the log file to be read."
    echo "  <search_keyword> The keyword (e.g., ERROR, CRITICAL) to search for."
    echo ""
    exit 1
}

# --- Argument Check ---
if [ "$#" -ne 2 ]; then
    display_usage
fi

# --- File Existence and Readability Check ---
if [ ! -f "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' not found."
    exit 1
fi
if [ ! -r "$LOG_FILE" ]; then
    echo "Error: Log file '$LOG_FILE' is not readable."
    exit 1
fi

# --- Log Processing and Error Search ---
echo "--- Starting Log Analysis: $LOG_FILE ---"
echo "--- Searching for keyword: $SEARCH_KEYWORD ---"
echo ""

# Use 'grep' for efficiency to find lines containing the keyword
# Use 'while read' loop to print all lines, and search if required, but 'grep' is faster
# For printing line-by-line AND searching, a simple 'grep' is the most efficient BAU approach:

# Grep approach (most efficient):
grep --color=auto -n "$SEARCH_KEYWORD" "$LOG_FILE"

# If the requirement is strictly to *read line by line* and *then* search/print:
# while IFS= read -r line; do
#     echo "$line"
#     if [[ "$line" == *"$SEARCH_KEYWORD"* ]]; then
#         echo "  [FOUND: $SEARCH_KEYWORD]"
#     fi
# done < "$LOG_FILE"

if [ $? -eq 0 ]; then
    echo ""
    echo "--- Search complete. Errors found. ---"
else
    echo ""
    echo "--- Search complete. Keyword '$SEARCH_KEYWORD' not found. ---"
fi
```
</details>

---

## PowerShell Scripts
These are essential for managing Windows infrastructure, Active Directory, Azure/AWS resources (via their respective modules), and internal tool integration.

<details>
<summary>1. Windows Service Health Check and Auto-Recovery</summary>

```powershell
# Check if a critical service is running and start it if it's stopped
$ServiceName = "BITS" # Example: Background Intelligent Transfer Service
$Service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue

if ($Service -ne $null -and $Service.Status -ne "Running") {
    Write-Host "$ServiceName is $($Service.Status). Attempting to start..."
    Start-Service -Name $ServiceName
    Start-Sleep -Seconds 5
    $Service = Get-Service -Name $ServiceName
    if ($Service.Status -eq "Running") {
        Write-Host "$ServiceName started successfully."
    } else {
        Send-MailMessage -To "sre-team@example.com" -Subject "Service Failure Alert" -Body "$ServiceName failed to start." -SmtpServer "smtp.example.com"
    }
}
```
</details>

<details>
<summary>2. IIS Application Pool Recycle (Performance/Stability)</summary>

```powershell
# Recycle a specific IIS Application Pool for maintenance or stability
$AppPoolName = "ProductionWebPool"
Write-Host "Recycling Application Pool: $AppPoolName"

try {
    Import-Module WebAdministration -ErrorAction Stop
    Recycle-WebAppPool -Name $AppPoolName
    Write-Host "Successfully recycled $AppPoolName."
} catch {
    Write-Error "Failed to recycle $AppPoolName: $($_.Exception.Message)"
}
```
</details>

<details>
<summary>3. Find Open Shares with Excessive Permissions (Security)</summary>

```powershell
# Scans for file shares and reports on permissions that grant 'Everyone' full control
$ComputerName = "localhost" # Can be an array of server names
$Report = @()

Get-WmiObject -Class Win32_Share -ComputerName $ComputerName | ForEach-Object {
    $Share = $_
    $ACL = Get-Acl $Share.Path.Replace(":", "$") -ErrorAction SilentlyContinue

    if ($ACL -ne $null) {
        $ACL.Access | Where-Object { $_.IdentityReference -like "*Everyone*" -and $_.FileSystemRights -like "*FullControl*" } | ForEach-Object {
            $Report += [PSCustomObject]@{
                ShareName = $Share.Name
                Path      = $Share.Path
                Account   = $_.IdentityReference
                Rights    = $_.FileSystemRights
            }
        }
    }
}

if ($Report.Count -gt 0) {
    $Report | Format-Table
    # $Report | Export-Csv "Insecure_Shares_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
} else {
    Write-Host "No shares found with 'Everyone' Full Control."
}
```
</details>

<details>
<summary>4. Automated Security Patch Installation Check</summary>

```powershell
# Check the last time the server was updated and alert if it exceeds a timeframe
$DaysThreshold = 30
$LastUpdate = (Get-CimInstance -ClassName Win32_QuickFixEngineering | Sort-Object InstalledOn -Descending | Select-Object -First 1).InstalledOn

if ($LastUpdate -eq $null) {
    Write-Warning "Could not find any installed updates."
} elseif ((Get-Date) - $LastUpdate).TotalDays -gt $DaysThreshold) {
    Write-Warning "Last security update was $($LastUpdate.ToShortDateString()), which is more than $DaysThreshold days ago."
    # Send alert logic here
} else {
    Write-Host "Server is up to date. Last update: $($LastUpdate.ToShortDateString())."
}
```
</details>

<details>
<summary>5. Clean Up Old Windows Event Logs</summary>

```powershell
# Archives and clears event logs older than a specific date to free up space and maintain performance
$MaxAgeDays = 60
$CutoffDate = (Get-Date).AddDays(-$MaxAgeDays)

Get-WinEvent -ListLog * | ForEach-Object {
    $LogName = $_.LogName
    Write-Host "Processing log: $LogName"
    # Logic to archive the log before clearing can be added here

    # Clear the log if it's not a critical system log and is configured to be cleared
    # For this BAU example, we just clear to keep it simple and efficient.
    # Clear-EventLog -LogName $LogName -Force
}
```
</details>

<details>
<summary>6. Validate SSL Certificate Expiry (Web Server)</summary>

```powershell
# Checks the expiry date of a certificate on a remote web server
$Hostname = "secure-app.example.com"
$Port = 443
$ExpireThresholdDays = 30

$Socket = New-Object System.Net.Sockets.TcpClient($Hostname, $Port)
$Stream = New-Object System.Net.Security.SslStream($Socket.GetStream(), $false, $null, $null)
$Stream.AuthenticateAsClient($Hostname)
$Cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($Stream.RemoteCertificate)

$DaysUntilExpiry = ($Cert.NotAfter - (Get-Date)).TotalDays

Write-Host "Certificate for $Hostname expires on: $($Cert.NotAfter.ToShortDateString())"

if ($DaysUntilExpiry -lt $ExpireThresholdDays) {
    Write-Warning "ALERT: Certificate expires in $DaysUntilExpiry days!"
    # Alert mechanism here
}

$Stream.Close()
$Socket.Close()
```
</details>

<details>
<summary>7. Azure Resource Group/VM Cost Tag Check (DevSecOps/FinOps)</summary>

```powershell
# Uses the Azure module to check if all VMs/RGs have required cost/owner tags
# Requires: Install-Module -Name Az
$RequiredTag = "CostCenter"

Get-AzVM | ForEach-Object {
    if (-not $_.Tags.ContainsKey($RequiredTag)) {
        Write-Warning "VM $($_.Name) in Resource Group $($_.ResourceGroupName) is missing the '$RequiredTag' tag."
        # Logic to automatically apply a default tag or alert the owner
    }
}
```
</details>

<details>
<summary>8. Active Directory (AD) Inactive User Report</summary>

```powershell
# Reports on user accounts that haven't logged in for a specified period
# Requires: Import-Module ActiveDirectory
$Days = 90
$InactiveDate = (Get-Date).AddDays(-$Days)

Search-ADAccount -AccountInactive -TimeSpan (New-TimeSpan -Days $Days) -UsersOnly | 
    Select-Object Name, SamAccountName, LastLogonDate, Enabled |
    Export-Csv "Inactive_AD_Users_$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation

Write-Host "Report generated for users inactive since $($InactiveDate.ToShortDateString())."
```
</details>

<details>
<summary>9. Clear IE/Edge Browser Cache on VDI/Terminal Servers</summary>

```powershell
# Automated cleanup of browser caches to improve performance on shared environments
$CachePath = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
Write-Host "Cleaning up cache in $CachePath..."

# Example: Delete files older than 7 days
Get-ChildItem -Path $CachePath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -Recurse
```
</details>

<details>
<summary>10. Automated Rollback Check (Deployment Validation)</summary>

```powershell
# Checks the version of a deployed application or file after a deployment
# This acts as a post-deployment verification/validation step
$AppPath = "C:\inetpub\wwwroot\App\version.txt"
$ExpectedVersion = "2.5.0"

if (Test-Path $AppPath) {
    $CurrentVersion = Get-Content $AppPath
    if ($CurrentVersion -ne $ExpectedVersion) {
        Write-Warning "Deployment mismatch! Current version is $CurrentVersion, expected $ExpectedVersion."
        # Trigger rollback pipeline step or PagerDuty alert
    } else {
        Write-Host "Deployment validated. Version $CurrentVersion confirmed."
    }
} else {
    Write-Error "Application path not found: $AppPath"
}
```
</details>

---

## Python Scripts
Python is excellent for complex logic, API interactions (Monitoring, Cloud APIs, SIEM), data processing, and cross-platform automation.

<details>
<summary>1. Cloud Instance Health and Auto-Scaling Group (ASG) Validation</summary>

```python
# Uses Boto3 (AWS) or Azure SDK to check health and ensure ASG desired state matches running instances
import boto3
import logging

logging.basicConfig(level=logging.INFO)

def validate_asg_health(asg_name):
    client = boto3.client('autoscaling')
    response = client.describe_auto_scaling_groups(AutoScalingGroupNames=[asg_name])

    if not response['AutoScalingGroups']:
        logging.error(f"ASG '{asg_name}' not found.")
        return False

    asg = response['AutoScalingGroups'][0]
    desired_capacity = asg['DesiredCapacity']
    in_service_count = sum(1 for instance in asg['Instances'] if instance['LifecycleState'] == 'InService' and instance['HealthStatus'] == 'Healthy')

    if in_service_count < desired_capacity:
        logging.warning(f"ASG '{asg_name}' is degraded: {in_service_count}/{desired_capacity} instances healthy.")
        # Trigger PagerDuty/Slack notification
        return False

    logging.info(f"ASG '{asg_name}' is healthy: {in_service_count}/{desired_capacity} instances healthy.")
    return True

# validate_asg_health('ProductionWebAppASG')
```
</details>

<details>
<summary>2. API Endpoint Latency and Status Check</summary>

```python
# Monitors application API health and response time
import requests
import time

def check_api_health(url, timeout=5):
    start_time = time.time()
    try:
        response = requests.get(url, timeout=timeout)
        latency_ms = (time.time() - start_time) * 1000

        if response.status_code == 200:
            print(f"URL: {url} | Status: OK | Latency: {latency_ms:.2f}ms")
        else:
            print(f"URL: {url} | Status: ERROR {response.status_code}")
            # Alert for non-200 status

        if latency_ms > 500: # Latency threshold
            print(f"ALERT: High latency at {latency_ms:.2f}ms")
            # Alert for high latency

    except requests.exceptions.RequestException as e:
        print(f"URL: {url} | Connection Error: {e}")
        # Alert for connection failure

# check_api_health("https://api.example.com/v1/health")
```
</details>

<details>
<summary>3. Audit CI/CD Pipeline Configuration for Security Defaults</summary>

```python
# Checks CI/CD configuration files (e.g., .gitlab-ci.yml, Jenkinsfile) for security best practices
import os
import re

def audit_pipeline_config(file_path):
    security_violations = []
    with open(file_path, 'r') as f:
        content = f.read()

        # Check 1: Ensure 'docker:dind' is not used (prefer Kaniko/BuildKit)
        if re.search(r'image:\s*docker:dind', content, re.IGNORECASE):
            security_violations.append("Used 'docker:dind' - insecure due to root privileges.")

        # Check 2: Check for hardcoded credentials (simplified example)
        if re.search(r'password\s*=\s*"\w+"', content, re.IGNORECASE):
            security_violations.append("Potential hardcoded credentials found.")

    if security_violations:
        print(f"Security Audit FAILED for {file_path}:")
        for violation in security_violations:
            print(f" - {violation}")
    else:
        print(f"Security Audit PASSED for {file_path}.")

# audit_pipeline_config('path/to/.gitlab-ci.yml')
```
</details>

<details>
<summary>4. Log File Pattern Anomaly Detection (Simple)</summary>

```python
# Searches log files for specific high-severity error patterns (e.g., 'OOM', 'Stack Overflow')
import re

def check_log_anomalies(log_file):
    error_patterns = [
        r'Out\s+Of\s+Memory',
        r'Stack\s+Overflow',
        r'500\s+Internal\s+Server\s+Error'
    ]

    with open(log_file, 'r') as f:
        for line_num, line in enumerate(f, 1):
            for pattern in error_patterns:
                if re.search(pattern, line, re.IGNORECASE):
                    print(f"ALERT (Line {line_num}): Found high-severity pattern '{pattern}' in log.")
                    # Could trigger an incident in a SIEM/Monitoring system

# check_log_anomalies('/var/log/nginx/access.log')
```
</details>

<details>
<summary>5. GitHub/GitLab Repository Access Audit (DevSecOps)</summary>

```python
# Uses the Git API to list users/groups with 'Admin' or 'Write' access to critical repositories
import requests
import os

def audit_repo_access(org_name, repo_name):
    token = os.environ.get("GITHUB_TOKEN")
    headers = {"Authorization": f"token {token}"}
    url = f"https://api.github.com/repos/{org_name}/{repo_name}/collaborators"

    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        collaborators = response.json()
        print(f"Users with Write/Admin access for {repo_name}:")
        for user in collaborators:
            permission = user['permissions']
            if permission['admin'] or permission['push']:
                print(f" - {user['login']} (Admin: {permission['admin']}, Push: {permission['push']})")
    else:
        print(f"Error accessing repository: {response.status_code}")

# audit_repo_access('AcmeCorp', 'critical-app-repo')
```
</details>

<details>
<summary>6. Secret Management (HashiCorp Vault) Lease Renewal</summary>

```python
# Automates the renewal of short-lived database credentials or other secret leases
import hvac # HashiCorp Vault client
import os

def renew_vault_lease(lease_id):
    client = hvac.Client(url=os.environ.get("VAULT_ADDR"), token=os.environ.get("VAULT_TOKEN"))

    try:
        renewal_info = client.sys.renew_lease(lease_id=lease_id)
        print(f"Lease {lease_id} renewed successfully. New lease duration: {renewal_info['lease_duration']}s")
        return renewal_info
    except hvac.exceptions.InvalidRequest as e:
        print(f"Failed to renew lease {lease_id}: {e}")
        return None

# Example: renew_vault_lease('database/creds/myapp/12345678')
```
</details>

<details>
<summary>7. Configuration File Consistency Check (YAML/JSON)</summary>

```python
# Ensures all deployed instances of a service have the same critical configuration values
import yaml

def check_config_consistency(primary_config_path, secondary_config_path, keys_to_check):
    with open(primary_config_path, 'r') as f:
        primary_config = yaml.safe_load(f)
    with open(secondary_config_path, 'r') as f:
        secondary_config = yaml.safe_load(f)

    is_consistent = True
    for key in keys_to_check:
        primary_value = primary_config.get(key)
        secondary_value = secondary_config.get(key)

        if primary_value != secondary_value:
            print(f"MISMATCH for key '{key}': Primary={primary_value}, Secondary={secondary_value}")
            is_consistent = False

    if is_consistent:
        print("Critical configuration keys are consistent.")

# check_config_consistency('config_prod.yaml', 'config_stage.yaml', ['db_host', 'log_level', 'feature_flag'])
```
</details>

<details>
<summary>8. Automated Data Cleanup (e.g., Old Database Records)</summary>

```python
# Connects to a database and purges records older than a specific date for GDPR/performance
import psycopg2
from datetime import datetime, timedelta

def clean_old_records(db_conn_string, table_name, date_column, days_to_keep=365):
    cutoff_date = (datetime.now() - timedelta(days=days_to_keep)).strftime('%Y-%m-%d %H:%M:%S')
    sql_query = f"DELETE FROM {table_name} WHERE {date_column} < '{cutoff_date}';"

    try:
        conn = psycopg2.connect(db_conn_string)
        cursor = conn.cursor()
        cursor.execute(sql_query)
        deleted_count = cursor.rowcount
        conn.commit()
        cursor.close()
        conn.close()
        print(f"Successfully deleted {deleted_count} records from {table_name} older than {cutoff_date}.")
    except Exception as e:
        print(f"Database cleanup failed: {e}")

# clean_old_records("dbname=mydb user=myuser password=mypass host=127.0.0.1", "log_events", "created_at", 180)
```
</details>

<details>
<summary>9. Terraform State/Configuration Drift Detection</summary>

```python
# Compares the Terraform state file with the current cloud infrastructure (using 'terraform plan')
import subprocess
import json

def check_terraform_drift(terraform_dir):
    try:
        # Run terraform plan and output in JSON format
        result = subprocess.run(
            ['terraform', 'plan', '-no-color', '-detailed-exitcode', '-input=false', '-json'],
            cwd=terraform_dir,
            capture_output=True, text=True, check=True
        )

        # detailed-exitcode: 0=no changes, 1=error, 2=changes/drift
        if result.returncode == 0:
            print("Terraform check: No drift detected.")
        elif result.returncode == 2:
            print("ALERT: Terraform drift detected (exit code 2). Plan output shows changes.")
            # Parse JSON output for detailed changes (Requires more complex parsing)

    except subprocess.CalledProcessError as e:
        print(f"ERROR running terraform plan (Exit Code {e.returncode}):\n{e.stderr}")
        print("Configuration error or failure. Investigate immediately.")

# check_terraform_drift('./infra/prod_env')
```
</details>

<details>
<summary>10. Slack/Teams Notification on Metric Threshold Breach</summary>

```python
# Sends a structured message to a communication platform when a monitored metric (from a source like Prometheus/New Relic) crosses a threshold
import requests
import json
from datetime import datetime

def send_slack_alert(webhook_url, metric_name, value, threshold):
    payload = {
        "text": f":fire: ALERT: {metric_name} Breach!",
        "blocks": [
            {"type": "section", "text": {"type": "mrkdwn", "text": f"*Metric:* {metric_name}"}},
            {"type": "section", "text": {"type": "mrkdwn", "text": f"*Value:* `{value}` (Threshold: `{threshold}`)"}},
            {"type": "context", "elements": [{"type": "mrkdwn", "text": f"Time: {datetime.now().isoformat()}"}]}
        ]
    }

    response = requests.post(webhook_url, data=json.dumps(payload), headers={'Content-Type': 'application/json'})

    if response.status_code == 200:
        print("Slack notification sent successfully.")
    else:
        print(f"Failed to send Slack notification: {response.text}")

# import os
# webhook_url = os.environ.get("SLACK_WEBHOOK")
# send_slack_alert(webhook_url, "DB Connection Pool Usage", 95, 80)
```
</details>