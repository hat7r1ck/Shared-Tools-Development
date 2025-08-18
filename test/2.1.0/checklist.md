# splunk_queries/README.md

Splunk Shared Queries System

Common SOC queries organized by category for quick access.

Query Categories
- Security Incidents: Investigation and analysis queries
- System Monitoring: Performance and health queries  
- Threat Hunting: Advanced detection queries
- Compliance & Reporting: Audit and compliance queries
- Quick Investigations: Parameterized triage queries

Configuration
Edit queries.json to:
- Add new queries
- Update Splunk server URL
- Modify default timeframes
- Add query categories

Query Format

"Query Name": {
  "description": "What this query does",
  "query": "index=* your search here", 
  "timeframe": "-4h@h",
  "tags": ["tag1", "tag2"],
  "requires_input": false
}

Updated: $(Get-Date -Format 'yyyy-MM-dd')

---

# DEPLOYMENT_CHECKLIST.md

Deployment Validation Checklist

Pre-Deployment 
- [ ] All files in repository match packing list
- [ ] No sensitive information in configuration files
- [ ] All placeholder URLs updated for your environment
- [ ] Email templates tested and approved
- [ ] Splunk queries validated against your environment

File Verification
Run this PowerShell snippet to verify structure:

$required = @(
    "LaunchFromShare.ps1",
    "scripts\README.md",
    "incident_comms\incident_comm_email.ps1", 
    "incident_comms\templates\critical_security_incident.html",
    "splunk_queries\splunk_query_launcher.ps1",
    "splunk_queries\queries.json",
    "docs\links.json"
)
foreach ($file in $required) {
    if (Test-Path $file) { 
        Write-Host "✓ $file" -ForegroundColor Green 
    } else { 
        Write-Host "✗ $file MISSING" -ForegroundColor Red 
    }
}

Post-Deployment Testing
- [ ] Main launcher starts without errors
- [ ] PowerShell scripts menu shows available scripts
- [ ] Incident communications launches (even with no templates)
- [ ] Splunk queries launches (even with placeholder config)
- [ ] Documentation links work
- [ ] Execution logging working
- [ ] No crashes with invalid input

Configuration Updates Needed
- [ ] Update Splunk server URL in queries.json
- [ ] Update email recipients in incident_comm_email.ps1
- [ ] Update documentation links in docs/links.json
- [ ] Add your actual email templates
- [ ] Add your organization's Splunk queries

Error Scenarios Tested
- [ ] Missing folders (graceful degradation)
- [ ] Corrupted configuration files (clear error messages)
- [ ] No PowerShell scripts (informative message)
- [ ] Network drive disconnection (proper error handling)
- [ ] Invalid user input (validation and retry)

