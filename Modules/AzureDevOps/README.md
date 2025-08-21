# Azure DevOps Module for Cobra Framework

A comprehensive, standalone PowerShell module that provides seamless integration with Azure DevOps services. This module offers a hierarchical command interface that simplifies Azure DevOps operations including work item management, build pipelines, pull requests, sprint tracking, and repository operations.

## Overview

The Azure DevOps module provides a clean, hierarchical command interface (`azdevops`) that adapts to both standalone and repository-aware contexts. It simplifies Azure DevOps operations through an intuitive command structure while maintaining full functionality for complex workflows.

### Key Features

- **🔧 Standalone Design**: No repository dependency - works anywhere
- **🚀 Hierarchical Commands**: Intuitive `azdevops <command> <subcommand>` structure
- **⚡ Context Awareness**: Automatically adapts to repository configuration
- **🔒 Type Safety**: Enum-based command routing with validation
- **📊 Comprehensive Coverage**: Work items, builds, PRs, sprints, repositories
- **🧪 Full Test Suite**: 45+ automated tests with 100% pass rate
- **📋 Template Generation**: One-command configuration setup
- **🔍 Rich Logging**: Detailed activity tracking and debugging
- **🎨 Rich UI**: Color-coded output with icons and progress indicators

## Architecture

### Module Structure

```powershell
Modules/AzureDevOps/
├── AzureDevOps.psm1          # Main module file (1,200+ lines)
├── config.ps1                # Module configuration & metadata
├── TestLogic.ps1             # Comprehensive test suite (500+ lines)
└── README.md                 # This documentation
```

### Core Components

```powershell
AzureDevOps.psm1
├── AzureDevOpsDriver          # Main command router and orchestrator
├── Show-AzureDevOpsHelp       # Unified help system
├── Get-AzureDevOpsConfigTemplate # Configuration template generator
├── Configuration Management    # Repository context detection and validation
│   ├── Get-AzureDevOpsConfig      # Context-aware config retrieval
│   ├── Test-AzureDevOpsConfig     # Configuration validation
│   └── Initialize-AzureDevOpsModule # Module initialization
├── Work Items Module          # Task, bug, and story management
│   ├── Get-MyWorkItems           # Query work items with filters
│   ├── New-WorkItem             # Create work items interactively
│   ├── Update-WorkItem          # Update work item fields
│   └── Get-WorkItemDetails      # Detailed work item information
├── Builds Module              # Pipeline execution and monitoring
│   ├── Get-BuildStatus          # Monitor build status with live updates
│   ├── Start-BuildPipeline      # Trigger pipeline runs
│   ├── Get-BuildDetails         # Detailed build information
│   └── Get-Pipelines           # List available pipelines
├── Pull Requests Module       # Code review and merge operations
│   ├── Get-PullRequests         # List and filter PRs
│   ├── New-PullRequest          # Create PRs with validation
│   ├── Get-PullRequestDetails   # Detailed PR information
│   └── Approve-PullRequest      # Approve PRs programmatically
├── Sprints Module             # Agile sprint tracking
│   ├── Get-CurrentSprint        # Current sprint information
│   ├── Get-SprintBacklog        # Sprint work items
│   └── Get-SprintProgress       # Progress tracking with burndown
├── Repository Module          # Repository management
│   └── Get-Repositories         # List available repositories
└── Utilities                  # Logging, error handling, and helpers
    ├── Write-AzureDevOpsLog     # Centralized logging
    ├── Command Validation       # Type-safe parameter checking
    └── Error Handling           # Robust error processing
```

### Command Structure

The module implements a hierarchical command interface using PowerShell enums for type safety:

```powershell
# Primary commands
enum AzureDevOpsCommand {
    help, config, status, template, workitems,
    builds, pipelines, repos, prs, sprints
}

# Secondary commands
enum AzureDevOpsSubCommand {
    help, list, new, update, delete, show, active,
    completed, assigned, created, recent, open,
    merge, approve, abandon, current, backlog, progress
}

# Usage: azdevops <command> [<subcommand>] [parameters]
```

### Design Patterns

#### 1. **Driver Pattern**

Central `AzureDevOpsDriver` function routes commands to appropriate handlers based on enum values.

#### 2. **Context Adaptation**

Automatically detects repository context via `GetCurrentAppConfig` and adapts behavior accordingly.

#### 3. **Configuration Template System**

