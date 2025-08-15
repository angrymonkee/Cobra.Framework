# Email Module Documentation

## Overview

The Email module is a standalone productivity module for the Cobra Framework that provides comprehensive email management and automation capabilities. It supports multiple email providers and includes advanced features like templates, AI integration, and caching.

**Version:** 1.0.0  
**Author:** angrymonkee  
**Created:** 2025-08-13  
**Type:** Standalone Module

## Files in this Directory

### Core Files

#### `Email.psm1`

The main PowerShell module file containing all email functionality.

**Key Functions:**

- `EmailDriver` - Main entry point for all email commands
- `Get-EmailInbox` - Retrieve and display emails from configured provider
- `Get-EmailOpen` - Open and view specific email by ID with full content
- `Send-Email` - Send new emails with support for templates and AI enhancement
- `Send-EmailReply` - Reply to emails with preview and confirmation
- `Send-EmailForward` - Forward emails to other recipients
- `Send-QuickEmail` - Send emails using predefined templates
- `Get-EmailTemplates` - List available email templates
- `Test-EmailConfiguration` - Validate module configuration
- `Start-EmailSetupWizard` - Interactive setup wizard for configuration

**Provider Support:**

- **Outlook** - Uses COM object integration (no setup required)
- **Microsoft Graph** - Office 365/Outlook.com via Azure app registration
- **Gmail API** - Google Workspace/Gmail via Google Cloud project
- **SMTP** - Generic SMTP server support (send-only)

**Features:**

- ✅ Cross-session email caching with JSON persistence
- ✅ Positional parameters (`email open 1` instead of `email open -ID 1`)
- ✅ Comprehensive logging with `Log-CobraActivity`
- ✅ AI-powered email composition and replies
- ✅ Template system with parameter substitution
- ✅ Safety confirmations for reply/forward operations
- ✅ Table-formatted email display with status indicators
- ✅ Email preview with smart truncation

#### `config.ps1`

Module configuration file defining settings, providers, templates, and integration points.

**Configuration Sections:**

- **Basic Information** - Name, version, author, capabilities
- **Provider Settings** - Configuration for Outlook, Graph, Gmail, SMTP
- **Behavior Settings** - Default signature, display preferences, keywords
- **Template Settings** - Built-in templates and template directory
- **Integration Points** - Dashboard, AI, and template integrations

**Environment Variables Used:**

- `GRAPH_CLIENT_ID` - Microsoft Graph application client ID
- `GRAPH_TENANT_ID` - Microsoft Graph tenant ID
- `GMAIL_CLIENT_ID` - Gmail API client ID
- `GMAIL_CLIENT_SECRET` - Gmail API client secret
- `SMTP_SERVER` - SMTP server hostname
- `SMTP_USERNAME` - SMTP authentication username
- `SMTP_PASSWORD` - SMTP authentication password

### Templates Directory

#### `templates/meeting-followup.txt`

Email template for meeting follow-ups with parameter substitution.

**Parameters:**

- `{name}` - Recipient name
- `{topic}` - Meeting topic
- `{action1}`, `{action2}`, `{action3}` - Action items
- `{sender}` - Sender name

**Usage:**

```powershell
email quick -Template meeting-followup -To "colleague@company.com" -Parameters @{
    name = "John"
    topic = "Project planning"
    action1 = "Review requirements"
    action2 = "Schedule next meeting"
    action3 = "Update timeline"
    sender = "Your Name"
}
```

## Email Provider Configuration

### Outlook (Recommended for Ease)

- **Setup:** No configuration required
- **Requirements:** Microsoft Outlook installed and configured
- **Capabilities:** Read, Send, Reply, Forward
- **Authentication:** Uses current Windows user credentials

### Microsoft Graph

- **Setup:** Azure App Registration required
- **Requirements:** Office 365 or Outlook.com account
- **Capabilities:** Read, Send, Reply, Forward
- **Authentication:** OAuth 2.0 with Azure AD

**Setup Steps:**

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to Azure Active Directory > App registrations
3. Create new registration or use existing
4. Add API permissions: Microsoft Graph > Mail.Read, Mail.Send, Mail.ReadWrite
5. Set environment variables: `GRAPH_CLIENT_ID`, `GRAPH_TENANT_ID`

### Gmail API

- **Setup:** Google Cloud Project required
- **Requirements:** Gmail or Google Workspace account
- **Capabilities:** Read, Send, Reply, Forward
- **Authentication:** OAuth 2.0 with Google

**Setup Steps:**

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create project and enable Gmail API
3. Create OAuth 2.0 credentials
4. Set authorized redirect URI: `http://localhost:8080`
5. Set environment variables: `GMAIL_CLIENT_ID`, `GMAIL_CLIENT_SECRET`

### SMTP

- **Setup:** SMTP server credentials required
- **Requirements:** SMTP server access
- **Capabilities:** Send only
- **Authentication:** Username/password

**Common SMTP Settings:**

- Gmail: `smtp.gmail.com:587` (use app password)
- Outlook: `smtp.office365.com:587`
- Yahoo: `smtp.mail.yahoo.com:587`

