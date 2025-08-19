# SOC Toolkit - GitHub Hybrid Integration v2.0
# Professional SOC analyst productivity suite with GitHub content management
# Author: SOC Engineering Team
# Last Modified: 2025-08-19

[CmdletBinding()]
param()

# Global configuration
$script:Config = @{
    GitHubRepo = "https://raw.githubusercontent.com/YOUR-ORG/soc-toolkit-private/main"
    LocalCache = "$env:TEMP\SOC_Toolkit_$(Get-Random)"
    CacheExpiry = 1800  # 30 minutes
    Version = "2.0"
}

# Initialize environment
function Initialize-Toolkit {
    Clear-Host

    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                            SOC TOOLKIT v$($script:Config.Version)                            " -ForegroundColor Cyan  
    Write-Host "                   Security Operations Center - Analyst Suite                   " -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Initializing toolkit..." -ForegroundColor Yellow

    # Test GitHub connectivity
    $githubAvailable = Test-GitHubConnectivity

    if (-not $githubAvailable) {
        Show-ConnectionError
        return $false
    }

    # Create cache directory
    try {
        if (Test-Path $script:Config.LocalCache) {
            Remove-Item $script:Config.LocalCache -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $script:Config.LocalCache -Force | Out-Null
    }
    catch {
        Write-Host "WARNING: Cannot create cache directory - some features may be limited" -ForegroundColor Yellow
    }

    Write-Host "STATUS: GitHub repository connection OK" -ForegroundColor Green
    Write-Host "STATUS: Loading toolkit configuration..." -ForegroundColor Green

    # Load master configuration
    $script:ToolkitConfig = Get-FreshContent -FilePath "toolkit_config.json"
    if (-not $script:ToolkitConfig) {
        Write-Host "ERROR: Cannot load toolkit configuration" -ForegroundColor Red
        return $false
    }

    Write-Host "STATUS: Toolkit configuration loaded successfully" -ForegroundColor Green
    Write-Host ""

    Start-Sleep -Seconds 1
    return $true
}

function Test-GitHubConnectivity {
    try {
        $testUrl = "$($script:Config.GitHubRepo)/config/health_check.txt"
        $response = Invoke-WebRequest -Uri $testUrl -TimeoutSec 10 -ErrorAction Stop
        return $response.StatusCode -eq 200 -and $response.Content.Trim() -eq "OK"
    }
    catch {
        return $false
    }
}

function Show-ConnectionError {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Red
    Write-Host "║                           CONNECTION ERROR                               ║" -ForegroundColor Red
    Write-Host "╚══════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Red
    Write-Host ""
    Write-Host "Cannot connect to SOC Toolkit GitHub repository." -ForegroundColor Yellow
    Write-Host "This toolkit requires access to the latest SOC content and procedures." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Possible causes:" -ForegroundColor Cyan
    Write-Host "  - Network connectivity issues" -ForegroundColor DarkGray
    Write-Host "  - GitHub repository access denied" -ForegroundColor DarkGray
    Write-Host "  - Corporate firewall blocking GitHub" -ForegroundColor DarkGray
    Write-Host "  - Repository URL configuration error" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Options:" -ForegroundColor White
    Write-Host "  [R] Retry connection" -ForegroundColor Green
    Write-Host "  [E] Exit and contact SOC lead" -ForegroundColor Red
    Write-Host ""

    do {
        $choice = Read-Host "Select option (R/E)"
        switch ($choice.ToUpper()) {
            "R" { 
                return Initialize-Toolkit
            }
            "E" { 
                Write-Host ""
                Write-Host "Contact your SOC lead for assistance with repository access." -ForegroundColor Cyan
                Write-Host "Press any key to exit..." -ForegroundColor DarkGray
                $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                exit 0 
            }
            default { 
                Write-Host "Please enter R or E." -ForegroundColor Red 
            }
        }
    } while ($true)
}

function Get-FreshContent {
    param([string]$FilePath)

    try {
        $url = "$($script:Config.GitHubRepo)/$FilePath"
        $content = Invoke-RestMethod -Uri $url -TimeoutSec 15 -ErrorAction Stop
        return $content
    }
    catch {
        return $null
    }
}

function Show-MainMenu {
    Clear-Host

    # Header
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                            SOC TOOLKIT v$($script:Config.Version)                            " -ForegroundColor Cyan  
    Write-Host "                   Security Operations Center - Analyst Suite                   " -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    # Toolkit info
    if ($script:ToolkitConfig) {
        Write-Host "Repository Version: $($script:ToolkitConfig.version) | Last Updated: $($script:ToolkitConfig.last_updated)" -ForegroundColor DarkGray
        Write-Host "Content Source: GitHub Repository (Live)" -ForegroundColor Green
    }
    Write-Host ""

    # Menu options
    Write-Host "Available Functions:" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1] Generate Incident Communication" -ForegroundColor Green
    Write-Host "      Professional email templates for security incidents" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] Launch Splunk Query" -ForegroundColor Green
    Write-Host "      Common SOC investigation queries" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] Execute PowerShell Analysis" -ForegroundColor Green
    Write-Host "      Automated system analysis and forensics tools" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] Open Documentation & Resources" -ForegroundColor Green
    Write-Host "      Quick access to SOC procedures and references" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [5] Refresh Content from Repository" -ForegroundColor Cyan
    Write-Host "      Update to latest templates, queries, and scripts" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [Q] Exit Toolkit" -ForegroundColor Red
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    do {
        $choice = Read-Host "Enter your choice (1-5, Q)"
        $choice = $choice.ToUpper().Trim()

        switch ($choice) {
            "1" { Start-IncidentCommunication }
            "2" { Start-SplunkQuery }
            "3" { Start-PowerShellAnalysis }
            "4" { Start-Documentation }
            "5" { Refresh-RepositoryContent }
            "Q" { 
                Cleanup-Cache
                Clear-Host
                Write-Host "SOC Toolkit session ended. Stay secure!" -ForegroundColor Green
                Write-Host ""
                exit 0 
            }
            default { 
                Write-Host "Invalid choice. Please enter 1-5 or Q." -ForegroundColor Red 
            }
        }
    } while ($true)
}