Dynamic template generation with clipboard integration for easy setup.

#### 4. **Standalone Module Pattern**

No external dependencies on repository structure - can operate independently.

#### 5. **Comprehensive Error Handling**

Multi-layered error handling with meaningful user messages and detailed logging.

## Installation & Setup

### Prerequisites

#### Required Software

1. **PowerShell 5.1 or later**

   ```powershell
   # Check PowerShell version
   $PSVersionTable.PSVersion
   ```

2. **Azure CLI** - Required for Azure DevOps operations

   ```powershell
   # Install via winget (Windows)
   winget install Microsoft.AzureCLI

   # Install via Chocolatey
   choco install azure-cli

   # Install via PowerShell (cross-platform)
   Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'
   ```

3. **Azure DevOps Extension for Azure CLI**

   ```powershell
   # Install the extension
   az extension add --name azure-devops

   # Verify installation
   az extension list --query "[?name=='azure-devops']"
   ```

#### Authentication Setup

1. **Azure Authentication**

   ```powershell
   # Interactive login
   az login

   # Service principal login (for automation)
   az login --service-principal -u <app-id> -p <password> --tenant <tenant-id>

   # Verify authentication
   az account show
   ```

2. **Azure DevOps Authentication**

   ```powershell
   # Set default organization (optional but recommended)
   az devops configure --defaults organization=https://dev.azure.com/yourorg

   # Personal Access Token (PAT) login
   echo "your-pat-token" | az devops login --organization https://dev.azure.com/yourorg
   ```

3. **Verify Azure DevOps Connectivity**
   ```powershell
   # List projects (confirms connectivity)
   az devops project list
   ```

### Module Installation

The module is part of the Cobra Framework and auto-initializes when imported:

```powershell
# Import the module (if not auto-loaded)
Import-Module "path\to\Cobra.Framework\Modules\AzureDevOps\AzureDevOps.psm1"

# Verify module loaded successfully
Get-Module AzureDevOps
azdevops help
```

### Quick Start Configuration

#### Method 1: Interactive Configuration (Recommended)

1. **Generate Configuration Template**

   ```powershell
   # Navigate to your repository directory
   cd "C:\Code\YourRepository"

   # Generate template (copies to clipboard automatically)
   azdevops template -Organization "YourOrg" -Project "YourProject" -Repository "YourRepo"
   ```

2. **Add Configuration to Repository**

   ```powershell
   # Edit your repository's config.ps1 file
   # Paste the generated template into the configuration
   ```

3. **Verify Configuration**

   ```powershell
   # Test the configuration
   azdevops config

   # Check module status
   azdevops status
   ```

#### Method 2: Manual Configuration

Create or edit your repository's `config.ps1` file:

#### Sample Configuration

```powershell
# AzureDevOps Configuration
AzureDevOps = @{
    Organization  = "microsoft"
    Project       = "Xbox.Apps"
    Repository    = "Xbox.Apps.GamingApp"
    DefaultBranch = "main"

    Settings      = @{
        DefaultWorkItemType = "Task"
        ActiveStates       = @("New", "Active", "In Progress")
        CompletedStates    = @("Resolved", "Closed")

        PullRequest        = @{
            DefaultTargetBranch = "main"
            AutoComplete        = $false
            DeleteSourceBranch  = $true
            RequireWorkItemLink = $true
        }
    }
}
```

## Commands Reference

### Help & Configuration

| Command             | Description                             |
| ------------------- | --------------------------------------- |
| `azdevops help`     | Show comprehensive help information     |
| `azdevops config`   | Test and validate current configuration |
| `azdevops status`   | Show Azure DevOps connection status     |
| `azdevops template` | Generate configuration template         |

### Work Items

| Command                          | Description                        |
| -------------------------------- | ---------------------------------- |
| `azdevops workitems list`        | List your assigned work items      |
| `azdevops workitems new`         | Create new work item (interactive) |
| `azdevops workitems show <ID>`   | Show work item details             |
| `azdevops workitems update <ID>` | Update work item                   |
| `azdevops workitems active`      | Show active work items             |

### Builds & Pipelines

| Command                        | Description                  |
| ------------------------------ | ---------------------------- |
| `azdevops builds list`         | List recent builds           |
| `azdevops builds show <ID>`    | Show build details           |
| `azdevops builds recent`       | Show recent builds (default) |
| `azdevops pipelines list`      | List available pipelines     |
| `azdevops pipelines show <ID>` | Show pipeline details        |

