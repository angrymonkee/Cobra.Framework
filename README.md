# Cobra Framework

Cobra Framework is a modular PowerShell framework for managing multiple repositories and development workflows with advanced productivity features, including a context-aware dashboard, module marketplace, template system, job management, and comprehensive reporting tools for enhanced developer experience.

## Requirements

- **PowerShell 7.0 or higher** (for full Unicode support and modern features)
- Windows 10/11 or Windows Server 2019/2022
- Git (optional, for repository status features)

## Features

- **Context-Aware Dashboard** 🎯 - Interactive UI with real-time project status, Git information, and quick actions
- **Module Marketplace** 📦 - Publish, discover, install, and rate modules with version management and dependency resolution
- **Template & Snippet System** 📝 - Create, save, and share code templates and snippets for rapid development
- **Job Management** ⚡ - Schedule and manage automated tasks with event-based triggers
- **System Monitoring & Reporting** 📊 - Built-in system monitoring, performance tracking, and custom reports
- **Modular architecture** for easy extension and customization
- **Built-in repository management** with context-aware navigation
- **Custom utility scripts** with AI-powered assistance
- **Global configuration support** with secure environment management
- **Activity logging** with advanced search and management
- **Rich output formatting** including markdown support
- **Hotkey integration** for instant dashboard access (Ctrl+D)

## Installation

To install the Cobra Framework, run the following script:

```powershell
.\Install.ps1
```

This will add a reference to `CobraProfile.ps1` in your PowerShell profile, enabling the Cobra tools.

## Uninstallation

To uninstall the Cobra Framework, run the following script:

```powershell
.\Uninstall.ps1
```

This will remove the reference to `CobraProfile.ps1` from your PowerShell profile.

## Usage

After installation, you can start using Cobra Framework commands immediately:

```powershell
# Open the Context-Aware Dashboard
dash              # Quick dashboard view
dashi             # Interactive dashboard with hotkeys
cobra dashboard    # Framework integration
cobra dashboard -i # Interactive mode

# Navigate to a repository
repo <RepoName>

# View available modules
cobra modules

# Module Marketplace Commands
cobra modules publish <name>           # Publish module to marketplace
cobra modules search <term>            # Search modules by term, tags, or categories
cobra modules install <name> [version] # Install module with dependency resolution
cobra modules uninstall <name>         # Remove installed module
cobra modules rate <name> <1-5>        # Rate and review a module
cobra modules info <name>              # Get detailed module information

# Module Registry Management
cobra modules registry init            # Initialize module marketplace
cobra modules registry list            # List all available registry modules
cobra modules registry info <name>     # Get registry module information
cobra modules registry open            # Open registry folder in Explorer

# Template & Snippet Management
cobra templates                        # List available templates and snippets
cobra templates new <template> <name>  # Create new module from template
cobra templates snippet <name>         # Insert code snippet
cobra templates search <term>          # Search templates and snippets
cobra templates save <name> <type>     # Save current code as template
cobra templates wizard                  # Interactive template creation

# Job Management
cobra jobs                             # (Loads job management system)

# System Monitoring & Reports
dash                                   # System dashboard (quick view)
dashi                                  # Interactive system dashboard
SysInfo                               # Detailed system information
Utilization                           # System resource utilization
Procs                                 # Process monitoring

# Check system health
cobra health

# View and manage activity logs
cobra logs view -Lines 10
cobra logs search -SearchTerm "Build"
cobra logs clear

# Get help
cobra help
```

## Context-Aware Dashboard 🚀

The flagship feature of Cobra Framework is the Context-Aware Dashboard, providing real-time development insights:

### Dashboard Features

- **📍 Context Awareness** - Shows current location, Git branch, repository info, and status
- **📊 Status Monitoring** - Displays build/test results with timing information
- **⚡ Quick Actions** - Single-key access to common commands:
  - `[B]uild` - Build current project
  - `[T]est` - Run tests
  - `[R]un` - Run application
  - `[P]R Prep` - Prepare for pull request
  - `[A]uth` - Authenticate
  - `[S]etup` - Setup project
  - `[I]nfo` - Show project info
  - `[L]ogs` - View activity logs
  - `[M]odules` - Manage modules
  - `[G]it` - Git status
  - `[H]elp` - Show help