function Start-IncidentCommunication {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                        INCIDENT COMMUNICATION GENERATOR                        " -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    if (-not $script:ToolkitConfig.incident_templates) {
        Write-Host "ERROR: No incident templates available" -ForegroundColor Red
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    Write-Host "Professional email templates for security incident communications" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available Templates:" -ForegroundColor White
    Write-Host ""

    $counter = 1
    $templateMap = @{}
    foreach ($templateName in ($script:ToolkitConfig.incident_templates.PSObject.Properties.Name | Sort-Object)) {
        $template = $script:ToolkitConfig.incident_templates.$templateName

        # Color code by urgency
        $urgencyColor = switch ($template.urgency) {
            "Critical" { "Red" }
            "High" { "Yellow" }
            "Medium" { "Cyan" }
            "Low" { "Green" }
            default { "White" }
        }

        Write-Host "  [$counter] $templateName" -ForegroundColor $urgencyColor
        Write-Host "      $($template.description)" -ForegroundColor DarkGray
        Write-Host "      Audience: $($template.audience) | Urgency: $($template.urgency)" -ForegroundColor DarkGray
        Write-Host ""

        $templateMap[$counter.ToString()] = $templateName
        $counter++
    }

    Write-Host "  [R] Return to Main Menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $selection = Read-Host "Select template (1-$($script:ToolkitConfig.incident_templates.PSObject.Properties.Count), R)"

    if ($selection.ToUpper() -eq "R") {
        Show-MainMenu
        return
    }

    if (-not $templateMap.ContainsKey($selection)) {
        Write-Host "Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Start-IncidentCommunication
        return
    }

    $selectedTemplateName = $templateMap[$selection]
    $templateInfo = $script:ToolkitConfig.incident_templates.$selectedTemplateName

    # Download and process template
    Write-Host "Loading template: $selectedTemplateName..." -ForegroundColor Yellow

    $templateContent = Get-FreshContent -FilePath $templateInfo.file
    if (-not $templateContent) {
        Write-Host "ERROR: Cannot load template content" -ForegroundColor Red
        Read-Host "Press Enter to return to template selection"
        Start-IncidentCommunication
        return
    }

    Process-IncidentTemplate -TemplateName $selectedTemplateName -TemplateInfo $templateInfo -TemplateContent $templateContent
}