### Pull Requests

| Command                     | Description                           |
| --------------------------- | ------------------------------------- |
| `azdevops prs list`         | List your pull requests               |
| `azdevops prs new`          | Create new pull request (interactive) |
| `azdevops prs show <ID>`    | Show pull request details             |
| `azdevops prs approve <ID>` | Approve pull request                  |

### Sprints & Planning

| Command                     | Description                     |
| --------------------------- | ------------------------------- |
| `azdevops sprints current`  | Show current sprint information |
| `azdevops sprints progress` | Show sprint progress            |
| `azdevops sprints backlog`  | Show sprint backlog             |

### Repository Operations

| Command               | Description                 |
| --------------------- | --------------------------- |
| `azdevops repos list` | List available repositories |

## Usage Examples & Workflows

### Quick Start Workflow

```powershell
# 1. Set up configuration
azdevops template -Organization "contoso" -Project "MyApp" -Repository "MyApp.Web"
# (Paste generated config into your repo's config.ps1)

# 2. Verify setup
azdevops config
azdevops status

# 3. Start working with Azure DevOps
azdevops workitems list
azdevops builds recent
azdevops prs list
```

### Template Generation Examples

```powershell
# Minimal template for quick setup
azdevops template -Minimal

# Full template with all parameters
azdevops template -Organization "microsoft" -Project "Xbox.Apps" -Repository "Xbox.Apps.GamingApp" -Team "Gaming.UI" -DefaultBranch "develop"

# Template with specific team and branch
azdevops template -Organization "contoso" -Project "MyApp" -Team "DevTeam" -DefaultBranch "develop"

# Generate without clipboard (output only)
azdevops template -Organization "contoso" -Project "MyApp" -NoClipboard
```

### Work Item Management Workflows

#### Daily Work Item Review

```powershell
# Check your active work items
azdevops workitems active

# Review work item details
azdevops workitems show 12345

# Update work item progress
azdevops workitems update 12345 -State "In Progress"

# List all your work items with expanded results
azdevops workitems list -Top 20
```

#### Bug Triage Workflow

```powershell
# List bugs assigned to you
azdevops workitems list -Type Bug -State New

# Create new bug report
azdevops workitems new -Type Bug -Title "Login page crashes on mobile" -Description "Detailed reproduction steps..."

# Assign bug to team member
azdevops workitems update 54321 -AssignedTo "developer@company.com" -State "Active"
```

#### Sprint Planning Workflow

```powershell
# Review current sprint
azdevops sprints current

# Check sprint backlog
azdevops sprints backlog

# Monitor sprint progress
azdevops sprints progress

# Create user stories for next sprint
azdevops workitems new -Type "User Story" -Title "As a user, I want to..." -Description "Acceptance criteria..."
```

### Build & Pipeline Monitoring

#### Continuous Integration Monitoring

```powershell
# Monitor recent builds
azdevops builds recent

# Watch specific pipeline builds
azdevops builds list -Pipeline "CI-Build" -Top 10

# Get detailed build information
azdevops builds show 67890

# Check build status for specific pipeline
azdevops builds list -Pipeline "Release-Pipeline"
```

#### Pipeline Management

```powershell
# List all available pipelines
azdevops pipelines list

# Trigger a specific pipeline (if supported)
azdevops pipelines show "Deployment Pipeline"
```

### Pull Request Workflows

#### Code Review Process

```powershell
# Check your active pull requests
azdevops prs active

# Review specific pull request
azdevops prs show 123

# List all pull requests for review
azdevops prs list -Top 15

# Approve a pull request
azdevops prs approve 123
```

#### Creating Pull Requests

```powershell
# Interactive PR creation
azdevops prs new
# (Follow prompts for source branch, target branch, title, description)

# Create PR with parameters
azdevops prs new -SourceBranch "feature/user-authentication" -TargetBranch "develop" -Title "Implement user authentication system" -Description "- Added login/logout functionality\n- Implemented JWT token handling\n- Added user session management"

# Create PR for current branch (requires Git integration)
azdevops prs new -TargetBranch "main" -Title "Fix critical security vulnerability"
```

### Repository Operations

```powershell
# List all repositories in the project
azdevops repos list

# Get repository information for context
azdevops repos list | Where-Object { $_.name -like "*API*" }
```

### Advanced Usage Patterns

