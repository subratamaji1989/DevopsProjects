# Ansible Cheat Sheet (Beginner → Expert)

> A practical reference covering installation, inventory, ad-hoc commands, playbooks, variables, roles, modules, templates, vault, debugging, and best practices.

---

## Table of Contents

1. Introduction & Installation
2. Ansible CLI Basics
3. Inventory & Hosts
4. Ad-hoc Commands
5. Playbooks
6. Variables & Facts
7. Modules
8. Handlers & Notifications
9. Templates (Jinja2)
10. Roles & Reuse
11. Ansible Collections
12. AWX/Tower Basics
13. Advanced Modules
14. Async and Performance
15. Ansible Vault (Secrets Management)
16. Debugging & Troubleshooting
17. Best Practices
18. References & Resources
19. Useful Commands Summary

---

# 1. Introduction & Installation

**What is Ansible?**

* Open-source automation tool for configuration management, provisioning, and orchestration.
* Agentless — communicates over SSH or WinRM.

**Core concepts**

```
Ansible Architecture:
+----------------+     +----------------+     +----------------+
| Control Node   | --> | Managed Nodes  | --> | Infrastructure |
| (Ansible CLI)  |     | (SSH/WinRM)    |     | (Servers, etc.) |
+----------------+     +----------------+     +----------------+
```

* Inventory: defines hosts and groups.
* Module: reusable unit of work (e.g., copy file, install package).
* Task: action executed on hosts.
* Playbook: YAML file describing automation.
* Role: structured collection of tasks, vars, templates, etc.

**Install**

* macOS: `brew install ansible`
* Linux: `apt-get install ansible` / `yum install ansible` / `dnf install ansible`
* Pip: `pip install ansible` (recommended for latest versions)
* Docker: `docker run -it ansible/ansible:latest ansible --version`
* Verify: `ansible --version`

---

# 2. Ansible CLI Basics

**Ping all hosts**

```bash
ansible all -m ping
```

**Run command**

```bash
ansible all -a "uptime"
```

**Syntax**

```bash
ansible <host-pattern> -m <module> -a "args"
```

**Common options**

* `-i INVENTORY`: specify inventory file
* `-u USER`: remote user
* `--become`: escalate privilege (sudo)
* `-k`: ask SSH password
* `-K`: ask sudo password

---

# 3. Inventory & Hosts

**INI format**

```ini
[web]
web1 ansible_host=192.168.1.10
web2 ansible_host=192.168.1.11

[db]
db1 ansible_host=192.168.1.20 ansible_user=ubuntu
```

**YAML format**

```yaml
all:
  hosts:
    localhost:
      ansible_connection: local
  children:
    web:
      hosts:
        web1:
        web2:
    db:
      hosts:
        db1:
```

**Dynamic inventory**

* Use scripts or plugins (AWS, GCP, Azure).

```bash
ansible-inventory -i inventory.aws_ec2.yml --list
```

---

# 4. Ad-hoc Commands

```bash
ansible all -m ping
ansible web -m shell -a "df -h"
ansible db -m yum -a "name=nginx state=present" --become
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts"
ansible all -m user -a "name=testuser state=present"
```

---

# 5. Playbooks

**Basic structure**

```yaml
- name: Install and start nginx
  hosts: web
  become: yes
  tasks:
    - name: Install nginx
      apt:
        name: nginx
        state: present
    - name: Start nginx
      service:
        name: nginx
        state: started
```

**Multiple plays**

```yaml
- hosts: db
  tasks:
    - name: Install PostgreSQL
      yum:
        name: postgresql
        state: present

- hosts: web
  tasks:
    - name: Copy config
      copy:
        src: files/web.conf
        dest: /etc/web.conf
```

**Practical example: Deploy a web app with database**

