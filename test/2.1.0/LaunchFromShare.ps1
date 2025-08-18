# LaunchFromShare.ps1
# CTFC Tool Launcher - Version 2.1.0


[CmdletBinding()]
param()

# Global configuration - paths and settings
$script:Config = @{
    BasePath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Definition }
}
$script:Config.ScriptRoot = Join-Path $Config.BasePath "scripts"
$script:Config.IncidentCommsPath = Join-Path $Config.BasePath "incident_comms"
$script:Config.SplunkQueriesPath = Join-Path $Config.BasePath "splunk_queries"
$script:Config.DocsPath = Join-Path $Config.BasePath "docs"
$script:Config.LogFile = Join-Path $Config.BasePath "logs\execution_log.txt"

function Initialize-Environment {
    # Create required directories with proper error handling
    $requiredDirs = @(
        (Split-Path $script:Config.LogFile -Parent),
        $script:Config.DocsPath
    )

    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir)) {
            try {
                New-Item -ItemType Directory -Path $dir -Force -ErrorAction Stop | Out-Null
                Write-Host "Created directory: $dir" -ForegroundColor DarkGray
            }
            catch {
                Write-Host "FATAL ERROR: Cannot create required directory: $dir" -ForegroundColor Red
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        }
    }

    # Check for critical tool directories (these should exist)
    $criticalPaths = @(
        @{ Path = $script:Config.ScriptRoot; Name = "PowerShell Scripts"; Required = $true },
        @{ Path = $script:Config.IncidentCommsPath; Name = "Incident Communications"; Required = $false },
        @{ Path = $script:Config.SplunkQueriesPath; Name = "Splunk Queries"; Required = $false }
    )

    $criticalMissing = @()
    foreach ($pathInfo in $criticalPaths) {
        if (-not (Test-Path $pathInfo.Path)) {
            if ($pathInfo.Required) {
                $criticalMissing += $pathInfo.Name
            } else {
                Write-Host "Optional tool not installed: $($pathInfo.Name)" -ForegroundColor Yellow
            }
        }
    }

    if ($criticalMissing.Count -gt 0) {
        Write-Host "CRITICAL ERROR: Missing required components:" -ForegroundColor Red
        $criticalMissing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
        Write-Host ""
        Write-Host "Please ensure the scripts folder exists with your PowerShell tools." -ForegroundColor Yellow
        return $false
    }

    return $true
}

function Write-ExecutionLog {
    param([string]$Action, [string]$Details = "")

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "$timestamp | $env:USERNAME | $Action"
        if ($Details) { $logEntry += " | $Details" }

        Add-Content -Path $script:Config.LogFile -Value $logEntry -Encoding UTF8 -ErrorAction Stop
    }
    catch {
        # Log failures should not break the application
        Write-Warning "Failed to write execution log (continuing): $($_.Exception.Message)"
    }
}

function Test-ScriptExecution {
    param([string]$ScriptPath)

    # Basic validation before attempting to run any script
    if (-not (Test-Path $ScriptPath)) {
        return @{ Success = $false; Error = "Script file not found: $ScriptPath" }
    }

    try {
        # Check if file is readable
        $content = Get-Content $ScriptPath -TotalCount 1 -ErrorAction Stop
        return @{ Success = $true; Error = $null }
    }
    catch {
        return @{ Success = $false; Error = "Cannot read script file: $($_.Exception.Message)" }
    }
}

