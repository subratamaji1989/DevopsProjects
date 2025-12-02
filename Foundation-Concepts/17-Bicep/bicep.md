# Bicep Cheat Sheet (Beginner → Advanced)

> Essential Bicep commands, concepts, and patterns for Azure Infrastructure as Code.

---

## Table of Contents

1. [Introduction to Bicep](#1-introduction-to-bicep)
2. [Installation & Setup](#2-installation--setup)
3. [Basic Syntax](#3-basic-syntax)
4. [Parameters](#4-parameters)
5. [Variables](#5-variables)
6. [Resources](#6-resources)
7. [Modules](#7-modules)
8. [Outputs](#8-outputs)
9. [Functions](#9-functions)
10. [Loops and Conditions](#10-loops-and-conditions)
11. [Resource Dependencies](#11-resource-dependencies)
12. [Best Practices](#12-best-practices)
13. [Deployment](#13-deployment)
14. [Advanced Patterns](#14-advanced-patterns)
15. [Troubleshooting](#15-troubleshooting)
16. [Real-World Examples](#16-real-world-examples)

---

# 1. Introduction to Bicep

* **Bicep**: Domain-specific language (DSL) for deploying Azure resources declaratively
* **Benefits**: Simpler syntax than ARM templates, better IntelliSense, modular, type-safe
* **File Extension**: `.bicep`
* **Compilation**: Bicep files compile to ARM JSON templates

```bicep
// Basic Bicep file structure
targetScope = 'subscription'  // or 'resourceGroup', 'managementGroup', 'tenant'

param location string = 'eastus'
var storageAccountName = 'mystorage${uniqueString(resourceGroup().id)}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output storageAccountName string = storageAccount.name
```

---

# 2. Installation & Setup

* **Azure CLI with Bicep** (Recommended):

```bash
# Install Azure CLI
# Windows: winget install -e --id Microsoft.AzureCLI
# macOS: brew update && brew install azure-cli
# Linux: curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify Bicep installation
az bicep version

# Upgrade Bicep
az bicep upgrade
```

* **Visual Studio Code Extensions**:
  - Bicep (Microsoft)
  - Azure Resource Manager Tools

* **Bicep CLI** (Standalone):

```bash
# Download from GitHub releases
# https://github.com/Azure/bicep/releases

# Verify installation
bicep --version

# Build Bicep file to ARM template
bicep build main.bicep
```

---

# 3. Basic Syntax

* **Comments**:

```bicep
// Single line comment

/*
Multi-line
comment
*/
```

* **Data Types**:
  - `string`: Text values
  - `int`: Integer numbers
  - `bool`: True/false values
  - `array`: Ordered list of values
  - `object`: Key-value pairs

* **Expressions**:
  - String interpolation: `'Hello ${name}'`
  - Array access: `array[0]`
  - Property access: `object.property`
  - Ternary operator: `condition ? trueValue : falseValue`

* **Scope Declaration**:

```bicep
// Deployment scopes
targetScope = 'resourceGroup'    // Default
targetScope = 'subscription'
targetScope = 'managementGroup'
targetScope = 'tenant'
```

---

# 4. Parameters

* **Parameter Declaration**:

```bicep
// Required parameter
param environment string

// Parameter with default value
param location string = 'eastus'

// Parameter with validation
param vmSize string {
  allowed: [
    'Standard_B1s'
    'Standard_B2s'
    'Standard_B4ms'
  ]
  default: 'Standard_B1s'
}

// Secure parameter (not logged)
@secure()
param adminPassword string

// Parameter with metadata
@description('The name of the storage account')
param storageAccountName string = 'mystorage'
```

* **Parameter Types**:

```bicep
// Primitive types
param name string
param count int
param enabled bool

// Complex types
param tags object = {
  environment: 'dev'
  project: 'myproject'
}

param subnets array = [
  {
    name: 'subnet1'
    addressPrefix: '10.0.1.0/24'
  }
]

// Union types (Bicep 0.12+)
param location string | 'eastus' | 'westus2'
```

---

# 5. Variables

* **Variable Declaration**:

```bicep
// Simple variables
var environment = 'dev'
var location = 'eastus'
var resourceGroupName = 'my-rg'

// Computed variables
var storageAccountName = '${toLower(environment)}storage${uniqueString(resourceGroup().id)}'
var vnetName = '${environment}-vnet'
var tags = {
  environment: environment
  createdBy: 'bicep'
  createdOn: utcNow()
}

// Complex variables
var subnets = [
  {
    name: 'web'
    addressPrefix: '10.0.1.0/24'
    securityGroup: 'web-nsg'
  }
  {
    name: 'db'
    addressPrefix: '10.0.2.0/24'
    securityGroup: 'db-nsg'
  }
]
```

* **Variable Best Practices**:
  - Use variables for complex expressions
  - Use variables for repeated values
  - Keep variables close to where they're used
  - Use descriptive names

---

# 6. Resources

* **Resource Declaration**:

```bicep
resource resourceName 'resourceType@apiVersion' = {
  name: 'resource-name'
  location: location
  properties: {
    // Resource-specific properties
  }
}
```

* **Common Azure Resources**:

```bicep
// Storage Account
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

// Virtual Network
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: '10.0.0.0/24'
        }
      }
    ]
  }
}

// Virtual Machine
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'Ubuntu2204'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}
```

* **Resource Properties**:
  - `name`: Resource name (required)
  - `location`: Azure region
  - `tags`: Resource tags
  - `sku`: Pricing tier
  - `properties`: Resource-specific configuration

---

# 7. Modules

* **Module Declaration**:

```bicep
module moduleName 'modulePath' = {
  name: 'deployment-name'
  params: {
    // Parameters to pass to module
  }
}
```

* **Module Examples**:

```bicep
// Local module
module storageModule './storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    environment: environment
  }
}

// Remote module (registry)
module networkModule 'br:exampleregistry.azurecr.io/bicep/modules/network:v1.0.0' = {
  name: 'network-deployment'
  params: {
    vnetAddressPrefix: '10.0.0.0/16'
    subnetPrefixes: [
      '10.0.1.0/24'
      '10.0.2.0/24'
    ]
  }
}

// Template spec module
module templateSpec 'ts:subscriptionId/resourceGroupName/templateSpecName:version' = {
  name: 'template-spec-deployment'
  params: {
    // parameters
  }
}
```

* **Module Best Practices**:
  - Use modules for reusable components
  - Keep modules focused on single responsibility
  - Version your modules
  - Use relative paths for local modules
  - Document module parameters

---

# 8. Outputs

* **Output Declaration**:

```bicep
output outputName type = value
```

* **Output Examples**:

```bicep
// Simple outputs
output storageAccountName string = storageAccount.name
output resourceGroupName string = resourceGroup().name

// Complex outputs
output vnetInfo object = {
  id: vnet.id
  name: vnet.name
  addressSpace: vnet.properties.addressSpace.addressPrefixes
  subnets: vnet.properties.subnets
}

// Array outputs
output subnetIds array = [
  for subnet in vnet.properties.subnets: {
    name: subnet.name
    id: subnet.id
  }
]

// Conditional outputs
output backupStorageId string = enableBackup ? backupStorage.id : ''
```

* **Output Best Practices**:
  - Use outputs to return important resource information
  - Avoid outputting sensitive data
  - Use descriptive names
  - Consider downstream dependencies

---

# 9. Functions

* **Built-in Functions**:

```bicep
// String functions
var lowerName = toLower('MY_NAME')
var upperName = toUpper('my_name')
var substring = substring('hello world', 0, 5)  // 'hello'
var replaced = replace('hello world', 'world', 'bicep')
var length = length('hello')  // 5

// Array functions
var array = ['a', 'b', 'c']
var first = first(array)      // 'a'
var last = last(array)        // 'c'
var contains = contains(array, 'b')  // true
var empty = empty([])         // true
var union = union(['a', 'b'], ['b', 'c'])  // ['a', 'b', 'c']

// Resource functions
var rg = resourceGroup()
var sub = subscription()
var tenant = tenant()

// Utility functions
var unique = uniqueString('input')  // Deterministic hash
var utc = utcNow()                  // Current UTC time
var guid = guid(resourceGroup().id, 'storage')  // Deterministic GUID
```

* **Custom Functions** (Bicep 0.14+):

```bicep
// User-defined functions
func buildTags(environment string, project string) object => {
  environment: environment
  project: project
  createdBy: 'bicep'
  createdOn: utcNow()
}

var tags = buildTags('dev', 'myproject')
```

---

# 10. Loops and Conditions

* **Array Loops**:

```bicep
// Static array loop
var environments = ['dev', 'staging', 'prod']
resource storageAccounts 'Microsoft.Storage/storageAccounts@2023-01-01' = [
  for env in environments: {
    name: '${env}storage${uniqueString(resourceGroup().id)}'
    location: location
    sku: {
      name: 'Standard_LRS'
    }
    kind: 'StorageV2'
  }
]

// Index-based loop
resource subnets 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = [
  for (subnet, index) in subnets: {
    parent: vnet
    name: subnet.name
    properties: {
      addressPrefix: subnet.addressPrefix
    }
  }
]

// Conditional loop
resource backupVaults 'Microsoft.RecoveryServices/vaults@2023-01-01' = [
  for env in environments: if (env == 'prod') {
    name: '${env}backupvault'
    location: location
    sku: {
      name: 'RS0'
      tier: 'Standard'
    }
  }
]
```

* **Object Loops**:

```bicep
var tags = {
  environment: 'dev'
  project: 'myproject'
  owner: 'team-a'
}

resource resourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [
  for (key, value) in tags: {
    name: '${key}-${value}-rg'
    location: location
    tags: {
      '${key}': value
    }
  }
]
```

* **Conditional Resources**:

```bicep
// Simple condition
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

// Complex condition
resource backup 'Microsoft.RecoveryServices/vaults@2023-01-01' = if (environment == 'prod' || enableBackup) {
  name: backupVaultName
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
}
```

---

# 11. Resource Dependencies

* **Implicit Dependencies**:

```bicep
// Bicep automatically creates dependencies based on symbolic references
resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  // ...
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = {
  parent: vnet  // Implicit dependency on vnet
  name: 'default'
  // ...
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  // Implicit dependency on subnet through nic
  // ...
}
```

* **Explicit Dependencies**:

```bicep
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' = {
  name: keyVaultName
  location: location
  dependsOn: [
    storageAccount  // Explicit dependency
  ]
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}
```

* **Dependency Best Practices**:
  - Prefer implicit dependencies (symbolic references)
  - Use explicit dependencies sparingly
  - Avoid circular dependencies
  - Consider deployment order

---

# 12. Best Practices

* **File Organization**:

```bicep
// main.bicep - Main deployment file
targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string

module network 'modules/network.bicep' = {
  name: 'network-deployment'
  params: {
    location: location
    environment: environment
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage-deployment'
  params: {
    location: location
    environment: environment
  }
}

// modules/network.bicep
param location string
param environment string

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  // ...
}
```

* **Naming Conventions**:

```bicep
// Use consistent naming
param location string
param environment string
var resourceGroupName = '${environment}-rg'
var storageAccountName = '${environment}storage${uniqueString(resourceGroup().id)}'

// Use descriptive names
param virtualMachineCount int
param enableMonitoring bool

// Avoid abbreviations
// Good
param virtualNetworkAddressPrefix string
// Bad
param vnetAddrPrefix string
```

* **Security Best Practices**:

```bicep
// Use secure parameters
@secure()
param adminPassword string

// Use managed identities
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  // ...
  properties: {
    osProfile: {
      // Avoid storing passwords in templates
    }
  }
}

// Use Azure RBAC
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, principalId, roleDefinitionId)
  scope: resourceGroup()
  properties: {
    principalId: principalId
    roleDefinitionId: roleDefinitionId
  }
}
```

* **Performance Best Practices**:
  - Use modules to reduce template size
  - Minimize use of `reference()` and `resourceId()` functions
  - Use conditional deployments to reduce resource count
  - Avoid large arrays in parameters

---

# 13. Deployment

* **Azure CLI Deployment**:

```bash
# Deploy to resource group
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters environment=dev location=eastus

# Deploy to subscription
az deployment sub create \
  --location eastus \
  --template-file main.bicep \
  --parameters environment=dev

# Deploy to management group
az deployment mg create \
  --management-group-id myMG \
  --location eastus \
  --template-file main.bicep

# What-if deployment
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters environment=dev \
  --what-if
```

* **PowerShell Deployment**:

```powershell
# Deploy to resource group
New-AzResourceGroupDeployment `
  -ResourceGroupName 'myResourceGroup' `
  -TemplateFile 'main.bicep' `
  -TemplateParameterObject @{
    environment = 'dev'
    location = 'eastus'
  }

# What-if deployment
New-AzResourceGroupDeployment `
  -ResourceGroupName 'myResourceGroup' `
  -TemplateFile 'main.bicep' `
  -TemplateParameterObject @{ environment = 'dev' } `
  -WhatIf
```

* **Parameter Files**:

```json
// parameters.dev.json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "environment": {
      "value": "dev"
    },
    "location": {
      "value": "eastus"
    },
    "vmCount": {
      "value": 2
    }
  }
}
```

```bash
# Deploy with parameter file
az deployment group create \
  --resource-group myResourceGroup \
  --template-file main.bicep \
  --parameters @parameters.dev.json
```

---

# 14. Advanced Patterns

* **Nested Deployments**:

```bicep
resource nestedDeployment 'Microsoft.Resources/deployments@2021-04-01' = {
  name: 'nested-deployment'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: [
        {
          type: 'Microsoft.Storage/storageAccounts'
          apiVersion: '2023-01-01'
          name: 'nestedstorage'
          location: location
          sku: {
            name: 'Standard_LRS'
          }
          kind: 'StorageV2'
        }
      ]
    }
  }
}
```

* **Cross-Resource References**:

```bicep
// Reference existing resources
var existingVnet = resourceId('Microsoft.Network/virtualNetworks', 'existing-vnet')
var existingSubnet = resourceId('Microsoft.Network/virtualNetworks/subnets', 'existing-vnet', 'default')

// Get resource properties
var storageAccountKeys = listKeys(storageAccount.id, storageAccount.apiVersion)
var connectionString = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccountKeys.keys[0].value}'
```

* **Template Specs**:

```bicep
// Create template spec
resource templateSpec 'Microsoft.Resources/templateSpecs@2021-05-01' = {
  name: 'my-template-spec'
  location: location
  properties: {
    description: 'Reusable Bicep template'
    versions: {
      '1.0.0': {
        template: loadTextContent('./main.bicep')
      }
    }
  }
}
```

---

# 15. Troubleshooting

* **Common Errors**:

```bicep
// Template validation error: Check resource properties
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Invalid_SKU'  // ❌ Invalid SKU name
  }
}

// Circular dependency error
resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  dependsOn: [vm]  // ❌ Self-dependency
}

// Parameter validation error
param location string {
  allowed: ['eastus', 'westus2']
  default: 'invalid'  // ❌ Default not in allowed values
}
```

* **Debugging Techniques**:

```bash
# Validate template
az bicep build main.bicep

# Check for linting errors
bicep lint main.bicep

# Format Bicep file
bicep format main.bicep

# Decompile ARM template to Bicep
bicep decompile template.json
```

* **Common Issues**:
  - API version mismatches
  - Invalid resource names
  - Missing required properties
  - Incorrect parameter types
  - Circular dependencies

---

# 16. Real-World Examples

* **Web Application Infrastructure**:

```bicep
targetScope = 'resourceGroup'

param location string = resourceGroup().location
param environment string = 'dev'
param appName string = 'mywebapp'

var tags = {
  environment: environment
  project: 'webapp'
}

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appName}-plan'
  location: location
  tags: tags
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
}

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: true
      http20Enabled: true
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: '${appName}storage${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
  }
}

output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output storageAccountName string = storageAccount.name
```

* **Virtual Machine with Networking**:

```bicep
param location string = resourceGroup().location
param vmName string = 'myvm'
param adminUsername string
@secure()
param adminPassword string
param vmSize string = 'Standard_B2s'

var vnetName = '${vmName}-vnet'
var subnetName = 'default'
var nsgName = '${vmName}-nsg'
var nicName = '${vmName}-nic'

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-02-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'Ubuntu2204'
        sku: '22_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

output vmPrivateIp string = nic.properties.ipConfigurations[0].properties.privateIPAddress
output vmId string = vm.id
```

* **AKS Cluster with Monitoring**:

```bicep
param location string = resourceGroup().location
param clusterName string = 'myaks'
param nodeCount int = 3
param vmSize string = 'Standard_D2_v2'
param enableMonitoring bool = true

var logAnalyticsName = '${clusterName}-logs'

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = if (enableMonitoring) {
  name: logAnalyticsName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2023-02-01' = {
  name: clusterName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.26.3'
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: nodeCount
        vmSize: vmSize
        osType: 'Linux'
        mode: 'System'
      }
    ]
    addonProfiles: enableMonitoring ? {
      omsAgent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: logAnalytics.id
        }
      }
    } : {}
  }
}

output clusterName string = aks.name
output clusterResourceId string = aks.id
output kubeConfig string = aks.properties.kubeConfig
```

---

*End of Bicep cheat sheet — master Azure Infrastructure as Code with Bicep!*