```yaml
- name: Deploy web app
  hosts: web
  become: yes
  vars:
    app_port: 8080
  tasks:
    - name: Install Java
      apt:
        name: openjdk-11-jdk
        state: present
    - name: Download app JAR
      get_url:
        url: https://example.com/app.jar
        dest: /opt/app.jar
    - name: Create systemd service
      template:
        src: app.service.j2
        dest: /etc/systemd/system/app.service
      notify: Restart app
    - name: Start app
      service:
        name: app
        state: started

  handlers:
    - name: Restart app
      service:
        name: app
        state: restarted

- name: Setup database
  hosts: db
  become: yes
  tasks:
    - name: Install MySQL
      apt:
        name: mysql-server
        state: present
    - name: Start MySQL
      service:
        name: mysql
        state: started
```

---

# 6. Variables & Facts

**Variables in playbook**

```yaml
vars:
  app_port: 8080

tasks:
  - name: Print port
    debug:
      msg: "App running on port {{ app_port }}"
```

**Extra vars**

```bash
ansible-playbook site.yml -e "app_port=9090"
```

**Facts**

* Gathered by default (`setup` module).

```yaml
- debug:
    var: ansible_facts['os_family']
```

---

# 7. Modules

**Popular modules**

| Category | Modules | Description |
|----------|---------|-------------|
| Package | `apt`, `yum`, `dnf` | Install/remove packages |
| Files | `copy`, `template`, `file`, `synchronize` | Manage files and directories |
| System | `user`, `group`, `service` | User/group/service management |
| Cloud | `ec2`, `gcp_compute`, `azure_rm` | Cloud resource provisioning |
| Utilities | `uri`, `get_url`, `unarchive` | Network and archive operations |

Example:

```yaml
- name: Download file
  get_url:
    url: https://example.com/file
    dest: /tmp/file
```

---

# 8. Handlers & Notifications

**Handler example**

```yaml
- name: Deploy app config
  hosts: web
  tasks:
    - name: Copy config
      copy:
        src: app.conf
        dest: /etc/app.conf
      notify: Restart app

  handlers:
    - name: Restart app
      service:
        name: app
        state: restarted
```

---

# 9. Templates (Jinja2)

**Example template (`nginx.conf.j2`)**

```jinja
server {
  listen {{ app_port }};
  server_name {{ inventory_hostname }};
}
```

**Usage**

```yaml
- name: Deploy template
  template:
    src: templates/nginx.conf.j2
    dest: /etc/nginx/nginx.conf
```

---

# 10. Roles & Reuse

**Create role structure**

```bash
ansible-galaxy init myrole
```

**Role directory**

```
myrole/
  tasks/main.yml
  handlers/main.yml
  templates/
  files/
  vars/main.yml
  defaults/main.yml
```

**Usage in playbook**

```yaml
- hosts: web
  roles:
    - myrole
```

**Galaxy roles**

```bash
ansible-galaxy install geerlingguy.nginx
```

---

# 11. Ansible Collections

**What are Collections?**

* Bundled packages of Ansible content (modules, roles, plugins).
* Introduced in Ansible 2.10 for better organization and distribution.
* Allow FQCN (Fully Qualified Collection Name) for modules.

**Install collections**

```bash
ansible-galaxy collection install community.general
ansible-galaxy collection install amazon.aws
```

**Use FQCN**

```yaml
- name: Create EC2 instance
  amazon.aws.ec2_instance:
    name: my-instance
    state: present
```

**List installed collections**

```bash
ansible-galaxy collection list
```

---

# 12. AWX/Tower Basics

**What is AWX/Tower?**

* Web-based UI for Ansible (AWX is open-source, Tower is enterprise).
* Provides job scheduling, inventory management, and role-based access.

**Key features**

* Job Templates: Predefined playbooks with parameters.
* Inventories: Dynamic host management.
* Credentials: Secure storage for SSH keys, passwords.
* Workflows: Chain multiple job templates.

**Basic usage**

* Install AWX: Use Docker Compose or Kubernetes.
* Create inventory, credentials, and job template.
* Launch jobs via UI or API.

---

# 13. Advanced Modules

**Cloud modules (expanded)**

