# PowerShell Cheat Sheet (Beginner → Expert)

> A practical reference covering installation, basic syntax, cmdlets, scripting, functions, objects, pipelines, remoting, error handling, debugging, and best practices.

---

## Table of Contents

1. Introduction & Installation
2. PowerShell Basics
3. Cmdlets & Aliases
4. Variables & Data Types
5. Operators
6. Objects & Pipelines
7. Conditional Logic & Loops
8. Functions & Scripts
9. Modules & Packages
10. Error Handling & Debugging
11. PowerShell Remoting
12. File System & Registry
13. Security & Execution Policy
14. Useful Commands Summary

---

# 1. Introduction & Installation

**What is PowerShell?**

* Task automation and configuration management shell from Microsoft.
* Built on .NET, supports object-oriented scripting.
* Cross-platform (Windows, macOS, Linux).

**Install**

* Windows: Pre-installed (Windows PowerShell), or install latest PowerShell (Core) from [GitHub](https://github.com/PowerShell/PowerShell).
* macOS/Linux: Install via package manager (brew, apt, yum, snap).
* Verify: `pwsh --version`

---

# 2. PowerShell Basics

**Prompt basics**

```powershell
Get-Command      # list available commands
Get-Help <cmd>   # show help
Get-Module -ListAvailable
Get-Service
```

**Command syntax**

```powershell
Verb-Noun -Parameter Value
```

---

# 3. Cmdlets & Aliases

**Cmdlet structure**

* Verb-Noun (e.g., `Get-Process`, `Set-Item`).
* Consistent naming.

**Examples**

```powershell
Get-Process
Stop-Process -Name notepad
Get-ChildItem C:\Users
```

**Common aliases**

* `ls`, `dir`, `gci` → `Get-ChildItem`
* `cat`, `type` → `Get-Content`
* `rm`, `del` → `Remove-Item`
* `where` → `Where-Object`
* `?` → `Where-Object`
* `%` → `ForEach-Object`

---

# 4. Variables & Data Types

**Variables**

```powershell
$name = "Alice"
$number = 42
$array = @(1, 2, 3)
$hash = @{ key = "value"; id = 1 }
```

**Special variables**

* `$PSVersionTable`
* `$_` → current object in pipeline
* `$?` → success of last command
* `$LASTEXITCODE`

---

# 5. Operators

**Comparison**

* `-eq`, `-ne`, `-lt`, `-gt`, `-le`, `-ge`
* `-like`, `-match`, `-contains`, `-in`

**Examples**

```powershell
5 -eq 5   # True
"abc" -like "a*"   # True
```

**Logical**

* `-and`, `-or`, `-not`

**Assignment**

* `=`, `+=`, `-=`, `*=`

---

# 6. Objects & Pipelines

**Pipeline basics**

```powershell
Get-Process | Where-Object {$_.CPU -gt 100} | Sort-Object CPU -Descending
```

**Select properties**

```powershell
Get-Service | Select-Object Name, Status
```

**Export/import**

```powershell
Get-Process | Export-Csv processes.csv
Import-Csv processes.csv
```

---

# 7. Conditional Logic & Loops

**If/else**

```powershell
if ($x -gt 10) {
  Write-Output "Greater"
} elseif ($x -eq 10) {
  Write-Output "Equal"
} else {
  Write-Output "Less"
}
```

**Loops**

```powershell
foreach ($i in 1..5) { Write-Output $i }

for ($i=0; $i -lt 5; $i++) { Write-Output $i }

while ($true) { break }
```

---

# 8. Functions & Scripts

**Define function**

```powershell
function Get-Square($num) {
  return $num * $num
}
```

**Script basics**

* File extension: `.ps1`
* Run script:

```powershell
./script.ps1
```

**Parameters**

```powershell
param(
  [string]$Name,
  [int]$Age
)
```

---

# 9. Modules & Packages

**Modules**

```powershell
Get-Module -ListAvailable
Import-Module AzureAD
Remove-Module AzureAD
```

**Install module**

```powershell
Install-Module -Name Az -Scope CurrentUser
Update-Module Az
```

**Packages**

```powershell
Find-Package
Install-Package
```

---

# 10. Error Handling & Debugging

**Try/catch**

```powershell
try {
  1/0
} catch {
  Write-Error "Error: $_"
}
```

**Trap**

```powershell
trap [Exception] {
  Write-Output "Caught an error"
  continue
}
```

**Debugging**

```powershell
Set-PSDebug -Trace 1
```

---

# 11. PowerShell Remoting

**Enable remoting**

```powershell
Enable-PSRemoting -Force
```

**Invoke command**

```powershell
Invoke-Command -ComputerName server1 -ScriptBlock { Get-Process }
```

**Enter remote session**

```powershell
Enter-PSSession -ComputerName server1
Exit-PSSession
```

---

# 12. File System & Registry

**Files**

```powershell
Get-Content file.txt
Set-Content file.txt "Hello"
Add-Content file.txt "World"
Remove-Item file.txt
```

**Registry**

```powershell
Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion
Set-ItemProperty -Path HKCU:\Software\MyApp -Name Setting -Value "123"
```

---

# 13. Security & Execution Policy

**Execution policy**

```powershell
Get-ExecutionPolicy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Signed scripts**

* Use code-signing certificate.
* Enforce: `AllSigned` policy.

**Credentials**

```powershell
$cred = Get-Credential
Invoke-Command -ComputerName server1 -Credential $cred -ScriptBlock { whoami }
```

---

# 14. Useful Commands Summary

**System info**

```powershell
Get-ComputerInfo
Get-Process
Get-Service
Get-EventLog -LogName System -Newest 10
```

**Networking**

```powershell
Test-Connection google.com
Get-NetIPAddress
Get-NetAdapter
```

**User management**

```powershell
Get-LocalUser
New-LocalUser -Name Bob -Password (Read-Host -AsSecureString)
Add-LocalGroupMember -Group Administrators -Member Bob
```

**File operations**

```powershell
Get-ChildItem
Copy-Item file.txt C:\Backup
Move-Item file.txt C:\Backup
```

---

# Quick Reference: One-liners

* Get top processes by CPU:

```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5
```

* Kill process by name:

```powershell
Stop-Process -Name notepad -Force
```

* Search files recursively:

```powershell
Get-ChildItem -Recurse -Filter "*.log"
```

* Replace text in file:

```powershell
(Get-Content file.txt) -replace "old", "new" | Set-Content file.txt
```

---

*End of cheat sheet — happy scripting with PowerShell!*