#### Bulk Operations

```powershell
# Review all active work items and their status
azdevops workitems active | ForEach-Object {
    Write-Host "Work Item $($_.id): $($_.fields.'System.Title')"
    Write-Host "  State: $($_.fields.'System.State')"
    Write-Host "  Assigned: $($_.fields.'System.AssignedTo'.displayName)"
}

# Monitor multiple pipeline builds
$pipelines = @("CI-Build", "Security-Scan", "Integration-Tests")
$pipelines | ForEach-Object {
    Write-Host "`n=== $_ ===" -ForegroundColor Cyan
    azdevops builds list -Pipeline $_ -Top 3
}
```

#### Filtering and Searching

```powershell
# Find work items by state and type
azdevops workitems list -State "Active" -Type "Bug" -Top 10

# Search for work items assigned to specific user
azdevops workitems assigned -AssignedTo "john.doe@company.com"

# Filter builds by status
azdevops builds list -Status "failed" -Top 5

# List PRs by state
azdevops prs list -State "completed" -Top 10
```

#### Integration with Git Workflows

```powershell
# Common workflow: Feature branch to PR
git checkout -b feature/new-feature
# ... make changes, commit ...
git push origin feature/new-feature

# Create PR for the feature
azdevops prs new -SourceBranch "feature/new-feature" -TargetBranch "main" -Title "Add new feature" -Description "Implementation details..."

# Monitor build status for the PR
azdevops builds recent | Where-Object { $_.sourceBranch -eq "refs/heads/feature/new-feature" }
```

## Context Awareness

The module automatically detects repository context and adapts behavior accordingly:

### Repository Context

When run from a configured repository directory, the module:

- Uses repository-specific Azure DevOps configuration
- Filters results to the current repository
- Provides context-aware defaults

### Standalone Mode

When run from non-repository directories, the module:

- Focuses on template generation and general utilities
- Requires explicit parameter specification
- Provides organization-wide operations

## Configuration Options

### Template Parameters

| Parameter       | Description                    | Required |
| --------------- | ------------------------------ | -------- |
| `Organization`  | Azure DevOps organization name | No       |
| `Project`       | Project name                   | No       |
| `Repository`    | Repository name                | No       |
| `Team`          | Team name (optional)           | No       |
| `DefaultBranch` | Default branch name            | No       |
| `Minimal`       | Generate minimal configuration | No       |
| `NoClipboard`   | Skip clipboard integration     | No       |

### Advanced Settings

The full configuration template includes advanced settings for:

- Work item state mappings
- Pull request policies
- Default work item types
- Branch protection rules

## Error Handling

The module provides comprehensive error handling:

- **Configuration Errors**: Clear messages when Azure DevOps config is missing
- **Connectivity Issues**: Guidance for Azure CLI authentication problems
- **Parameter Validation**: Type-safe command parameters with enum validation
- **Azure DevOps Errors**: Wrapped Azure CLI errors with context

## Logging

All operations are logged for debugging and audit purposes:

- Commands executed
- Configuration changes
- Error conditions
- Performance metrics

Logs are written to the module's logging system and can be accessed through the Cobra.Framework logging infrastructure.

## Development

### Testing

Run the comprehensive test suite:

```powershell
.\TestLogic.ps1
```

Test specific functionality:

```powershell
# Test with mock mode (no external dependencies)
.\TestLogic.ps1 -MockMode

# Skip Azure CLI tests
.\TestLogic.ps1 -SkipAzureCliTests
```

### Extending

To add new commands:

1. Add command to `AzureDevOpsCommand` enum
2. Implement handler function
3. Add routing in `AzureDevOpsDriver` switch statement
4. Update help documentation
5. Add tests in `TestLogic.ps1`

## Dependencies

### Required

- **PowerShell 5.1+**: Core scripting platform
- **Azure CLI**: Azure DevOps connectivity

### Optional

- **Git**: Enhanced repository operations
- **VS Code**: Integrated development experience

## Troubleshooting

### Common Issues & Solutions

#### "Current repository does not support Azure DevOps integration"

**Cause**: Missing AzureDevOps configuration in repository config

**Solution**:

```powershell
# Generate and add configuration
azdevops template -Organization "your-org" -Project "your-project"
# Paste the output into your repository's config.ps1 file

