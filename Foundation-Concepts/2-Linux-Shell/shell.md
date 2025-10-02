# 🚀 Essential Linux Commands for DevOps Engineers and SRE

This guide provides the fundamental commands DevOps engineers and SRE use daily for monitoring, diagnostics, and system management, formatted for quick reference.

## **1. System Health and Resource Monitoring**

- **Check CPU and Memory usage in real-time.**
```bash
top
# or the more interactive, feature-rich version
htop
```

- **Report on virtual memory, I/O, and CPU statistics (quick snapshot).**

```bash
vmstat 1 5  # Report every 1 second, 5 times
```

- **Report CPU and Disk I/O statistics.**

```bash
iostat -x 1 5  # Extended statistics, 1 second intervals, 5 reports
```

- **Check available disk space (Human-readable).**

```bash
df -h
```

- **Summarize disk usage for the current directory (find large folders).**

```bash
du -sh *
```

- **View detailed information about the system's hardware and kernel.**

```bash
uname -a
```

## **2. Networking and Connectivity**

- **Test basic network connectivity and latency.**

```bash
ping google.com
```

- **Display the network path to a host (identify bottlenecks).**

```bash
traceroute google.com
```

- **Display open ports and the processes using them (legacy but common).**

```bash
netstat -tunlp
```

- **Quickly check listening sockets (modern, faster alternative to netstat).**

```bash
ss -tuln
```

- **Test an API endpoint or website availability (get response headers).**

```bash
curl -I https://api.example.com/health
```

- **Download a file non-interactively in a script.**

```bash
wget https://example.com/file.zip
```

- **Inspect routing tables and network interface configuration.**

```bash
ip addr show
ip route show
```

## **3. Text Processing and Log Inspection**
- **Search log files for a specific error pattern.**

```bash
grep "ERROR" /var/log/app.log
```

- **Display log file content and follow new entries in real-time.**

```bash
tail -f /var/log/app.log
```

- **View large files without loading them fully into memory.**

```bash
less /var/log/huge_file.log
```

- **Extract a specific column (e.g., the 5th column) from a data stream using AWK.**

```bash
cat data.txt | awk '{print $5}'
```

- **Perform an in-place find and replace operation on a configuration file using SED.**

```bash
sed -i 's/OLD_VALUE/NEW_VALUE/g' config.conf
```

- **Count the number of lines, words, and bytes in a file.**

```bash
wc -l file.txt
```

- **Sort the lines of text files.**

```bash
sort unsorted_list.txt
```

## **4. Process and Service Management**
- **Get a snapshot of all running processes.**

```bash
ps aux
```

- **Stop a process gracefully using its Process ID (PID).**

```bash
kill 12345
# Forcefully stop (use only if necessary)
kill -9 12345
```

- **Start, stop, or check the status of a systemd service.**

```bash
sudo systemctl status nginx
sudo systemctl restart myapp
```

- **Run a command in the background, immune to terminal hang-ups.**

```bash
nohup long_running_script.sh &
```

- **Show the hierarchical process tree (useful for debugging parent/child processes).**

```bash
pstree -p
```

- **List all open files and the processes that opened them (powerful diagnostic).**

```bash
lsof -i :8080  # Show processes listening on port 8080
```

## **5. Containerization and Orchestration (Kubernetes/Docker)**

- **List currently running Docker containers.**

```bash
docker ps
```

- **Fetch and stream logs from a specific Docker container.**

```bash
docker logs -f my_container_name
```

- **List all pods in the current Kubernetes namespace.**

```bash
kubectl get pods
```

- **View detailed status and events for a Kubernetes resource (e.g., a pod).**

```bash
kubectl describe pod my-app-pod-xyz
```

- **Stream logs from a Kubernetes pod.**

```bash
kubectl logs -f my-app-pod-xyz
```

- **Execute a command inside a running Kubernetes container.**

```bash
kubectl exec -it my-app-pod-xyz -- bash
```

## **6. Security, File Management, and Package Control**

- **Execute a command with superuser privileges.**

```bash
sudo systemctl start database
```

- **Change the permissions (mode) of a file (e.g., make a script executable).**

```bash
chmod +x setup.sh
# Set private key permissions (Read/Write for Owner only)
chmod 600 id_rsa
```

- **Change the owner and group of a file or directory.**

```bash
sudo chown -R www-data:www-data /var/www/html
```

- **Recursively synchronize files and directories to a remote host (efficient copying).**

```bash
rsync -avz /local/path/ user@remote:/remote/path/
```

- **Search for and install packages (Debian/Ubuntu).**

```bash
sudo apt update
sudo apt install package_name
```

- **Search for and install packages (CentOS/RHEL).**

```bash
sudo yum check-update
sudo yum install package_name
```

## **7. Version Control (Git)**

- **Check the status of files in the working directory and staging area.**

```bash
git status
```

- **Fetch changes from the remote and merge them into the current branch.**

```bash
git pull
```

- **Switch to a different branch or create a new one.**

```bash
git checkout develop
git checkout -b feature/new-feature
```

- **View commit history in different formats.**

```bash
git log --oneline
git log --pretty=format:"%h - %an, %ar : %s"
git log --stat
```

- **Delete your feature branch locally and remotely.**

```bash
git branch -d feature/your-feature-name
git push origin --delete feature/your-feature-name
```
