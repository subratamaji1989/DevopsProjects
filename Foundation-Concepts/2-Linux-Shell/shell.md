# 🚀 Essential Linux Commands for DevOps Engineers and SRE

This guide provides the fundamental commands DevOps engineers and SRE use daily for monitoring, diagnostics, and system management, formatted for quick reference.

## Table of Contents
- [1. System Health and Resource Monitoring](#1-system-health-and-resource-monitoring)
- [2. Networking and Connectivity](#2-networking-and-connectivity)
- [3. Text Processing and Log Inspection](#3-text-processing-and-log-inspection)
- [4. Process and Service Management](#4-process-and-service-management)
- [5. Containerization and Orchestration (Kubernetes/Docker)](#5-containerization-and-orchestration-kubernetesdocker)
- [6. Security, File Management, and Package Control](#6-security-file-management-and-package-control)
- [7. Version Control (Git)](#7-version-control-git)
- [8. File System Navigation](#8-file-system-navigation)
- [9. User Management](#9-user-management)
- [10. Backup and Compression](#10-backup-and-compression)
- [11. Scripting Basics](#11-scripting-basics)
- [Troubleshooting Common Issues](#troubleshooting-common-issues)
- [Best Practices](#best-practices)

## 1. System Health and Resource Monitoring

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

## 2. Networking and Connectivity

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

## 3. Text Processing and Log Inspection
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

## 4. Process and Service Management
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

Process Tree Example:
```
init(1)─┬─systemd(1)─┬─sshd(1234)─┬─sshd(5678)───bash(9012)
        │            │             └─sshd(3456)───bash(7890)
        │            ├─nginx(2468)─┬─nginx(1357)
        │            │             └─nginx(2469)
        │            └─docker(1111)─┬─containerd(2222)
        │                          └─dockerd(3333)
```

- **List all open files and the processes that opened them (powerful diagnostic).**

```bash
lsof -i :8080  # Show processes listening on port 8080
```

## 5. Containerization and Orchestration (Kubernetes/Docker)

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

## 6. Security, File Management, and Package Control

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

## 7. Version Control (Git)

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

## 8. File System Navigation

- **List directory contents (with details).**

```bash
ls -la
```

- **Change directory.**

```bash
cd /path/to/directory
cd ..  # Go up one level
cd ~   # Go to home directory
```

- **Print working directory.**

```bash
pwd
```

- **Create directories.**

```bash
mkdir new_directory
mkdir -p parent/child/grandchild  # Create nested directories
```

- **Remove files and directories.**

```bash
rm file.txt
rm -rf directory/  # Remove directory recursively
```

- **Copy files and directories.**

```bash
cp source.txt destination.txt
cp -r source_dir/ destination_dir/
```

- **Move or rename files and directories.**

```bash
mv old_name.txt new_name.txt
mv file.txt /new/path/
```

- **Find files by name.**

```bash
find /path -name "*.log"
```

## 9. User Management

- **Display current user information.**

```bash
whoami
id
```

- **Switch to another user.**

```bash
su - username
sudo -u username command
```

- **Add a new user.**

```bash
sudo useradd newuser
sudo passwd newuser
```

- **Delete a user.**

```bash
sudo userdel username
```

- **Change user password.**

```bash
passwd  # Change own password
sudo passwd username  # Change another user's password
```

- **List all users.**

```bash
cat /etc/passwd
```

## 10. Backup and Compression

- **Create a compressed tar archive.**

```bash
tar -czf archive.tar.gz /path/to/directory
```

- **Extract a tar archive.**

```bash
tar -xzf archive.tar.gz
```

- **Compress a file with gzip.**

```bash
gzip file.txt  # Creates file.txt.gz
```

- **Decompress a gzip file.**

```bash
gunzip file.txt.gz
```

- **Create a backup with rsync (incremental).**

```bash
rsync -av --delete /source/ /backup/
```

## 11. Scripting Basics

- **Create a simple bash script.**

```bash
#!/bin/bash
echo "Hello, World!"
```

- **Make script executable and run it.**

```bash
chmod +x script.sh
./script.sh
```

- **Use variables in scripts.**

```bash
#!/bin/bash
NAME="DevOps"
echo "Hello, $NAME!"
```

- **Conditional statements.**

```bash
if [ "$VAR" == "value" ]; then
    echo "Match"
else
    echo "No match"
fi
```

- **Loops.**

```bash
for i in {1..5}; do
    echo "Iteration $i"
done
```

- **Check exit status.**

```bash
command
if [ $? -eq 0 ]; then
    echo "Success"
else
    echo "Failed"
fi
```

## Troubleshooting Common Issues

- **Permission denied:** Use `sudo` or check file permissions with `ls -l`.
- **Command not found:** Ensure the package is installed or add to PATH.
- **Disk full:** Check with `df -h` and `du -sh *` to find large files.
- **Service not starting:** Check logs with `journalctl -u service_name`.
- **Network issues:** Use `ping`, `traceroute`, or `ss -tuln` to diagnose.
- **High CPU/Memory:** Monitor with `top` or `htop` and identify processes.

## Best Practices

- **Use absolute paths in scripts** to avoid dependency on current directory.
- **Always check exit codes** in scripts for error handling.
- **Use `sudo` sparingly** and understand what commands do.
- **Backup before making changes** to critical files.
- **Monitor logs regularly** for early issue detection.
- **Automate repetitive tasks** with scripts.
- **Keep systems updated** with package managers.
- **Use version control** for configuration files and scripts.
