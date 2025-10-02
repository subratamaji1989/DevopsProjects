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
11. Ansible Vault (Secrets Management)
12. Debugging & Troubleshooting
13. Best Practices
14. Useful Commands Summary

---

# 1. Introduction & Installation

**What is Ansible?**

* Open-source automation tool for configuration management, provisioning, and orchestration.
* Agentless — communicates over SSH or WinRM.

**Core concepts**

* Inventory: defines hosts and groups.
* Module: reusable unit of work (e.g., copy file, install package).
* Task: action executed on hosts.
* Playbook: YAML file describing automation.
* Role: structured collection of tasks, vars, templates, etc.

**Install**

* macOS: `brew install ansible`
* Linux: `apt-get install ansible` / `yum install ansible`
* Pip: `pip install ansible`
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

* Package: `apt`, `yum`, `dnf`
* Files: `copy`, `template`, `file`, `synchronize`
* System: `user`, `group`, `service`
* Cloud: `ec2`, `gcp_compute`, `azure_rm`
* Utilities: `uri`, `get_url`, `unarchive`

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

# 11. Ansible Vault (Secrets Management)

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

# 12. Debugging & Troubleshooting

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

---

# 13. Best Practices

* Use roles for reusability and maintainability.
* Group vars in `group_vars/` and `host_vars/`.
* Use vault for sensitive data.
* Keep playbooks idempotent.
* Prefer modules over shell commands.
* Test with Molecule or CI pipelines.
* Structure inventories (dev/staging/prod).
* Use tags for selective runs.

---

# 14. Useful Commands Summary

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