# Verify the fix
azdevops config
```

#### "Azure CLI not authenticated" / "Please run 'az login'"

**Cause**: Azure CLI not logged in or expired credentials

**Solution**:

```powershell
# Interactive login
az login

# Verify authentication
az account show

# For Azure DevOps specifically
az devops configure --defaults organization=https://dev.azure.com/your-org

# Test connection
az devops project list
```

#### "Organization/Project not found"

**Cause**: Incorrect organization or project names in configuration

**Solution**:

```powershell
# Verify organization and project names in Azure DevOps portal
# Update your config.ps1 with correct names

# List available organizations
az account list-locations

# List projects in organization
az devops project list --organization https://dev.azure.com/your-org

# Update configuration with correct names
azdevops template -Organization "correct-org" -Project "correct-project"
```

#### "Template not copied to clipboard"

**Cause**: Clipboard access restrictions or PowerShell execution policy

**Solution**:

```powershell
# Use the no-clipboard flag
azdevops template -Organization "your-org" -Project "your-project" -NoClipboard

# Or manually copy the output

# Fix clipboard access (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### "Command not found" / "azdevops is not recognized"

**Cause**: Module not loaded or alias not registered

**Solution**:

```powershell
# Force reload the module
Import-Module "path\to\AzureDevOps\AzureDevOps.psm1" -Force

# Verify alias exists
Get-Alias azdevops

# Check module is loaded
Get-Module AzureDevOps
```

#### "Azure CLI extension 'azure-devops' is not installed"

**Cause**: Azure DevOps CLI extension missing

**Solution**:

```powershell
# Install the extension
az extension add --name azure-devops

# Verify installation
az extension list | grep azure-devops

# Update if needed
az extension update --name azure-devops
```

#### Work items/builds/PRs not showing

**Cause**: Configuration pointing to wrong project or no access permissions

**Solution**:

```powershell
# Verify your configuration
azdevops config

# Check your access to the project
az devops project show --project "your-project" --organization https://dev.azure.com/your-org

# Verify your user permissions in Azure DevOps portal
# Update PAT token if using personal access token authentication
```

### Debug Mode & Logging

#### Enable Verbose Logging

```powershell
# Enable detailed logging for troubleshooting
$VerbosePreference = "Continue"
azdevops workitems list -Verbose

# Reset to normal
$VerbosePreference = "SilentlyContinue"
```

#### Check Activity Logs

```powershell
# View recent Cobra Framework logs
Get-Content "CobraActivity.log" -Tail 50

# Filter for AzureDevOps entries
Get-Content "CobraActivity.log" | Select-String "Azure" -Context 2

# Monitor logs in real-time
Get-Content "CobraActivity.log" -Wait -Tail 10
```

#### Test Module Components

```powershell
# Test module import
Import-Module "path\to\AzureDevOps.psm1" -Force

# Test configuration validation
Test-AzureDevOpsConfig -ShowStatus

# Test individual functions
Get-AzureDevOpsConfig
Get-AzureDevOpsConfigTemplate -NoClipboard

# Run the comprehensive test suite
.\TestLogic.ps1 -MockMode
```

### Performance Troubleshooting

#### Slow Command Execution

```powershell
# Check Azure CLI performance
Measure-Command { az devops project list }

# Test network connectivity
Test-NetConnection dev.azure.com -Port 443

# Clear Azure CLI cache
az cache purge

# Use smaller result sets
azdevops workitems list -Top 5
azdevops builds list -Top 3
```

#### Memory Usage Issues

```powershell
# Monitor PowerShell memory usage
Get-Process powershell | Select-Object WorkingSet64

# Restart PowerShell session if needed
# Import module fresh
Import-Module "path\to\AzureDevOps.psm1" -Force
```

## Support & Diagnostics

### Self-Diagnosis Checklist

Run these commands in order to diagnose issues:

```powershell
# 1. Check PowerShell version
$PSVersionTable.PSVersion

# 2. Verify Azure CLI installation
az --version

# 3. Check Azure DevOps extension
az extension show --name azure-devops

# 4. Test Azure authentication
az account show

# 5. Test Azure DevOps connectivity
az devops project list

# 6. Verify module loading
Get-Module AzureDevOps
azdevops help

# 7. Test configuration
azdevops config

# 8. Check module status
azdevops status
```

### Getting Help

For issues and feature requests:

