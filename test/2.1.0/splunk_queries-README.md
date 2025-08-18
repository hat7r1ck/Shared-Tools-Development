# Splunk Shared Queries System

Common SOC queries organized by category for quick access.

## Query Categories
- Security Incidents: Investigation and analysis queries
- System Monitoring: Performance and health queries  
- Threat Hunting: Advanced detection queries
- Compliance & Reporting: Audit and compliance queries
- Quick Investigations: Parameterized triage queries

## Configuration
Edit queries.json to:
- Add new queries
- Update Splunk server URL
- Modify default timeframes
- Add query categories

## Query Format
```json
"Query Name": {
"description": "What this query does",
"query": "index=* your search here",
"timeframe": "-4h@h",
"tags": ["tag1", "tag2"],
"requires_input": false
}

```

Updated: $(Get-Date -Format 'yyyy-MM-dd')
