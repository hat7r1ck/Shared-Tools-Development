launcher expects:
- toolkit_config.json (master index)
- config/health_check.txt 
- config/documentation_links.json
- templates/*.html files
- queries/*.spl files  
- scripts/*.ps1 files (but they might already have these or don't want me to provide them again)


## Required Repository Structure
```
soc-toolkit-private/
├── toolkit_config.json          # CRITICAL - Master index
├── config/
│   ├── health_check.txt         # CRITICAL - Connection test
│   └── documentation_links.json # Links to your docs
├── templates/
│   └── (your .html template files)
├── queries/
│   └── (your .spl query files)  
└── scripts/
    └── (your .ps1 script files)
```

## 1. toolkit_config.json (REQUIRED)
```json
{
  "version": "2.0",
  "last_updated": "2025-08-19",
  "description": "SOC Analyst Productivity Toolkit - Hybrid GitHub Integration",
  "powershell_scripts": {
    "Network Analysis": {
      "file": "scripts/network_analysis.ps1",
      "description": "Analyze current network connections and identify suspicious activity",
      "category": "Network Security",
      "author": "SOC Team",
      "estimated_runtime": "30 seconds",
      "requires_elevation": false
    },
    "Event Log Analysis": {
      "file": "scripts/event_log_check.ps1", 
      "description": "Quick check of Windows security and system event logs",
      "category": "Log Analysis",
      "author": "SOC Team",
      "estimated_runtime": "45 seconds",
      "requires_elevation": false
    }
  },
  "incident_templates": {
    "Critical Security Incident": {
      "file": "templates/critical_incident.html",
      "description": "Executive notification for critical security incidents",
      "audience": "Executive Leadership",
      "urgency": "Critical"
    },
    "Security Alert Leadership": {
      "file": "templates/security_alert.html", 
      "description": "Management notification for security alerts",
      "audience": "Management Team",
      "urgency": "High"
    }
  },
  "splunk_queries": {
    "Failed Authentication Events": {
      "file": "queries/failed_logins.spl",
      "description": "Shows failed login attempts by source IP and username",
      "timeframe": "-4h@h",
      "category": "Security Investigation",
      "difficulty": "Basic"
    },
    "Malware Detection Events": {
      "file": "queries/malware_detection.spl",
      "description": "Shows antivirus detections and quarantine actions", 
      "timeframe": "-24h@h",
      "category": "Threat Detection",
      "difficulty": "Basic"
    }
  }
}
```

## 2. config/health_check.txt (REQUIRED)
```
OK
```

## 3. config/documentation_links.json (REQUIRED)
```json
{
  "SOC Confluence Space": {
    "url": "https://your-company.atlassian.net/wiki/spaces/SOC",
    "description": "Main SOC procedures and documentation",
    "category": "Documentation"
  },
  "Incident Response Playbooks": {
    "url": "https://your-company.atlassian.net/wiki/spaces/IR", 
    "description": "Detailed incident response procedures",
    "category": "Procedures"
  },
  "Security SharePoint Site": {
    "url": "https://your-company.sharepoint.com/sites/security",
    "description": "Security team collaboration site",
    "category": "Collaboration"
  },
  "Emergency Contact List": {
    "url": "https://your-company.sharepoint.com/sites/security/contacts",
    "description": "After-hours and escalation contacts",
    "category": "Contacts"
  }
}
```
