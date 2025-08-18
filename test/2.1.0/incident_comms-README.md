# Incident Communications System

Template-based email system for professional SOC communications.

## Templates Available
- Critical Security Incident (Executive notification)
- Security Alert Leadership (Management notification)  
- System Outage (Operations notification)
- Maintenance Notice (User notification)
- Incident Update (Stakeholder notification)

## Template Customization
1. Edit HTML files in templates folder
2. Use {{variable_name}} for dynamic content
3. Update recipient lists in incident_comm_email.ps1
4. Test with preview function before use

## Golden Standard Integration
To convert existing approved emails to templates:
1. Save email as HTML from Outlook
2. Replace actual values with {{placeholders}}
3. Update field definitions in script
4. Test thoroughly

Updated: $(Get-Date -Format 'yyyy-MM-dd')