- **📝 Recent Activity** - Shows last 5 framework activities
- **🔍 Log Management** - Integrated log viewing and searching
- **⌨️ Hotkey Access** - Press `Ctrl+D` from anywhere to open dashboard

### Dashboard Usage Examples

```powershell
# Quick dashboard view
dash

# Interactive dashboard with hotkeys
dashi

# Framework integration
cobra dashboard -i

# Open with hotkey (when available)
# Press Ctrl+D from any PowerShell prompt
```

## Structure

```text
Cobra.Framework/
├── Core.ps1                    # Core framework functionality
├── CobraProfile.ps1            # Main profile loader and command dispatcher
├── CobraDashboard.ps1          # Context-aware dashboard system
├── ModuleManagement.ps1        # Module marketplace and registry management
├── TemplatesManagement.ps1     # Template and snippet system
├── JobManagement.ps1           # Automated job scheduling and management
├── Report_Scripts.ps1          # System monitoring and reporting tools
├── DevCommands.ps1             # Development workflow commands
├── GoCommands.ps1              # Navigation and location management
├── sysconfig.ps1               # Global configuration file
├── Utils/                      # Custom utility scripts
│   ├── CommonUtilsModule.psm1  # Common utilities and helpers
│   └── ExperimentalUtils.psm1  # Experimental features and tools
├── Modules/                    # Repository-specific modules
│   ├── Code/                   # Example module for Code repository
│   ├── Anaconda/               # Data science and Python tools
│   ├── GRTS/                   # Gaming runtime testing system
│   ├── Garrison/               # Security and compliance tools
│   └── OpenAI/                 # AI integration and automation
├── Templates/                  # Code templates and snippets
│   ├── code-snippets/          # Reusable code snippets
│   ├── function-snippets/      # Function templates
│   ├── module-templates/       # Module creation templates
│   └── personal/               # Personal template collection
├── Jobs/                       # Background job definitions
│   └── CodeValidationJobs.psm1 # Code validation automation
├── Report/                     # Monitoring and reporting modules
│   ├── ResourceMonitoring.psm1 # System resource tracking
│   ├── SystemMonitoring.psm1   # System health monitoring
│   └── Utilities.psm1          # Reporting utilities
└── CobraModuleRegistry/        # Local module marketplace
    ├── packages/              # Versioned module packages (*.zip)
    ├── metadata/              # Module metadata (including version-specific)
    └── cache/                 # Installation cache
```

## Global Configuration

The `sysconfig.ps1` file is the global configuration file for the Cobra Framework. It defines key settings and environment variables required for the framework to function properly.

### Example Configuration

```powershell
# filepath: d:\Code\Cobra.Framework\sysconfig.ps1
@{
    CobraRoot = "C:\Path\To\Cobra\Framework"
    CodeRepo  = "C:\Path\To\Repositories"
    ModuleRegistryLocation = "C:\Path\To\ModuleRegistry"
}
```

### Key Properties

- **`CobraRoot`**: Specifies the root directory of the Cobra Framework.
- **`CodeRepo`**: Defines the root directory where all repositories are stored.
- **`ModuleRegistryLocation`**: Path to the registry where Cobra modules are stored for import and sharing.

### Configuration Usage

The global configuration file is automatically imported when the framework is loaded. To modify the configuration:

Run...

```powershell
cobra env init
```

or manually...

1. Open the `sysconfig.ps1` file in the root directory.
2. Update the values as needed.
3. Reload the framework to apply the changes.

## Module Marketplace 🛒

The Cobra Framework includes a comprehensive module marketplace system for sharing and discovering modules with advanced features:

### Key Marketplace Features

- **Rich Metadata System** - Comprehensive module information including dependencies, tags, categories, and ratings
- **Version Management** - Support for multiple module versions with automatic dependency resolution
- **Rating & Review System** - Community-driven module ratings and reviews (1-5 stars)
- **Advanced Search** - Search by name, tags, categories, ratings, and content
- **Dependency Resolution** - Automatic installation of module dependencies
- **Central Registry Database** - Structured JSON database for efficient module discovery

### Registry Structure

The module marketplace uses a structured 3-directory layout:

```text
CobraModuleRegistry/
├── registry.json          # Central metadata database
├── packages/              # Versioned module packages (*.zip)
├── metadata/              # Version-specific metadata storage
│   └── ModuleName/        # Module-specific metadata
│       ├── 1.0.0/         # Version-specific metadata
│       └── 1.1.0/         # Multiple versions supported
└── cache/                 # Installation and processing cache
```

