# SOC Tool Launcher Deployment

## Overview

This setup provides a centralized PowerShell launcher for SOC analyst tools hosted on a shared network drive. It ensures analysts always run the most up-to-date script version, logs all usage, and eliminates local script storage or version drift.

---

## Folder Structure

All components reside in the shared location:

```
\\SHARE\Scripts
├── LaunchFromShare.ps1         # Master launcher script
├── HostValidator.ps1           # Example analyst tool
├── launch_log.txt              # Auto-generated execution log
├── SOC_Tool_Launcher.lnk       # Optional clickable shortcut
```

> Replace `\\SHARE\Scripts\` with your actual UNC path.

---

## Components

- **LaunchFromShare.ps1**  
  Core wrapper that presents a dropdown of available `.ps1` tools and executes the selected script in a new PowerShell window.

- **launch_log.txt**  
  Automatically tracks all script launches. Appends one line per execution:  
  `2025-07-28 10:13:00 | jsmith ran HostValidator.ps1`

- **SOC_Tool_Launcher.lnk**  
  Windows shortcut that opens the launcher directly—optional but recommended for ease of use.

- **Tool Scripts (`*.ps1`)**  
  Any other script in this folder becomes selectable through the launcher.

---

## Analyst Usage

### Option 1 – Launch via Shortcut  
Navigate to:

\SHARE\Scripts\SOC_Tool_Launcher.lnk

Double-click to open the tool picker.

---

### Option 2 – Launch via Terminal  
Run from any PowerShell prompt:

```powershell
Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File '\\SHARE\Scripts\LaunchFromShare.ps1'"
```

This opens the dropdown GUI, where analysts select a script to run.

---

## Behavior
- Checks that the network share is accessible before running anythin
- Presents a list of .ps1 tools in the share (excluding the launcher itself)
- Opens the selected script in a new PowerShell window using -NoExit
- Logs the username, timestamp, and script run to launch_log.txt
- Requires no local file downloads or setup

---

## Permissions

| Folder Item       | Analyst Access | Admin Access |
|-------------------|----------------|--------------|
| Scripts (`*.ps1`) | Read-only      | Full         |
| launch_log.txt    | Append-write   | Full         |
| Shortcut (`.lnk`) | Read-only      | Full         |

---

### Benefits
- Analysts always run the latest version of each tool
- Easy to use from either the terminal or a desktop shortcut
- Centralized script management and audit trail
- Eliminates version drift, saves support time

---

Here’s a section you can drop into the README to explain hostname handling and logging behavior to leadership or management:

---

## Input Handling & Analyst Attribution

**Hostname Normalization**
When analysts input a target, the script intelligently handles both IP addresses and fully qualified domain names (FQDNs):

* If an **IP address** is entered (`10.10.8.77`), it is used directly.
* If a **FQDN** is entered (`wks-abc123.corp.domain.com`), only the short hostname (`wks-abc123`) is extracted for resolution and comparison.

  * This avoids mismatches when comparing to NetBIOS and reverse DNS, which typically return the unqualified hostname.

**Environment-Based Attribution**
Analyst activity is automatically tracked without any manual user input:

- The script pulls the **signed-in Windows username** using the built-in environment variable:

  ```powershell
  $env:USERNAME
  ```
- This ensures accurate attribution for every execution, with no dependence on command-line arguments, login prompts, or analyst discipline.

Example log entry:

```
2025-07-28 14:36:18 | jdoe ran HostValidator.ps1 v1.0.0 with input='wks-test1.corp.domain.com' resolved_ip='10.50.21.7'
```

> This provides managers and auditors traceable execution logs tied to individual operators while remaining fully automated and frictionless for analysts.