1. **Run diagnostics**: Use the self-diagnosis checklist above
2. **Check configuration**: `azdevops config`
3. **Review logs**: Check `CobraActivity.log` for error details
4. **Verify Azure CLI**: `az account show` and `az devops project list`
5. **Test connectivity**: `azdevops status`
6. **Run tests**: `.\TestLogic.ps1 -MockMode`

### Reporting Issues

When reporting issues, please include:

- PowerShell version (`$PSVersionTable.PSVersion`)
- Azure CLI version (`az --version`)
- Module configuration (sanitized, no credentials)
- Full error messages
- Steps to reproduce
- Expected vs actual behavior

## API Reference

### Core Driver Functions

#### `AzureDevOpsDriver`

Main entry point for all hierarchical commands.

**Syntax**:

```powershell
AzureDevOpsDriver [-Command] <AzureDevOpsCommand> [[-SubCommand] <AzureDevOpsSubCommand>]
    [-ID <Int32>] [-Top <Int32>] [-Title <String>] [-Description <String>]
    [-AssignedTo <String>] [-State <String>] [-Type <String>] [-Branch <String>]
    [-SourceBranch <String>] [-TargetBranch <String>] [-Pipeline <String>]
    [-ShowDetails] [-Organization <String>] [-Project <String>]
    [-Repository <String>] [-Team <String>] [-DefaultBranch <String>]
    [-Minimal] [-NoClipboard]
```

**Parameters**:

- `Command` - Primary command (help, config, workitems, builds, pipelines, repos, prs, sprints, template)
- `SubCommand` - Secondary command (list, new, show, update, active, etc.)
- `ID` - Item identifier for specific operations
- `Top` - Limit number of results (default: 10)
- `Title` - Work item or PR title
- `Description` - Item description
- `AssignedTo` - User email for assignments
- `State` - Filter by state (Active, Resolved, etc.)
- `Type` - Work item type (Bug, Task, User Story, etc.)
- `ShowDetails` - Include detailed information
- Template parameters for configuration generation

**Examples**:

```powershell
azdevops workitems list -Top 15
azdevops builds show 12345
azdevops template -Organization "contoso" -Project "MyApp"
```

### Configuration Functions

#### `Get-AzureDevOpsConfig`

Retrieves and validates Azure DevOps configuration for the current repository context.

**Syntax**:

```powershell
Get-AzureDevOpsConfig
```

**Returns**: Hashtable containing Azure DevOps configuration

**Throws**: Exception if no repository context or invalid configuration

**Example**:

```powershell
$config = Get-AzureDevOpsConfig
Write-Host "Organization: $($config.Organization)"
Write-Host "Project: $($config.Project)"
```

#### `Test-AzureDevOpsConfig`

Tests and validates the Azure DevOps configuration.

**Syntax**:

```powershell
Test-AzureDevOpsConfig [-ShowStatus]
```

**Parameters**:

- `ShowStatus` - Display detailed status information

**Returns**: Boolean indicating configuration validity

**Example**:

```powershell
if (Test-AzureDevOpsConfig) {
    Write-Host "Configuration is valid"
}
```

#### `Get-AzureDevOpsConfigTemplate`

Generates configuration template for copying to repository configs.

**Syntax**:

```powershell
Get-AzureDevOpsConfigTemplate [[-Organization] <String>] [[-Project] <String>]
    [[-Repository] <String>] [[-Team] <String>] [[-DefaultBranch] <String>]
    [-Minimal] [-NoClipboard]
```

**Parameters**:

- `Organization` - Azure DevOps organization name
- `Project` - Project name
- `Repository` - Repository name
- `Team` - Team name
- `DefaultBranch` - Default branch name
- `Minimal` - Generate minimal configuration
- `NoClipboard` - Skip clipboard copy

**Returns**: String containing PowerShell configuration template

### Work Item Functions

#### `Get-MyWorkItems`

Retrieves work items assigned to the current user.

**Syntax**:

```powershell
Get-MyWorkItems [[-State] <String>] [[-Top] <Int32>] [[-WorkItemTypes] <String[]>]
    [[-AssignedTo] <String>]
```

**Parameters**:

- `State` - Filter by work item state
- `Top` - Maximum number of results (default: 10)
- `WorkItemTypes` - Array of work item types to include
- `AssignedTo` - Filter by assignee email

**Returns**: Array of work item objects

**Example**:

```powershell
$activeItems = Get-MyWorkItems -State "Active" -Top 20
$bugs = Get-MyWorkItems -WorkItemTypes @("Bug") -Top 5
```

