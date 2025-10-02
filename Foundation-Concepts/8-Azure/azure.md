# Azure Cheat Sheet (Beginner → Expert)

> A practical reference covering Azure CLI, PowerShell, core services, resource management, networking, storage, compute, identity, monitoring, automation, security, and best practices.

---

## Table of Contents

1. Introduction & Setup
2. Azure CLI & PowerShell Basics
3. Resource Groups & Resource Management
4. Compute (VMs, Scale Sets, Functions, AKS)
5. Networking
6. Storage
7. Databases & Data Services
8. Identity & Access Management (IAM)
9. Monitoring & Logging
10. Automation (ARM, Bicep, Terraform)
11. Security & Governance
12. Cost Management
13. Useful CLI & PowerShell Commands

---

# 1. Introduction & Setup

**What is Azure?**

* Microsoft’s cloud platform offering compute, storage, networking, identity, AI, DevOps, and more.

**Install tools**

```bash
# Azure CLI (cross-platform)
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Login
az login

# Set default subscription
az account set --subscription "MySubscription"
```

PowerShell:

```powershell
Install-Module -Name Az -AllowClobber -Scope CurrentUser
Connect-AzAccount
```

---

# 2. Azure CLI & PowerShell Basics

**CLI**

```bash
az account show
az group list
az vm list -o table
```

**PowerShell**

```powershell
Get-AzSubscription
Get-AzResourceGroup
Get-AzVM
```

**Output formats**

* JSON (default), table, tsv, yaml.

```bash
az vm list -o table
```

---

# 3. Resource Groups & Resource Management

**CLI**

```bash
az group create --name myRG --location eastus
az group list -o table
az group delete --name myRG
```

**PowerShell**

```powershell
New-AzResourceGroup -Name myRG -Location eastus
Get-AzResourceGroup
Remove-AzResourceGroup -Name myRG
```

---

# 4. Compute

**Virtual Machines (VMs)**

```bash
az vm create \
  --resource-group myRG \
  --name myVM \
  --image UbuntuLTS \
  --admin-username azureuser \
  --generate-ssh-keys

az vm start --name myVM --resource-group myRG
az vm stop --name myVM --resource-group myRG
```

PowerShell:

```powershell
New-AzVM -ResourceGroupName myRG -Name myVM -Image UbuntuLTS
Start-AzVM -Name myVM -ResourceGroupName myRG
Stop-AzVM -Name myVM -ResourceGroupName myRG
```

**Scale Sets**

```bash
az vmss create --resource-group myRG --name myScaleSet --image UbuntuLTS
```

**Functions**

```bash
az functionapp create --resource-group myRG --consumption-plan-location eastus --runtime python --functions-version 4 --name myFuncApp --storage-account mystorageacct
```

**AKS (Kubernetes)**

```bash
az aks create --resource-group myRG --name myCluster --node-count 3 --enable-addons monitoring --generate-ssh-keys
az aks get-credentials --resource-group myRG --name myCluster
```

---

# 5. Networking

**Virtual Network & Subnet**

```bash
az network vnet create --name myVnet --resource-group myRG --subnet-name mySubnet
```

**Public IP**

```bash
az network public-ip create --resource-group myRG --name myPublicIP
```

**NSG (Network Security Group)**

```bash
az network nsg create --resource-group myRG --name myNSG
az network nsg rule create --resource-group myRG --nsg-name myNSG --name AllowSSH --priority 1000 --access Allow --protocol Tcp --destination-port-ranges 22
```

---

# 6. Storage

**Storage account**

```bash
az storage account create --name mystorageacct --resource-group myRG --location eastus --sku Standard_LRS
```

**Blob container**

```bash
az storage container create --account-name mystorageacct --name mycontainer --auth-mode login
```

**File share**

```bash
az storage share create --name myshare --account-name mystorageacct
```

---

# 7. Databases & Data Services

**Azure SQL Database**

```bash
az sql server create --name mydbserver --resource-group myRG --location eastus --admin-user adminuser --admin-password P@ssw0rd123
az sql db create --resource-group myRG --server mydbserver --name mydatabase --service-objective S0
```

**Cosmos DB**

```bash
az cosmosdb create --name mycosmos --resource-group myRG --kind MongoDB
```

**Azure Storage Table**

```bash
az storage table create --account-name mystorageacct --name mytable
```

---

# 8. Identity & Access Management (IAM)

**Users & Roles**

```bash
az ad user create --display-name "Bob" --user-principal-name bob@contoso.com --password "P@ssword123!"
az role assignment create --assignee bob@contoso.com --role "Contributor" --resource-group myRG
```

**Service Principals**

```bash
az ad sp create-for-rbac --name myApp --role Contributor --scopes /subscriptions/<SUB_ID>/resourceGroups/myRG
```

---

# 9. Monitoring & Logging

**Azure Monitor metrics**

```bash
az monitor metrics list --resource <resourceID> --metric Percentage CPU
```

**Activity logs**

```bash
az monitor activity-log list --resource-group myRG --max-events 5
```

**Log Analytics query**

```bash
az monitor log-analytics query --workspace <workspaceID> --analytics-query "AzureActivity | take 10"
```

---

# 10. Automation (ARM, Bicep, Terraform)

**ARM template deployment**

```bash
az deployment group create --resource-group myRG --template-file template.json
```

**Bicep deployment**

```bash
az deployment group create --resource-group myRG --template-file main.bicep
```

**Terraform**

```bash
terraform init
terraform plan
terraform apply
```

---

# 11. Security & Governance

**Policies**

```bash
az policy definition list
az policy assignment create --name denyPublicIP --policy "DenyPublicIP" --scope /subscriptions/<SUB_ID>
```

**Key Vault**

```bash
az keyvault create --name myKeyVault --resource-group myRG --location eastus
az keyvault secret set --vault-name myKeyVault --name MySecret --value "supersecret"
```

**Azure Defender**

* Security alerts and threat protection.

---

# 12. Cost Management

**View costs**

```bash
az consumption usage list --start-date 2023-01-01 --end-date 2023-01-31
```

**Budgets**

```bash
az consumption budget create --amount 100 --time-frame Month --name MyBudget --category cost --start-date 2023-01-01 --end-date 2023-12-31 --resource-group myRG
```

---

# 13. Useful CLI & PowerShell Commands

**CLI**

```bash
az login
az group list -o table
az vm list -o table
az storage account list -o table
az aks list -o table
```

**PowerShell**

```powershell
Connect-AzAccount
Get-AzResourceGroup
Get-AzVM
Get-AzStorageAccount
Get-AzAksCluster
```

---

# Quick Reference: One-liners

* List all resource groups:

```bash
az group list -o table
```

* Start all VMs in a resource group:

```bash
az vm start --ids $(az vm list -g myRG --query "[].id" -o tsv)
```

* Delete all resources in a group:

```bash
az group delete --name myRG --yes --no-wait
```

* List role assignments:

```bash
az role assignment list -o table
```

---

*End of cheat sheet — happy cloud building with Azure!*