### Publishing Modules

```powershell
# Publish a module to the marketplace
cobra modules publish MyModule

# Interactive prompts will collect:
# - Version number (semantic versioning)
# - Description and detailed information
# - Tags (comma-separated for discovery)
# - Categories (development, automation, etc.)
# - Dependencies (automatic resolution)
# - License and repository information
```

### Installing Modules

```powershell
# Install latest version with automatic dependency resolution
cobra modules install ModuleName

# Install specific version
cobra modules install ModuleName 1.2.0

# View dependency information before installing
cobra modules info ModuleName  # Shows dependencies and compatibility

# Update existing module to latest version
cobra modules update ModuleName

# List installed modules
cobra modules list
```

### Module Discovery

```powershell
# Search all modules in registry
cobra modules search

# Search by term (searches name, description, tags)
cobra modules search "development"

# Advanced search with filters
cobra modules search -Tags "automation,powershell" -MinRating 4

# Browse by categories
cobra modules registry list  # Shows all modules with categories

# Get comprehensive module information
cobra modules info ModuleName  # Includes ratings, dependencies, versions, install count
```

### Rating and Reviews

```powershell
# Rate a module (1-5 stars) with optional review comment
cobra modules rate ModuleName 5 "Excellent module! Great automation features."

# Rate without comment
cobra modules rate ModuleName 4

# View comprehensive ratings and reviews
cobra modules info ModuleName  # Shows average rating, review count, recent comments

# Search modules by minimum rating
cobra modules search -MinRating 4  # Only show highly-rated modules
```

### Registry Management

```powershell
# Initialize the module marketplace (first-time setup)
cobra modules registry init  # Creates directory structure and registry.json database

# List all modules in registry with metadata
cobra modules registry list

# Get detailed registry information about a module
cobra modules registry info ModuleName

# Search the registry database
cobra modules registry search "automation"

# Open registry folder in File Explorer
cobra modules registry open

# View registry statistics and health
cobra modules registry status  # Shows module count, categories, database info
```

### Registry Database

The marketplace uses a central `registry.json` database containing:

- **Module Metadata** - All versions, descriptions, tags, categories for each module
- **Community Data** - Ratings, reviews, install counts, and usage statistics
- **Dependency Maps** - Module relationships and compatibility information
- **Categories & Tags** - Organized discovery and browsing capabilities
- **Featured Modules** - Highlighted and recommended modules
- **Version History** - Complete versioning information with release notes

## Template & Snippet System 📝

Create, manage, and share code templates and snippets:

### Using Templates

```powershell
# View available templates
cobra templates

# Create new module from template
cobra templates new basic-module MyNewModule

# Use interactive template wizard
cobra templates wizard

# Search templates
cobra templates search "azure"
```

### Managing Snippets

```powershell
# Insert a code snippet
cobra templates snippet error-handling

# Save current code as template
cobra templates save MyTemplate module -SourcePath "C:\MyCode"

# Search available snippets
cobra templates search "logging"
```

### Template Types

- **Module Templates**: Complete module structures with configuration files
- **Function Snippets**: Reusable PowerShell functions
- **Code Snippets**: Common code patterns and utilities
- **Personal Templates**: Custom templates for individual workflows

## Job Management ⚡

Schedule and manage automated tasks:

```powershell
# Load job management system
cobra jobs

# Jobs are defined in Jobs/ directory
# - CodeValidationJobs.psm1: Automated code validation
# - Custom job scripts can be added
```

## Adding a New Repository Module

To add a new repository module to the framework:

```powershell
cobra modules add <ModuleName>
```

or manually...

1. Create a new directory in `Modules/` with your module name.
2. Create two files:
   - `[ModuleName].psm1`: Contains the module implementation.
   - `config.ps1`: Contains the module configuration.

### Example Module Structure