function Process-IncidentTemplate {
    param(
        [string]$TemplateName,
        [object]$TemplateInfo,
        [string]$TemplateContent
    )

    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                           TEMPLATE: $($TemplateName.ToUpper())                           " -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""

    Write-Host "Template Details:" -ForegroundColor Yellow
    Write-Host "  Description: $($TemplateInfo.description)" -ForegroundColor White
    Write-Host "  Target Audience: $($TemplateInfo.audience)" -ForegroundColor White
    Write-Host "  Urgency Level: $($TemplateInfo.urgency)" -ForegroundColor White
    Write-Host ""

    # Extract placeholders from template
    $placeholders = [regex]::Matches($TemplateContent, '\{\{([^}]+)\}\}') | 
                   ForEach-Object { $_.Groups[1].Value } | 
                   Sort-Object -Unique

    if ($placeholders.Count -gt 0) {
        Write-Host "Placeholder Fields to Complete:" -ForegroundColor Cyan
        Write-Host ""
        foreach ($placeholder in $placeholders) {
            Write-Host "  - {{$placeholder}}" -ForegroundColor Yellow
        }
        Write-Host ""
        Write-Host "Replace these placeholder values with actual incident information." -ForegroundColor White
    }

    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Template Actions:" -ForegroundColor White
    Write-Host "  [1] Copy template to clipboard (Recommended)" -ForegroundColor Green
    Write-Host "  [2] Save template to desktop file" -ForegroundColor Green
    Write-Host "  [3] Preview template content" -ForegroundColor Cyan
    Write-Host "  [R] Return to template selection" -ForegroundColor DarkGray
    Write-Host ""

    $action = Read-Host "Select action (1-3, R)"

    switch ($action.ToUpper()) {
        "1" {
            try {
                Set-Clipboard -Value $TemplateContent
                Write-Host ""
                Write-Host "SUCCESS: Template copied to clipboard!" -ForegroundColor Green
                Write-Host ""
                Write-Host "Next steps:" -ForegroundColor Yellow
                Write-Host "  1. Open your email client (Outlook, etc.)" -ForegroundColor White
                Write-Host "  2. Create new email and paste template (Ctrl+V)" -ForegroundColor White
                Write-Host "  3. Replace {{placeholder}} fields with actual values" -ForegroundColor White
                Write-Host "  4. Add appropriate recipients" -ForegroundColor White
                Write-Host "  5. Review and send" -ForegroundColor White
            }
            catch {
                Write-Host ""
                Write-Host "WARNING: Cannot access clipboard" -ForegroundColor Yellow
                Write-Host "Saving template to desktop file instead..." -ForegroundColor Yellow
                Save-TemplateToFile -TemplateName $TemplateName -TemplateContent $TemplateContent
            }
        }
        "2" {
            Save-TemplateToFile -TemplateName $TemplateName -TemplateContent $TemplateContent
        }
        "3" {
            Show-TemplatePreview -TemplateName $TemplateName -TemplateContent $TemplateContent
            Process-IncidentTemplate -TemplateName $TemplateName -TemplateInfo $TemplateInfo -TemplateContent $TemplateContent
            return
        }
        "R" {
            Start-IncidentCommunication
            return
        }
        default {
            Write-Host "Invalid selection." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Process-IncidentTemplate -TemplateName $TemplateName -TemplateInfo $TemplateInfo -TemplateContent $TemplateContent
            return
        }
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Save-TemplateToFile {
    param([string]$TemplateName, [string]$TemplateContent)

    $fileName = "$($TemplateName -replace '[^\w\-_\.]', '_')_$(Get-Date -Format 'yyyyMMdd_HHmmss').html"
    $filePath = "$env:USERPROFILE\Desktop\$fileName"

    try {
        $TemplateContent | Out-File -FilePath $filePath -Encoding UTF8
        Write-Host ""
        Write-Host "SUCCESS: Template saved to desktop!" -ForegroundColor Green
        Write-Host "File: $filePath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "You can now:" -ForegroundColor Yellow
        Write-Host "  - Open the file in your browser to preview" -ForegroundColor White
        Write-Host "  - Copy content and paste into email client" -ForegroundColor White
    }
    catch {
        Write-Host ""
        Write-Host "ERROR: Cannot save template file" -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Show-TemplatePreview {
    param([string]$TemplateName, [string]$TemplateContent)

    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "                           TEMPLATE PREVIEW                           " -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host ""
    Write-Host "Template: $TemplateName" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host $TemplateContent -ForegroundColor White
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Read-Host "Press Enter to return to template options"
}

function Start-PowerShellAnalysis {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host "                          POWERSHELL ANALYSIS SUITE                          " -ForegroundColor Blue
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Blue
    Write-Host ""

    if (-not $script:ToolkitConfig.powershell_scripts) {
        Write-Host "ERROR: No PowerShell scripts available" -ForegroundColor Red
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    Write-Host "Automated system analysis and forensics tools" -ForegroundColor Yellow
    Write-Host ""

    # Group scripts by category
    $categories = $script:ToolkitConfig.powershell_scripts.PSObject.Properties.Value | 
                 Group-Object category | Sort-Object Name

    Write-Host "Available Analysis Tools:" -ForegroundColor White
    Write-Host ""

    $counter = 1
    $scriptMap = @{}

    foreach ($category in $categories) {
        Write-Host "CATEGORY: $($category.Name)" -ForegroundColor Cyan
        Write-Host "   ────────────────────────────────────────" -ForegroundColor Cyan

        foreach ($scriptName in ($category.Group | ForEach-Object { $script:ToolkitConfig.powershell_scripts.PSObject.Properties | Where-Object {$_.Value -eq $_} | Select-Object -ExpandProperty Name })) {
            $script = $script:ToolkitConfig.powershell_scripts.$scriptName

            Write-Host "   [$counter] $scriptName" -ForegroundColor Green
            Write-Host "       $($script.description)" -ForegroundColor DarkGray
            Write-Host "       Runtime: ~$($script.estimated_runtime) | Admin Required: $(if($script.requires_elevation){'Yes'}else{'No'})" -ForegroundColor DarkGray

            $scriptMap[$counter.ToString()] = $scriptName
            $counter++
        }
        Write-Host ""
    }

    Write-Host "  [R] Return to Main Menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $selection = Read-Host "Select analysis tool (1-$($script:ToolkitConfig.powershell_scripts.PSObject.Properties.Count), R)"

    if ($selection.ToUpper() -eq "R") {
        Show-MainMenu
        return
    }

    if (-not $scriptMap.ContainsKey($selection)) {
        Write-Host "Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Start-PowerShellAnalysis
        return
    }

    $selectedScriptName = $scriptMap[$selection]
    $scriptInfo = $script:ToolkitConfig.powershell_scripts.$selectedScriptName

    Execute-PowerShellScript -ScriptName $selectedScriptName -ScriptInfo $scriptInfo
}

function Execute-PowerShellScript {
    param([string]$ScriptName, [object]$ScriptInfo)

    Write-Host ""
    Write-Host "Loading analysis tool: $ScriptName..." -ForegroundColor Yellow

    if ($ScriptInfo.requires_elevation) {
        Write-Host ""
        Write-Host "WARNING: This tool requires administrative privileges" -ForegroundColor Yellow
        Write-Host "Some functions may not work without elevated permissions." -ForegroundColor Yellow
        Write-Host ""
        $continue = Read-Host "Continue anyway? (Y/N)"
        if ($continue.ToUpper() -ne "Y") {
            Start-PowerShellAnalysis
            return
        }
    }

    try {
        $scriptUrl = "$($script:Config.GitHubRepo)/$($ScriptInfo.file)"
        $scriptContent = Invoke-RestMethod -Uri $scriptUrl -TimeoutSec 15

        Write-Host "STATUS: Script loaded successfully" -ForegroundColor Green
        Write-Host "STATUS: Launching analysis tool in new window..." -ForegroundColor Green
        Write-Host ""

        # Save script to temp file and execute in new window
        $tempScript = "$env:TEMP\SOC_Analysis_$(Get-Random).ps1"
        $scriptContent | Out-File -FilePath $tempScript -Encoding UTF8

        # Launch in new PowerShell window with appropriate execution policy
        Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass", "-NoProfile", "-File `"$tempScript`""

        Write-Host "Analysis tool launched successfully!" -ForegroundColor Green
        Write-Host "Check the new PowerShell window for analysis results." -ForegroundColor Cyan

        # Schedule temp file cleanup
        Start-Job -ScriptBlock {
            param($filePath)
            Start-Sleep -Seconds 300  # 5 minutes
            Remove-Item $filePath -ErrorAction SilentlyContinue
        } -ArgumentList $tempScript | Out-Null

    }
    catch {
        Write-Host "ERROR: Cannot execute analysis tool" -ForegroundColor Red
        Write-Host "Details: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "Press Enter to return to analysis menu"
    Start-PowerShellAnalysis
}

function Start-SplunkQuery {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "                              SPLUNK QUERY ASSISTANT                              " -ForegroundColor DarkCyan
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""

    if (-not $script:ToolkitConfig.splunk_queries) {
        Write-Host "ERROR: No Splunk queries available" -ForegroundColor Red
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    Write-Host "Common SOC investigation queries ready for Splunk" -ForegroundColor Yellow
    Write-Host ""

    # Group queries by category
    $categories = $script:ToolkitConfig.splunk_queries.PSObject.Properties.Value | 
                 Group-Object category | Sort-Object Name

    Write-Host "Available Query Categories:" -ForegroundColor White
    Write-Host ""

    $counter = 1
    $queryMap = @{}

    foreach ($category in $categories) {
        Write-Host "CATEGORY: $($category.Name)" -ForegroundColor Cyan
        Write-Host "   ────────────────────────────────────────" -ForegroundColor Cyan

        foreach ($queryName in ($category.Group | ForEach-Object { $script:ToolkitConfig.splunk_queries.PSObject.Properties | Where-Object {$_.Value -eq $_} | Select-Object -ExpandProperty Name })) {
            $query = $script:ToolkitConfig.splunk_queries.$queryName

            # Color code by difficulty
            $difficultyColor = switch ($query.difficulty) {
                "Basic" { "Green" }
                "Intermediate" { "Yellow" }
                "Advanced" { "Red" }
                default { "White" }
            }

            Write-Host "   [$counter] $queryName" -ForegroundColor $difficultyColor
            Write-Host "       $($query.description)" -ForegroundColor DarkGray
            Write-Host "       Timeframe: $($query.timeframe) | Difficulty: $($query.difficulty)" -ForegroundColor DarkGray

            $queryMap[$counter.ToString()] = $queryName
            $counter++
        }
        Write-Host ""
    }

    Write-Host "  [R] Return to Main Menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $selection = Read-Host "Select query (1-$($script:ToolkitConfig.splunk_queries.PSObject.Properties.Count), R)"

    if ($selection.ToUpper() -eq "R") {
        Show-MainMenu
        return
    }

    if (-not $queryMap.ContainsKey($selection)) {
        Write-Host "Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Start-SplunkQuery
        return
    }

    $selectedQueryName = $queryMap[$selection]
    $queryInfo = $script:ToolkitConfig.splunk_queries.$selectedQueryName

    Process-SplunkQuery -QueryName $selectedQueryName -QueryInfo $queryInfo
}

function Process-SplunkQuery {
    param([string]$QueryName, [object]$QueryInfo)

    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host "                           QUERY: $($QueryName.ToUpper())                           " -ForegroundColor DarkCyan
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor DarkCyan
    Write-Host ""

    Write-Host "Loading query from repository..." -ForegroundColor Yellow

    $queryContent = Get-FreshContent -FilePath $QueryInfo.file
    if (-not $queryContent) {
        Write-Host "ERROR: Cannot load query content" -ForegroundColor Red
        Read-Host "Press Enter to return to query selection"
        Start-SplunkQuery
        return
    }

    Write-Host "STATUS: Query loaded successfully" -ForegroundColor Green
    Write-Host ""

    Write-Host "Query Details:" -ForegroundColor Yellow
    Write-Host "  Description: $($QueryInfo.description)" -ForegroundColor White
    Write-Host "  Category: $($QueryInfo.category)" -ForegroundColor White
    Write-Host "  Suggested Timeframe: $($QueryInfo.timeframe)" -ForegroundColor White
    Write-Host "  Difficulty Level: $($QueryInfo.difficulty)" -ForegroundColor White
    Write-Host ""

    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "SPLUNK QUERY:" -ForegroundColor Yellow
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host $queryContent -ForegroundColor White
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    try {
        Set-Clipboard -Value $queryContent.Trim()
        Write-Host "SUCCESS: Query copied to clipboard!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "  1. Open Splunk in your web browser" -ForegroundColor White
        Write-Host "  2. Navigate to Search & Reporting" -ForegroundColor White
        Write-Host "  3. Paste query into search bar (Ctrl+V)" -ForegroundColor White
        Write-Host "  4. Set appropriate time range: $($QueryInfo.timeframe)" -ForegroundColor White
        Write-Host "  5. Run the search" -ForegroundColor White
    }
    catch {
        Write-Host "WARNING: Cannot access clipboard" -ForegroundColor Yellow
        Write-Host "Please copy the query above manually" -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Start-Documentation {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host "                          DOCUMENTATION & RESOURCES                          " -ForegroundColor Magenta
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Magenta
    Write-Host ""

    Write-Host "Loading documentation links from repository..." -ForegroundColor Yellow

    $docLinks = Get-FreshContent -FilePath "config/documentation_links.json"
    if (-not $docLinks) {
        Write-Host "ERROR: Cannot load documentation links" -ForegroundColor Red
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    Write-Host "STATUS: Documentation links loaded successfully" -ForegroundColor Green
    Write-Host ""

    # Group links by category
    $categories = $docLinks.PSObject.Properties.Value | Group-Object category | Sort-Object Name

    Write-Host "Available Resources:" -ForegroundColor White
    Write-Host ""

    $counter = 1
    $linkMap = @{}

    foreach ($category in $categories) {
        Write-Host "CATEGORY: $($category.Name)" -ForegroundColor Cyan
        Write-Host "   ────────────────────────────────────────" -ForegroundColor Cyan

        foreach ($linkName in ($category.Group | ForEach-Object { $docLinks.PSObject.Properties | Where-Object {$_.Value -eq $_} | Select-Object -ExpandProperty Name })) {
            $link = $docLinks.$linkName

            Write-Host "   [$counter] $linkName" -ForegroundColor Green
            Write-Host "       $($link.description)" -ForegroundColor DarkGray

            $linkMap[$counter.ToString()] = @{
                Name = $linkName
                URL = $link.url
                Description = $link.description
            }
            $counter++
        }
        Write-Host ""
    }

    Write-Host "  [R] Return to Main Menu" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "────────────────────────────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $selection = Read-Host "Select resource (1-$($docLinks.PSObject.Properties.Count), R)"

    if ($selection.ToUpper() -eq "R") {
        Show-MainMenu
        return
    }

    if ($linkMap.ContainsKey($selection)) {
        $selectedLink = $linkMap[$selection]

        if ($selectedLink.URL -like "PLACEHOLDER_*") {
            Write-Host ""
            Write-Host "WARNING: This link needs to be configured with your organization's URL" -ForegroundColor Yellow
            Write-Host "Link: $($selectedLink.Name)" -ForegroundColor White
            Write-Host "Current URL: $($selectedLink.URL)" -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "Contact your SOC lead to update the documentation links." -ForegroundColor Cyan
        }
        else {
            try {
                Start-Process $selectedLink.URL
                Write-Host ""
                Write-Host "SUCCESS: Opening resource: $($selectedLink.Name)" -ForegroundColor Green
                Write-Host "URL: $($selectedLink.URL)" -ForegroundColor Cyan
            }
            catch {
                Write-Host ""
                Write-Host "ERROR: Cannot open browser" -ForegroundColor Red
                Write-Host "URL: $($selectedLink.URL)" -ForegroundColor Cyan
                Write-Host "Please copy and paste the URL above into your browser." -ForegroundColor Yellow
            }
        }
    }
    else {
        Write-Host "Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Start-Documentation
        return
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Refresh-RepositoryContent {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                           REFRESHING REPOSITORY CONTENT                           " -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Clearing local cache..." -ForegroundColor Yellow

    # Clear cache
    try {
        if (Test-Path $script:Config.LocalCache) {
            Remove-Item $script:Config.LocalCache -Recurse -Force -ErrorAction SilentlyContinue
        }
        New-Item -ItemType Directory -Path $script:Config.LocalCache -Force | Out-Null
        Write-Host "STATUS: Local cache cleared" -ForegroundColor Green
    }
    catch {
        Write-Host "WARNING: Could not clear cache completely" -ForegroundColor Yellow
    }

    Write-Host "Testing repository connection..." -ForegroundColor Yellow
    $connected = Test-GitHubConnectivity

    if (-not $connected) {
        Write-Host "ERROR: Cannot connect to repository" -ForegroundColor Red
        Write-Host "Repository may be temporarily unavailable." -ForegroundColor Yellow
        Read-Host "Press Enter to return to main menu"
        Show-MainMenu
        return
    }

    Write-Host "STATUS: Repository connection successful" -ForegroundColor Green
    Write-Host "Reloading toolkit configuration..." -ForegroundColor Yellow

    $script:ToolkitConfig = Get-FreshContent -FilePath "toolkit_config.json"
    if ($script:ToolkitConfig) {
        Write-Host "STATUS: Toolkit configuration reloaded" -ForegroundColor Green
        Write-Host "STATUS: Content refresh completed successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Latest version: $($script:ToolkitConfig.version)" -ForegroundColor Cyan
        Write-Host "Last updated: $($script:ToolkitConfig.last_updated)" -ForegroundColor Cyan
    }
    else {
        Write-Host "WARNING: Could not reload configuration" -ForegroundColor Yellow
        Write-Host "Using previously cached configuration." -ForegroundColor Yellow
    }

    Write-Host ""
    Read-Host "Press Enter to return to main menu"
    Show-MainMenu
}

function Cleanup-Cache {
    try {
        if (Test-Path $script:Config.LocalCache) {
            Remove-Item $script:Config.LocalCache -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Cleanup failures are not critical
    }
}

# Main execution
try {
    $initialized = Initialize-Toolkit
    if ($initialized) {
        Show-MainMenu
    }
}
catch {
    Clear-Host
    Write-Host "CRITICAL ERROR: Toolkit initialization failed" -ForegroundColor Red
    Write-Host "Error Details: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please contact your SOC lead or IT support." -ForegroundColor Cyan
    Read-Host "Press Enter to exit"
    exit 1
}
finally {
    Cleanup-Cache
}