## Command Reference

### Core Commands

```powershell
# Get help
email help

# Show module status
email info

# Validate configuration
email config

# Run setup wizard
email setup
```

### Email Management

```powershell
# View inbox
email inbox                    # Show 10 recent emails
email inbox -Count 20          # Show 20 emails
email inbox -UnreadOnly        # Show only unread emails

# Open specific email
email open 1                   # Open email ID 1

# Reply to emails
email reply 1 -Body "Thanks!"         # Reply to email ID 1
email replyall 1 -Body "Thanks!"      # Reply all to email ID 1

# Forward emails
email forward 1 -To "user@example.com" -Body "FYI"

# Send new emails
email send -To "user@example.com" -Subject "Test" -Body "Message"
```

### Templates

```powershell
# List templates
email templates

# Send using template
email quick -Template "meeting-delay" -To "user@example.com"

# Send with parameters
email quick -Template "meeting-followup" -To "user@example.com" -Parameters @{
    name = "John"
    topic = "Planning"
}
```

## Built-in Templates

The module includes several built-in templates accessible via the `email quick` command:

| Template        | Description                | Usage                 |
| --------------- | -------------------------- | --------------------- |
| `quick-reply`   | Simple acknowledgment      | General responses     |
| `meeting-delay` | Meeting delay notification | Scheduling changes    |
| `code-review`   | Code review completion     | Development workflows |
| `deployment`    | Deployment notification    | DevOps updates        |
| `bug-report`    | Bug tracking update        | Issue management      |

## Features

### Email Caching

- Emails are cached globally for the current session
- Persistent JSON cache in temp directory for cross-session access
- Automatic cache loading when needed
- Enables back-to-back command execution

### AI Integration

When the Utils module is loaded, AI enhancement is available:

- `email send -UseAI` - AI-enhanced email composition
- `email reply -UseAI` - AI-generated replies
- Email summarization and priority detection

### Safety Features

- Preview and confirmation for reply/forward operations
- Detailed email previews before sending
- Cache validation and error handling
- Graceful fallbacks for provider failures

### Logging

All email operations are logged using `Log-CobraActivity`:

- Module initialization
- Inbox operations
- Email opens/views
- Send/reply/forward operations
- Configuration changes
- Template usage

### Status Indicators

- 📩 Unread email
- 📖 Read email
- ❗ High priority email
- 📧 Email operation in progress
- ✅ Successful operation
- ❌ Failed operation

## Error Handling

The module includes comprehensive error handling:

- Provider connectivity issues
- Missing email cache
- Invalid email IDs
- Configuration validation
- Template loading failures

## Integration Points

### Dashboard Integration

The module provides status information to the Cobra Dashboard:

- Provider status
- Connection health
- Unread email count
- High priority email count

### Template System

- File-based templates in `templates/` directory
- Built-in templates in configuration
- Parameter substitution with `{parameter}` syntax
- Support for custom template creation

### Standalone Architecture

- No repository dependency
- Self-contained configuration
- Modular provider system
- Independent operation

## Troubleshooting

### Common Issues

**Outlook COM Error:**

- Ensure Outlook is installed and configured
- Try opening Outlook manually first
- Check Windows user permissions

**Graph API Authentication:**

- Verify Azure app registration
- Check API permissions are granted
- Confirm environment variables are set

**Cache Issues:**

- Run `email inbox` to refresh cache
- Check temp directory permissions
- Clear cache file if corrupted

**Template Not Found:**

- Use `email templates` to list available templates
- Check template file exists in `templates/` directory
- Verify template name spelling

### Debug Commands

```powershell
# Test configuration
email config

# Check provider status
email info

# Reload module
Import-Module .\Email.psm1 -Force

# View activity log
Get-Content "d:\Code\Cobra.Framework\CobraActivity.log" | Select-Object -Last 10
```

## Development Notes

### Adding New Providers

1. Add provider configuration to `config.ps1`
2. Implement `Get-[Provider]Emails` function
3. Implement `Send-[Provider]Email` function
4. Add provider case to switch statements
5. Update configuration validation

### Adding New Templates

1. Create `.txt` file in `templates/` directory
2. Use `{parameter}` syntax for substitution
3. Templates are automatically discovered
4. Test with `email quick -Template [name]`

### Extending Functionality

- Provider functions are modular and extensible
- Configuration-driven behavior
- Logging integration with Cobra framework
- Error handling patterns established

## Dependencies

### Required

- PowerShell 5.1 or later
- Cobra Framework Core functions
- Windows (for Outlook COM integration)

### Optional

- Microsoft Outlook (for Outlook provider)
- Azure subscription (for Graph provider)
- Google Cloud project (for Gmail provider)
- SMTP server access (for SMTP provider)
- Utils module (for AI integration)

### Module Dependencies

- `Utils` module for AI integration (`AiExpander` function)
- Core Cobra functions (`Log-CobraActivity`, `Register-CobraStandaloneModule`)

---

_This documentation covers all files and functionality in the Email module directory. For general Cobra Framework documentation, see the main repository README._