#### `New-WorkItem`

Creates a new work item in Azure DevOps.

**Syntax**:

```powershell
New-WorkItem [-Type] <String> [-Title] <String> [[-Description] <String>]
    [[-AssignedTo] <String>]
```

**Parameters**:

- `Type` - Work item type (required): Bug, Task, User Story, etc.
- `Title` - Work item title (required)
- `Description` - Work item description
- `AssignedTo` - Assignee email

**Returns**: Work item object if successful, null otherwise

**Example**:

```powershell
$workItem = New-WorkItem -Type "Bug" -Title "Fix login issue" -Description "Users cannot authenticate" -AssignedTo "dev@company.com"
```

#### `Update-WorkItem`

Updates an existing work item with new values.

**Syntax**:

```powershell
Update-WorkItem [-ID] <Int32> [[-Title] <String>] [[-Description] <String>]
    [[-AssignedTo] <String>] [[-State] <String>]
```

**Parameters**:

- `ID` - Work item ID (required)
- `Title` - New title
- `Description` - New description
- `AssignedTo` - New assignee
- `State` - New state

**Returns**: Updated work item object if successful

### Build & Pipeline Functions

#### `Get-BuildStatus`

Gets the status of recent builds in Azure DevOps.

**Syntax**:

```powershell
Get-BuildStatus [[-PipelineName] <String>] [[-Top] <Int32>]
    [[-Status] <String>] [-ShowDetails] [-Monitor]
```

**Parameters**:

- `PipelineName` - Filter by pipeline name
- `Top` - Maximum results (default: 10)
- `Status` - Filter by build status (inProgress, completed, etc.)
- `ShowDetails` - Include detailed information
- `Monitor` - Continuous monitoring mode

**Returns**: Array of build objects

**Example**:

```powershell
$recentBuilds = Get-BuildStatus -Top 5
$failedBuilds = Get-BuildStatus -Status "failed" -Top 3
```

#### `Start-BuildPipeline`

Starts a build pipeline in Azure DevOps.

**Syntax**:

```powershell
Start-BuildPipeline [-PipelineName] <String> [[-Branch] <String>]
    [[-Parameters] <Hashtable>] [-WaitForCompletion] [-ShowProgress]
```

**Parameters**:

- `PipelineName` - Pipeline to start (required)
- `Branch` - Source branch
- `Parameters` - Build parameters hashtable
- `WaitForCompletion` - Wait for build to finish
- `ShowProgress` - Show progress updates

**Returns**: Build object if successful

### Pull Request Functions

#### `Get-PullRequests`

Gets pull requests with optional filtering.

**Syntax**:

```powershell
Get-PullRequests [[-State] <String>] [[-Top] <Int32>]
```

**Parameters**:

- `State` - Filter by PR state (active, completed, abandoned)
- `Top` - Maximum results (default: 10)

**Returns**: Array of pull request objects

#### `New-PullRequest`

Creates a new pull request.

**Syntax**:

```powershell
New-PullRequest [-SourceBranch] <String> [-TargetBranch] <String>
    [-Title] <String> [[-Description] <String>]
```

**Parameters**:

- `SourceBranch` - Source branch (required)
- `TargetBranch` - Target branch (required)
- `Title` - PR title (required)
- `Description` - PR description

**Returns**: Pull request object if successful

### Sprint Functions

#### `Get-CurrentSprint`

Gets information about the current sprint.

**Syntax**:

```powershell
Get-CurrentSprint
```

**Returns**: Sprint object with current sprint information

#### `Get-SprintBacklog`

Gets work items in the sprint backlog.

**Syntax**:

```powershell
Get-SprintBacklog
```

**Returns**: Array of work items in current sprint

#### `Get-SprintProgress`

Gets current sprint progress and statistics.

**Syntax**:

```powershell
Get-SprintProgress [[-Team] <String>] [-ShowBurndown] [-ShowVelocity]
```

**Parameters**:

- `Team` - Specific team name
- `ShowBurndown` - Include burndown information
- `ShowVelocity` - Include velocity metrics

### Utility Functions

#### `Write-AzureDevOpsLog`

Centralized logging function for the module.

**Syntax**:

```powershell
Write-AzureDevOpsLog [[-Level] <String>] [-Message] <String>
```

**Parameters**:

