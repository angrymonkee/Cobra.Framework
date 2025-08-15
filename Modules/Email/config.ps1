# Email Standalone Module Configuration
# This module does not depend on a repository

@{
    # Basic module information
    Name         = "Email"
    Description  = "Email management and automation module for senior engineers"
    Version      = "1.0.0"
    Author       = "dajon"
    ModuleType   = "Standalone"
    
    # Creation metadata
    Created      = "2025-08-13"
    LastModified = "2025-08-13"
    
    # Module capabilities
    Capabilities = @(
        "Configuration",
        "Status", 
        "Help",
        "EmailSending",
        "EmailReading",
        "Templates",
        "AIIntegration"
    )
    
    # Dependencies (other Cobra modules this module requires)
    Dependencies = @(
        "Utils"  # For AI integration and common utilities
    )
    
    # Module-specific configuration
    Settings     = @{
        # Email provider settings
        Provider             = "Outlook"  # Options: Outlook, Graph, Gmail, SMTP
        
        # Outlook COM settings (easiest - no setup required)
        Outlook              = @{
            RequireOutlookApp = $true
            DefaultProfile    = "Outlook"  # Default Outlook profile
        }
        
        # Microsoft Graph API settings
        Graph                = @{
            ClientId = $env:GRAPH_CLIENT_ID
            TenantId = $env:GRAPH_TENANT_ID
            Scopes   = @("Mail.Read", "Mail.Send", "Mail.ReadWrite")
        }
        
        # Gmail API settings (alternative)
        Gmail                = @{
            ClientId     = $env:GMAIL_CLIENT_ID
            ClientSecret = $env:GMAIL_CLIENT_SECRET
            RedirectUri  = "http://localhost:8080"
        }
        
        # SMTP settings (fallback)
        SMTP                 = @{
            Server   = $env:SMTP_SERVER
            Port     = 587
            UseSsl   = $true
            Username = $env:SMTP_USERNAME
            Password = $env:SMTP_PASSWORD
        }
        
        # Email behavior settings
        DefaultSignature     = "Best regards,`n$($env:USERNAME)"
        MaxEmailsToShow      = 10
        UnreadOnly           = $true
        HighPriorityKeywords = @("urgent", "critical", "asap", "emergency")
        
        # Template settings
        TemplateDirectory    = "$PSScriptRoot\templates"
        DefaultTemplates     = @{
            "quick-reply"   = "Thanks for your email. I'll get back to you soon."
            "meeting-delay" = "I'm running a few minutes late to our meeting. Starting shortly."
            "code-review"   = "Code review completed. Please see my feedback in the PR."
            "deployment"    = "Deployment to {environment} completed successfully."
            "bug-report"    = "Bug confirmed and logged. Tracking: {ticketId}. ETA: {eta}."
        }
    }
    
    # Command aliases (optional)  
    Aliases      = @{
        "send-email"   = "Send-Email"
        "read-email"   = "Get-EmailInbox"
        "email-status" = "Get-EmailStatus"
        "email status" = "Get-EmailStatus"
        "email config" = "Test-EmailConfiguration"
        "email help"   = "Show-EmailHelp"
    }
    
    # Integration points (optional)
    Integrations = @{
        # Dashboard integration
        Dashboard = @{
            Enabled        = $true
            ShowInStatus   = $true
            Priority       = "High"  # High priority for productivity
            StatusFunction = "Get-EmailDashboardStatus"
        }
        
        # AI integration  
        AI        = @{
            Enabled        = $true
            SupportedTypes = @(
                "email-compose",
                "email-reply",
                "email-summary",
                "email-priority"
            )
        }
        
        # Template integration
        Templates = @{
            Enabled           = $true
            TemplateDirectory = "$PSScriptRoot\templates"
        }
    }
}