```powershell
# Modules/YourRepo/config.ps1
@{
    Name = "YourRepo"
    Repo = $env:YOUR_REPO_PATH
    AuthMethod = "Auth-YourRepo"
    SetupMethod = "Setup-YourRepo"
    BuildMethod = "Build-YourRepo"
    TestMethod = "Test-YourRepo"
    RunMethod = "Run-YourRepo"
    DevMethod = "Dev-YourRepo"
    ReviewPullRequests = "Review-YourRepoPullRequests"
    OpenPullRequest = "Open-YourRepoPullRequestById"
    GoLocations = @{
        # Add your repository-specific locations
    }
}

# Modules/YourRepo/YourRepo.psm1
function Initialize-YourRepoModule {
    [CmdletBinding()]
    param()

    $config = . "$PSScriptRoot/config.ps1"
    Register-CobraRepository -Name "YourRepo" -Description "YourDescription" -Config $config
}

# Add your repository-specific functions
function Auth-YourRepo {
    # Implementation
}

# Export your functions
Export-ModuleMember -Function Initialize-YourRepoModule, Auth-YourRepo, ...
```

### Available Commands

#### Navigation Commands

- **`repo [name]`**: Navigate to a repository and load its configuration.
- **`go [name]`**: Navigate to predefined tasks or locations.

#### Developer Commands

- **`AuthApp`**: Authenticate with the current repository.
- **`SetupApp`**: Set up the current repository.
- **`BuildApp [buildType]`**: Build the current repository (supports Build, Rebuild, BuildAll).
- **`TestApp`**: Test the current repository.
- **`RunApp`**: Run the current repository.
- **`DevEnv`**: Start the development environment.
- **`pr`**: Run pre-pull request preparation steps (build, lint, and test).
- **`viewPRs`**: View and open assigned pull requests.
- **`ReviewPullRequests`**: Review pull requests for the current repository.
- **`OpenPullRequest`**: Open a specific pull request by ID.

#### Cobra Framework Commands

- **`cobra help`**: Display comprehensive help information.
- **`cobra dashboard [-i]`**: Open the Context-Aware Dashboard.
  - **`-i`**: Interactive mode with hotkey actions.

**Module Marketplace:**

- **`cobra modules publish <name>`**: Publish a module to the marketplace with interactive metadata collection.
- **`cobra modules search <term>`**: Search modules by term, tags, or categories.
- **`cobra modules install <name> [version]`**: Install module with automatic dependency resolution.
- **`cobra modules uninstall <name>`**: Remove an installed module.
- **`cobra modules rate <name> <1-5> [comment]`**: Rate and review a module.
- **`cobra modules info <name>`**: Get detailed module information including ratings and dependencies.
- **`cobra modules list`**: List locally installed modules.

**Module Registry Management:**

- **`cobra modules registry init`**: Initialize the module marketplace database.
- **`cobra modules registry list`**: List all modules in the registry.
- **`cobra modules registry info <name>`**: Get detailed registry information about a module.
- **`cobra modules registry open`**: Open registry folder in Explorer.

**Template & Snippet Management:**

- **`cobra templates`**: List available templates and snippets.
- **`cobra templates new <template> <name>`**: Create new module from template.
- **`cobra templates snippet <name>`**: Insert a code snippet.
- **`cobra templates search <term>`**: Search templates and snippets.
- **`cobra templates save <name> <type>`**: Save current code as template.
- **`cobra templates wizard`**: Interactive template creation wizard.
- **`cobra templates publish <name>`**: Publish template to shared collection.
- **`cobra templates import <name>`**: Import template from shared collection.

**System Management:**

- **`cobra logs`**: Manage and view activity logs.
  - **`view [lines]`**: View the last N log entries (default: 50).
  - **`search <term>`**: Search for specific entries in the log.
  - **`clear`**: Clear the activity log (creates backup).
- **`cobra env`**: Environment management.
  - **`init`**: Initialize environment variables from configuration.
  - **`(no args)`**: Display current environment configuration.
- **`cobra go`**: Manage "Go" locations.
  - **`add <name> <description> <url>`**: Add a new "Go" location.
  - **`remove <name>`**: Remove an existing "Go" location.
  - **`update <name> <description> <url>`**: Update an existing "Go" location.
- **`cobra utils`**: Display available utility functions.
- **`cobra health [target]`**: Run health checks for modules and repositories.

#### Dashboard Aliases

Quick access aliases for the Context-Aware Dashboard:

- **`dash`**: Open the dashboard in view mode.
- **`dashi`**: Open the dashboard in interactive mode.

**Utility Functions:**

The framework includes several built-in utility functions accessible from anywhere:

- **`CleanEventLog`**: Clear Windows event logs.
- **`DumpEventLog`**: Export Windows event logs.
- **`HostsFile`**: Open the hosts file with elevated privileges.
- **`AiExpander -Type <type> -AdditionalInfo <info>`**: AI-powered text generation with markdown output.
  - Types: `email`, `prompt`, `summarizetext`, `summarizetopic`, `brainstorm`, `expert`, `askme`, `faketool`, `extract`, `plan`
- **`Base64Decode -Base64String <string>`**: Decode base64 encoded strings.
- **`Browse-ModuleRegistry -Action <action>`**: Browse and explore the module registry.
  - Actions: `list`, `info`, `search`, `open`

**System Monitoring & Reporting:**

- **`dash`**: Open the system dashboard in view mode (alias for Show-CobraDashboard).
- **`dashi`**: Open the system dashboard in interactive mode.
- **`SysInfo`**: Display detailed system information and health status.
- **`Utilization`**: Show system resource utilization (CPU, memory, disk).
- **`Procs`**: Display running process information with resource usage.

## Activity Logging

Cobra Framework automatically logs user activities to `CobraActivity.log` for debugging and usage tracking. The enhanced logging system provides:

### Log Management Features

- **Real-time Activity Tracking** - All framework operations are logged with timestamps
- **Advanced Search** - Find specific activities with term highlighting
- **Integrated Dashboard View** - Recent activities displayed in the Context-Aware Dashboard
- **Log Rotation** - Automatic backup when clearing logs
- **Formatted Output** - Color-coded timestamps and messages for easy reading

### Log Management Commands

```powershell
# View recent logs
cobra logs view 100

# Search for specific activities
cobra logs search "Build"
cobra logs search "Dashboard"

# Clear logs (creates backup)
cobra logs clear
```

## Module Marketplace Examples 🛒

### Publishing a Module

```powershell
# Navigate to your module directory
repo MyProject

# Publish with comprehensive interactive prompts
cobra modules publish MyAwesomeModule

# Example interactive session:
# Version (1.0.0): 1.2.0
# Description: Advanced automation tools for PowerShell development
# Tags: automation,powershell,tools,development
# Categories: automation,development,productivity
# Dependencies (optional): GitUtils,CommonUtils
# License (MIT): MIT
# Homepage: https://github.com/user/awesome-module
# Repository: https://github.com/user/awesome-module.git

# The system will:
# - Create versioned package (MyAwesomeModule-1.2.0.zip)
# - Store metadata in metadata/MyAwesomeModule/1.2.0/
# - Update central registry.json database
# - Enable discovery through search and browsing
```

### Installing and Managing Modules

```powershell
# Search for modules with advanced filtering
cobra modules search "automation" -Tags "powershell" -MinRating 3

# View detailed information before installing
cobra modules info MyAwesomeModule
# Shows: versions, dependencies, ratings, reviews, install count, license

# Install latest version (resolves dependencies automatically)
cobra modules install MyAwesomeModule

# Install specific version with dependency checking
cobra modules install MyAwesomeModule 1.1.0

# Update to latest version
cobra modules update MyAwesomeModule

# List all installed modules with versions
cobra modules list

# Uninstall module (checks for dependents)
cobra modules uninstall MyAwesomeModule

# Rate and review with detailed feedback
cobra modules rate MyAwesomeModule 5 "Excellent automation tools! Saved hours of work. Great documentation and examples."

# Get comprehensive module information including community feedback
cobra modules info MyAwesomeModule
# Displays: description, versions, dependencies, average rating (4.8/5),
#          recent reviews, install count (342), license, repository links
```

### Managing Your Registry

```powershell
# Initialize marketplace (first-time setup - creates directory structure)
cobra modules registry init

# List all available modules with categories and ratings
cobra modules registry list

# Search registry database with filters
cobra modules search -Tags "development,git" -MinRating 4
cobra modules search "azure" -Categories "cloud,deployment"

# Get registry statistics and health information
cobra modules registry status
# Shows: total modules (45), categories (12), average rating (4.2/5),
#        registry size (234 MB), last sync time

# Browse categories and featured modules
cobra modules browse -Category "automation"
cobra modules featured  # Show featured/recommended modules

# Open registry folder for manual inspection
cobra modules registry open

# Backup and restore registry
cobra modules registry backup  # Creates timestamped backup
cobra modules registry restore <backup-file>  # Restore from backup
```