- `Level` - Log level (INFO, WARN, ERROR)
- `Message` - Log message

#### `Get-AzureDevOpsStatus`

Shows current module status and information.

**Syntax**:

```powershell
Get-AzureDevOpsStatus
```

**Returns**: Displays module status information

## Version History & Changelog

### v1.0.0 (2025-08-19) - Initial Release

#### 🎉 Major Features

- **Hierarchical Command Interface**: Complete `azdevops <command> <subcommand>` system
- **Standalone Module Design**: No repository dependencies, works anywhere
- **Configuration Template System**: One-command setup with clipboard integration
- **Context-Aware Operations**: Automatically adapts to repository configuration

#### 🔧 Work Item Management

- List work items with filtering (state, type, assignee)
- Create work items interactively or programmatically
- Update work item fields (title, state, assignee, description)
- Show detailed work item information
- Active work item tracking

#### 🏗️ Build & Pipeline Operations

- Monitor recent builds with real-time status
- Filter builds by pipeline, status, and date
- Show detailed build information with logs
- List available pipelines
- Pipeline trigger support (where applicable)

#### 🔀 Pull Request Management

- List pull requests with state filtering
- Create pull requests with full parameter support
- Show detailed PR information
- Approve pull requests programmatically
- Active PR tracking

#### 🏃‍♂️ Sprint & Agile Support

- Current sprint information and timeline
- Sprint backlog with work item details
- Sprint progress tracking with completion metrics
- Multi-team support

#### 📊 Repository Operations

- List all project repositories
- Repository information and metadata

#### 🧪 Comprehensive Testing

- **45+ automated tests** with 100% pass rate target
- Mock mode for CI/CD environments
- Azure CLI integration testing
- Configuration validation testing
- Error scenario testing
- Performance and reliability testing

#### 🔍 Advanced Features

- **Rich Console Output**: Color-coded status, icons, progress indicators
- **Comprehensive Logging**: Activity tracking with multiple log levels
- **Error Handling**: Robust error detection and user-friendly messages
- **Type Safety**: Enum-based command validation
- **Clipboard Integration**: Automatic template copying
- **Context Detection**: Automatic repository configuration detection
- **Caching Support**: Result caching for improved performance

#### 🛠️ Technical Implementation

- **1,200+ lines** of PowerShell code
- **500+ lines** of comprehensive test suite
- **Enum-based command routing** for type safety
- **Azure CLI integration** for all Azure DevOps operations
- **PowerShell 5.1+** compatibility
- **Cross-platform support** via PowerShell Core

#### 📚 Documentation & Support

- **Comprehensive README** with architecture, usage, and troubleshooting
- **API Reference** with detailed function documentation
- **Usage Examples** covering common workflows
- **Troubleshooting Guide** with step-by-step solutions
- **Self-diagnosis tools** and health checks

### Features Summary

#### ✅ Implemented Features

- Clean hierarchical command interface (`azdevops <cmd> <subcmd>`)
- Repository context detection and adaptation
- Configuration template generation with customization options
- Comprehensive work item management (CRUD operations)
- Build and pipeline monitoring with real-time updates
- Pull request operations with full lifecycle support
- Sprint tracking and agile workflow support
- Extensive error handling with user-friendly messages
- Full test suite coverage with automated validation
- Clipboard integration for seamless setup
- Type-safe command parameters with enum validation
- Extensive logging and debugging support
- Rich console output with colors and formatting
- Context-aware help system
- Performance optimization with caching
- Azure CLI integration and authentication handling

#### 🔄 Module Architecture Benefits

- **Standalone Design**: Works independently, no repository coupling
- **Hierarchical Interface**: Intuitive command structure
- **Type Safety**: Enum-based validation prevents errors
- **Context Awareness**: Adapts behavior based on environment
- **Comprehensive Testing**: Ensures reliability and stability
- **Rich Documentation**: Detailed usage and API reference
- **Error Resilience**: Robust error handling and recovery
- **Performance Optimized**: Caching and efficient operations
- **Extensible Design**: Easy to add new commands and features
- **Integration Ready**: Works with Cobra Framework ecosystem

### Roadmap & Future Enhancements

Planned for future releases:

- Enhanced sprint burndown charts
- Work item template customization
- Bulk operations support
- Teams integration for notifications
- Advanced filtering and search
- Pipeline templates and management
- Release management integration
- Custom field support
- Automation workflows
- Performance dashboards