function Show-MainMenu {
    Clear-Host
    Write-Host "CTFC Tool Launcher v2.1.0" -ForegroundColor Cyan
    Write-Host "Security Operations Center - Tool Access Portal" -ForegroundColor DarkGray
    Write-Host ""

    # Dynamic menu based on available tools
    $menuItems = @()
    $menuItems += @{ Number = "1"; Name = "Incident Communications"; Available = (Test-Path (Join-Path $script:Config.IncidentCommsPath "incident_comm_email.ps1")) }
    $menuItems += @{ Number = "2"; Name = "PowerShell Scripts"; Available = ((Get-ChildItem -Path $script:Config.ScriptRoot -Filter "*.ps1" -ErrorAction SilentlyContinue).Count -gt 0) }
    $menuItems += @{ Number = "3"; Name = "Splunk Shared Queries"; Available = (Test-Path (Join-Path $script:Config.SplunkQueriesPath "splunk_query_launcher.ps1")) }
    $menuItems += @{ Number = "4"; Name = "Documentation & Links"; Available = $true }
    $menuItems += @{ Number = "5"; Name = "View Execution Logs"; Available = $true }

    Write-Host "Available Tools:" -ForegroundColor Yellow
    Write-Host ""

    foreach ($item in $menuItems) {
        $status = if ($item.Available) { "" } else { " (Not Available)" }
        $color = if ($item.Available) { "Green" } else { "DarkGray" }
        Write-Host "  [$($item.Number)] $($item.Name)$status" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "  [Q] Quit" -ForegroundColor Red
    Write-Host ""

    do {
        $choice = Read-Host "Enter your choice (1-5, Q)"
        $choice = $choice.ToUpper().Trim()

        switch ($choice) {
            "1" { Start-IncidentCommunications }
            "2" { Start-PowerShellScripts }
            "3" { Start-SplunkQueries }
            "4" { Start-Documentation }
            "5" { Show-ExecutionLogs }
            "Q" { 
                Write-Host "Goodbye!" -ForegroundColor Green
                exit 0 
            }
            default { 
                Write-Host "Invalid choice. Please enter 1-5 or Q." -ForegroundColor Red 
            }
        }
    } while ($choice -notin @("1", "2", "3", "4", "5", "Q"))
}

function Start-IncidentCommunications {
    Clear-Host
    Write-Host "Incident Communications - Template Based Email System" -ForegroundColor Green
    Write-Host ""

    $scriptPath = Join-Path $script:Config.IncidentCommsPath "incident_comm_email.ps1"
    $validation = Test-ScriptExecution -ScriptPath $scriptPath

    if (-not $validation.Success) {
        Write-Host "ERROR: Incident Communications not available" -ForegroundColor Red
        Write-Host "Reason: $($validation.Error)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This tool creates professional incident emails using approved templates." -ForegroundColor Cyan
        Write-Host "Contact your SOC lead to set up the incident communications system." -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    # Check templates exist
    $templatesPath = Join-Path $script:Config.IncidentCommsPath "templates"
    $templateCount = (Get-ChildItem -Path $templatesPath -Filter "*.html" -ErrorAction SilentlyContinue).Count

    if ($templateCount -eq 0) {
        Write-Host "WARNING: No email templates found" -ForegroundColor Yellow
        Write-Host "Templates folder: $templatesPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Email templates are required for this tool to function." -ForegroundColor Yellow
        Write-Host "Contact your SOC lead to install the approved email templates." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    Write-Host "Launching Incident Communications System..." -ForegroundColor Green
    Write-Host "Templates available: $templateCount" -ForegroundColor Cyan
    Write-Host ""

    try {
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass", "-File `"$scriptPath`"" -ErrorAction Stop
        Write-ExecutionLog "Launched Incident Communications" "Templates: $templateCount"
        Write-Host "SUCCESS: Tool launched in new window" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to launch tool: $($_.Exception.Message)" -ForegroundColor Red
        Write-ExecutionLog "FAILED to launch Incident Communications" $_.Exception.Message
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Start-PowerShellScripts {
    Clear-Host
    Write-Host "PowerShell Scripts - SOC Automation Tools" -ForegroundColor Blue
    Write-Host ""

    try {
        $scripts = Get-ChildItem -Path $script:Config.ScriptRoot -Filter "*.ps1" -ErrorAction Stop | 
                   Where-Object { $_.Name -ne (Split-Path $MyInvocation.MyCommand.Path -Leaf) }

        if ($scripts.Count -eq 0) {
            Write-Host "No PowerShell scripts found in: $($script:Config.ScriptRoot)" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Add your SOC automation scripts to the scripts folder." -ForegroundColor Cyan
            Write-Host ""
            Read-Host "Press Enter to return to main menu"
            Show-MainMenu
            return
        }

        Write-Host "Available Scripts: $($scripts.Count)" -ForegroundColor Green
        Write-Host ""

        # Add return option and show selection
        $options = @("Return to Main Menu") + $scripts.Name
        $selection = $options | Out-GridView -Title "Select PowerShell Script to Execute" -OutputMode Single

        if (-not $selection -or $selection -eq "Return to Main Menu") {
            Show-MainMenu
            return
        }

        $selectedPath = Join-Path $script:Config.ScriptRoot $selection
        $validation = Test-ScriptExecution -ScriptPath $selectedPath

        if (-not $validation.Success) {
            Write-Host "ERROR: Cannot execute script" -ForegroundColor Red
            Write-Host "Reason: $($validation.Error)" -ForegroundColor Yellow
            Read-Host "Press Enter to return to main menu"
            Show-MainMenu
            return
        }

        Write-Host "Executing: $selection" -ForegroundColor Green

        try {
            Start-Process powershell.exe -ArgumentList "-NoExit", "-ExecutionPolicy Bypass", "-File `"$selectedPath`"" -ErrorAction Stop
            Write-ExecutionLog "Executed PowerShell Script" $selection
            Write-Host "SUCCESS: Script launched in new window" -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Script execution failed: $($_.Exception.Message)" -ForegroundColor Red
            Write-ExecutionLog "FAILED to execute PowerShell Script" "$selection - $($_.Exception.Message)"
        }
    }
    catch {
        Write-Host "ERROR: Cannot access scripts folder: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Scripts folder: $($script:Config.ScriptRoot)" -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Start-SplunkQueries {
    Clear-Host
    Write-Host "Splunk Shared Queries - SOC Query Library" -ForegroundColor DarkCyan
    Write-Host ""

    $scriptPath = Join-Path $script:Config.SplunkQueriesPath "splunk_query_launcher.ps1"
    $validation = Test-ScriptExecution -ScriptPath $scriptPath

    if (-not $validation.Success) {
        Write-Host "ERROR: Splunk Queries not available" -ForegroundColor Red
        Write-Host "Reason: $($validation.Error)" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "This tool provides quick access to common SOC Splunk queries." -ForegroundColor Cyan
        Write-Host "Contact your SOC lead to set up the Splunk queries system." -ForegroundColor Cyan
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    # Check queries configuration
    $queriesFile = Join-Path $script:Config.SplunkQueriesPath "queries.json"
    if (-not (Test-Path $queriesFile)) {
        Write-Host "WARNING: Queries configuration not found" -ForegroundColor Yellow
        Write-Host "Configuration file: $queriesFile" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Query definitions are required for this tool." -ForegroundColor Yellow
        Write-Host ""
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    Write-Host "Launching Splunk Query System..." -ForegroundColor Green
    Write-Host ""

    try {
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass", "-File `"$scriptPath`"" -ErrorAction Stop
        Write-ExecutionLog "Launched Splunk Queries" "Configuration: $queriesFile"
        Write-Host "SUCCESS: Tool launched in new window" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Failed to launch tool: $($_.Exception.Message)" -ForegroundColor Red
        Write-ExecutionLog "FAILED to launch Splunk Queries" $_.Exception.Message
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Start-Documentation {
    Clear-Host
    Write-Host "Documentation & Links - SOC Knowledge Base" -ForegroundColor Magenta
    Write-Host ""

    # Initialize documentation system
    Initialize-DocumentationSystem

    # Load links configuration
    $linksFile = Join-Path $script:Config.DocsPath "links.json"
    if (Test-Path $linksFile) {
        try {
            $linksConfig = Get-Content $linksFile -Raw | ConvertFrom-Json
            Show-DocumentationMenu -LinksConfig $linksConfig
        }
        catch {
            Write-Host "ERROR: Invalid links configuration: $($_.Exception.Message)" -ForegroundColor Red
            Show-BasicDocumentation
        }
    }
    else {
        Show-BasicDocumentation
    }
}

function Initialize-DocumentationSystem {
    # Create documentation structure if missing
    $readmePath = Join-Path $script:Config.DocsPath "README.md"
    $linksPath = Join-Path $script:Config.DocsPath "links.json"

    if (-not (Test-Path $readmePath)) {
        $readmeContent = @"
# SOC Documentation & Links

This folder contains links to SOC documentation across various platforms and local reference files.

## Quick Links
See links.json for configured quick links to:
- Confluence spaces
- SharePoint sites
- Local documentation files

## Local Files
Place SOC reference documents in this folder for quick access:
- Incident response playbooks
- Contact lists
- Procedure documents
- Reference guides

Updated: $(Get-Date -Format 'yyyy-MM-dd')
"@
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
    }

    if (-not (Test-Path $linksPath)) {
        $defaultLinks = @{
            external_links = @{
                confluence = @{
                    name = "SOC Confluence Space"
                    url = "https://your-company.atlassian.net/wiki/spaces/SOC"
                    description = "SOC procedures and documentation"
                }
                sharepoint = @{
                    name = "Security SharePoint Site"
                    url = "https://your-company.sharepoint.com/sites/security"
                    description = "Security team collaboration site"
                }
                incident_response = @{
                    name = "Incident Response Playbooks"
                    url = "https://your-company.atlassian.net/wiki/spaces/IR"
                    description = "Detailed incident response procedures"
                }
                contact_list = @{
                    name = "Emergency Contact List"
                    url = "https://your-company.sharepoint.com/sites/security/contacts"
                    description = "After-hours and escalation contacts"
                }
            }
            local_docs = @{
                enabled = $true
                scan_extensions = @(".md", ".pdf", ".docx", ".txt")
            }
        } | ConvertTo-Json -Depth 4

        $defaultLinks | Out-File -FilePath $linksPath -Encoding UTF8
    }
}

function Show-DocumentationMenu {
    param($LinksConfig)

    Write-Host "Available Documentation:" -ForegroundColor Yellow
    Write-Host ""

    $options = @()
    $actions = @{}
    $counter = 1

    # Add external links
    if ($LinksConfig.external_links) {
        Write-Host "External Links:" -ForegroundColor Cyan
        foreach ($linkKey in $LinksConfig.external_links.PSObject.Properties.Name) {
            $link = $LinksConfig.external_links.$linkKey
            Write-Host "  [$counter] $($link.name)" -ForegroundColor Green
            Write-Host "      $($link.description)" -ForegroundColor DarkGray
            $options += "$counter"
            $actions[$counter.ToString()] = @{ Type = "URL"; Value = $link.url; Name = $link.name }
            $counter++
        }
        Write-Host ""
    }

    # Add local files
    if ($LinksConfig.local_docs.enabled) {
        $localFiles = Get-ChildItem -Path $script:Config.DocsPath -File | 
                     Where-Object { $_.Extension -in $LinksConfig.local_docs.scan_extensions }

        if ($localFiles.Count -gt 0) {
            Write-Host "Local Documentation:" -ForegroundColor Cyan
            foreach ($file in $localFiles) {
                Write-Host "  [$counter] $($file.Name)" -ForegroundColor Green
                $options += "$counter"
                $actions[$counter.ToString()] = @{ Type = "File"; Value = $file.FullName; Name = $file.Name }
                $counter++
            }
            Write-Host ""
        }
    }

    # Add management options
    Write-Host "Management:" -ForegroundColor Cyan
    Write-Host "  [$counter] Open Documentation Folder" -ForegroundColor Green
    $actions[$counter.ToString()] = @{ Type = "Folder"; Value = $script:Config.DocsPath; Name = "Documentation Folder" }
    $options += "$counter"
    $counter++

    Write-Host "  [$counter] Return to Main Menu" -ForegroundColor Green
    $actions[$counter.ToString()] = @{ Type = "Return"; Value = $null; Name = "Main Menu" }
    $options += "$counter"

    Write-Host ""

    do {
        $choice = Read-Host "Enter your choice"
        if ($actions.ContainsKey($choice)) {
            $action = $actions[$choice]

            switch ($action.Type) {
                "URL" {
                    try {
                        Start-Process $action.Value
                        Write-ExecutionLog "Opened Documentation Link" $action.Name
                        Write-Host "Opened: $($action.Name)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "ERROR: Failed to open link: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                "File" {
                    try {
                        Start-Process $action.Value
                        Write-ExecutionLog "Opened Documentation File" $action.Name
                        Write-Host "Opened: $($action.Name)" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "ERROR: Failed to open file: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                "Folder" {
                    try {
                        Start-Process explorer.exe -ArgumentList $action.Value
                        Write-ExecutionLog "Opened Documentation Folder"
                        Write-Host "Opened: Documentation Folder" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "ERROR: Failed to open folder: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                "Return" {
                    Show-MainMenu
                    return
                }
            }
        }
        else {
            Write-Host "Invalid choice. Please try again." -ForegroundColor Red
        }
    } while ($true)
}

function Show-BasicDocumentation {
    Write-Host "Basic documentation access (links.json not configured)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available options:" -ForegroundColor Cyan
    Write-Host "  [1] Open Documentation Folder" -ForegroundColor Green
    Write-Host "  [2] Return to Main Menu" -ForegroundColor Green
    Write-Host ""

    $choice = Read-Host "Enter your choice (1-2)"
    switch ($choice) {
        "1" {
            try {
                Start-Process explorer.exe -ArgumentList $script:Config.DocsPath
                Write-ExecutionLog "Opened Documentation Folder"
                Write-Host "Opened: Documentation Folder" -ForegroundColor Green
            }
            catch {
                Write-Host "ERROR: Failed to open folder: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        "2" { Show-MainMenu; return }
        default { Write-Host "Invalid choice." -ForegroundColor Red }
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Show-ExecutionLogs {
    Clear-Host
    Write-Host "Execution Logs - Tool Usage History" -ForegroundColor DarkGray
    Write-Host ""

    if (-not (Test-Path $script:Config.LogFile)) {
        Write-Host "No execution logs found yet." -ForegroundColor Yellow
        Write-Host "Logs will be created when SOC tools are executed." -ForegroundColor Cyan
        Write-Host "Log location: $($script:Config.LogFile)" -ForegroundColor DarkGray
    }
    else {
        try {
            Write-Host "Recent tool executions (last 25 entries):" -ForegroundColor Yellow
            Write-Host ""

            $logEntries = Get-Content $script:Config.LogFile -Tail 25 -ErrorAction Stop
            foreach ($entry in $logEntries) {
                Write-Host "  $entry" -ForegroundColor White
            }

            Write-Host ""
            Write-Host "Full log file: $($script:Config.LogFile)" -ForegroundColor DarkGray
        }
        catch {
            Write-Host "ERROR: Cannot read log file: $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

# Main execution with comprehensive error handling
try {
    Write-Host "Initializing CTFC Tool Launcher..." -ForegroundColor Cyan

    if (-not (Initialize-Environment)) {
        Write-Host ""
        Write-Host "INITIALIZATION FAILED" -ForegroundColor Red
        Write-Host "Cannot start launcher due to critical errors above." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Contact your SOC lead for assistance." -ForegroundColor Cyan
        Read-Host "Press Enter to exit"
        exit 1
    }

    # Start main application
    Show-MainMenu
}
catch {
    Write-Host ""
    Write-Host "CRITICAL ERROR: Launcher crashed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Contact IT support immediately." -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}