* AWS: `ec2`, `s3_bucket`, `rds_instance`
* Azure: `azure_rm_virtualmachine`, `azure_rm_storageaccount`
* GCP: `gcp_compute_instance`, `gcp_storage_bucket`

Example: Create S3 bucket

```yaml
- name: Create S3 bucket
  amazon.aws.s3_bucket:
    name: my-bucket
    state: present
    region: us-east-1
```

**Networking modules**

* `netconf_get`, `netconf_config` (for network devices)
* `cli_command` (for CLI-based devices)

**Windows modules**

* `win_command`, `win_service`, `win_user`

---

# 14. Async and Performance

**Async tasks**

* Run long-running tasks asynchronously.

```yaml
- name: Run async task
  command: sleep 30
  async: 45
  poll: 0
```

**Forks**

* Control parallelism: `ansible-playbook site.yml -f 10`

**Performance tuning**

* Use `serial` for rolling updates.
* Limit facts gathering with `gather_facts: false`.
* Use `strategy: free` for parallel execution.

---

# 15. Ansible Vault (Secrets Management)

**Encrypt file**

```bash
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
ansible-vault view secrets.yml
```

**Run playbook with vault**

```bash
ansible-playbook site.yml --ask-vault-pass
```

**Encrypt existing file**

```bash
ansible-vault encrypt file.yml
ansible-vault decrypt file.yml
```

---

# 16. Debugging & Troubleshooting

**Dry run**

```bash
ansible-playbook site.yml --check
```

**Verbose mode**

```bash
ansible-playbook site.yml -vvv
```

**Debug module**

```yaml
- debug:
    var: ansible_facts['hostname']
```

**Limit hosts**

```bash
ansible-playbook site.yml -l web1
```

**Common errors and fixes**

* SSH connection failed: Check SSH keys, user permissions.
* Module not found: Use FQCN or install collection.
* Syntax error: Run `--syntax-check`.
* Permission denied: Use `--become`.

---

# 17. Best Practices

* Use roles for reusability and maintainability.
* Group vars in `group_vars/` and `host_vars/`.
* Use vault for sensitive data.
* Keep playbooks idempotent.
* Prefer modules over shell commands.
* Test with Molecule or ansible-lint.
* Structure inventories (dev/staging/prod).
* Use tags for selective runs.
* Implement security: Least privilege, audit logs.
* Integrate with CI/CD: GitHub Actions, Jenkins.
* Use collections for modern Ansible (2.10+).

---

# 18. References & Resources

**Official Docs**

* [Ansible Documentation](https://docs.ansible.com/)
* [Ansible Galaxy](https://galaxy.ansible.com/)

**Community**

* [Ansible Forum](https://forum.ansible.com/)
* [Reddit r/ansible](https://www.reddit.com/r/ansible/)

**Learning Resources**

* [Ansible Getting Started](https://docs.ansible.com/ansible/latest/getting_started/index.html)
* [Sample Playbooks](https://github.com/ansible/ansible-examples)

**Tools**

* [Molecule](https://molecule.readthedocs.io/) for testing
* [AWX](https://github.com/ansible/awx) open-source Tower

---

# 19. Useful Commands Summary

**Inventory**

```bash
ansible-inventory -i inventory.yml --list
```

**Ad-hoc**

```bash
ansible all -m ping
ansible web -a "uptime"
```

**Playbooks**

```bash
ansible-playbook site.yml
ansible-playbook site.yml --tags "install"
ansible-playbook site.yml -l web1
```

**Vault**

```bash
ansible-vault create secrets.yml
ansible-vault edit secrets.yml
```

**Debug**

```bash
ansible-playbook site.yml --check
ansible-playbook site.yml -vvv
```

---

# Quick Reference: One-liners

* Test syntax:

```bash
ansible-playbook site.yml --syntax-check
```

* Run with extra vars:

```bash
ansible-playbook site.yml -e "env=prod"
```

* Show host facts:

```bash
ansible -m setup web1
```

* List tasks to run:

```bash
ansible-playbook site.yml --list-tasks
```

---

*End of cheat sheet — happy automating with Ansible!*