## Template System Examples 📝

### Using Code Templates

```powershell
# View available templates
cobra templates

# Create new module from template
cobra templates new basic-module MyNewProject

# Use interactive wizard
cobra templates wizard

# Insert common code snippets
cobra templates snippet error-handling
cobra templates snippet logging
```

### Managing Templates

```powershell
# Save current project as template
cobra templates save MyProjectTemplate module -SourcePath "C:\MyProject"

# Search for specific templates
cobra templates search "azure"
cobra templates search "function"

# Publish template for team sharing
cobra templates publish MyProjectTemplate
```

## System Monitoring Examples 📊

### Quick System Overview

```powershell
# System dashboard (quick view)
dash

# Interactive dashboard with real-time updates
dashi

# Detailed system information
SysInfo

# Resource utilization monitoring
Utilization

# Process monitoring
Procs
```

### Advanced Monitoring

```powershell
# Load job management for scheduled monitoring
cobra jobs

# Custom reporting utilities available in Report/ modules:
# - ResourceMonitoring.psm1: Track resource usage over time
# - SystemMonitoring.psm1: Monitor system health metrics
# - Utilities.psm1: Reporting helper functions
```

## AI Integration Examples 🤖

The framework includes AI-powered utilities through the `AiExpander` function:

```powershell
# Generate professional emails
AiExpander -Type email -AdditionalInfo "Meeting request for project review"

# Brainstorm ideas
AiExpander -Type brainstorm -AdditionalInfo "PowerShell automation improvements"

# Expert-level responses
AiExpander -Type expert -AdditionalInfo "PowerShell:How to optimize script performance"

# Create action plans
AiExpander -Type plan -AdditionalInfo "Learn Docker:Intermediate PowerShell:3 months"

# Summarize text or topics
AiExpander -Type summarizetext -AdditionalInfo "Your text content here"
```

All AI responses are formatted in markdown for better readability and sharing.

## Module Registry

The enhanced module registry provides comprehensive module management with rich metadata and community features:

```powershell
# Registry Management
cobra modules registry init                      # Initialize marketplace with database
cobra modules registry list                     # List all modules with metadata
cobra modules registry info "MyModule"          # Detailed module information
cobra modules registry search "MyModule"        # Search with advanced filtering
cobra modules registry open                     # Open registry folder in Explorer
cobra modules registry status                   # Registry health and statistics

# Module Discovery & Installation
cobra modules search "automation" -MinRating 4  # Advanced search with rating filter
cobra modules info "MyModule"                   # Complete module details and reviews
cobra modules install "MyModule" 1.2.0          # Install specific version with dependencies
cobra modules rate "MyModule" 5 "Great tool!"   # Rate and review modules

# Database Features
# - Central registry.json with structured metadata
# - Version-specific metadata storage (metadata/Module/Version/)
# - Community ratings and reviews system
# - Dependency resolution and compatibility tracking
# - Installation statistics and usage analytics
```

## Recent Updates

### Module Marketplace Phase 1 (Latest)

- **Enhanced Registry Structure** - Streamlined 3-directory architecture (packages/, metadata/, cache/)
- **Version-Specific Metadata** - Support for multiple module versions with dedicated metadata storage
- **Central Registry Database** - Structured JSON database for efficient module discovery and management
- **Advanced Search & Filtering** - Search by name, tags, categories, ratings, and content with filtering options
- **Community Rating System** - 1-5 star ratings with review comments and average scoring
- **Automatic Dependency Resolution** - Smart installation with dependency checking and resolution
- **Comprehensive Module Info** - Rich metadata including licenses, repositories, install counts, and community feedback
- **Registry Management Tools** - Initialize, backup, restore, and health monitoring capabilities

### Context-Aware Dashboard

- **Interactive TUI Dashboard** with real-time context detection and status monitoring
- **Hotkey Integration** - Ctrl+D for instant dashboard access from anywhere
- **Quick Actions** - Single-key access to build, test, run, and other common operations
- **Git Integration** - Live branch status and change tracking
- **Enhanced Log Management** - Advanced search, filtering, and integrated dashboard view
- **Dashboard Aliases** - `cdash` and `cdashi` for quick access

## Contributing

Contributions are welcome! Add new utility scripts to the `Utils` folder or extend the framework by creating new modules.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).
