# Cobra Framework

Cobra Framework is a modular PowerShell framework for managing multiple repositories and development workflows with advanced productivity features, including a context-aware dashboard for enhanced developer experience.

## Requirements

- **PowerShell 7.0 or higher** (for full Unicode support and modern features)
- Windows 10/11 or Windows Server 2019/2022
- Git (optional, for repository status features)

## Features

- **Context-Aware Dashboard** 🎯 - Interactive UI with real-time project status, Git information, and quick actions
- **Modular architecture** for easy extension and customization
- **Built-in repository management** with context-aware navigation
- **Custom utility scripts** with AI-powered assistance
- **Global configuration support** with secure environment management
- **Activity logging** with advanced search and management
- **Module registry browsing** for discovering and sharing modules
- **Rich output formatting** including markdown support
- **Template and snippet management** for code reuse
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
├── Core.ps1           # Core framework functionality
├── Utils/             # Custom utility scripts
├── sysconfig.ps1      # Global configuration file
└── Modules/           # Repository-specific modules
    └── Code/          # Example module for Code repository
        ├── Code.psm1  # Module implementation
        └── config.ps1 # Repository configuration
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
- **`ModuleRegistryLocation`**: Path to the registry where Cobra modules are stored for import.

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
- **`cobra modules`**: Manage Cobra modules.
  - **`add <name>`**: Create a new module with template files.
  - **`remove <name>`**: Remove an existing module.
  - **`edit <name>`**: Edit a module's configuration and script files.
  - **`import <name> <artifactPath>`**: Import a module from an artifact.
  - **`export <name> <artifactPath>`**: Export a module to an artifact.
  - **`registry <option>`**: Manage the module registry.
    - **`list`**: List all modules in the registry.
    - **`info <name>`**: Get detailed information about a module.
    - **`search <term>`**: Search for modules.
    - **`open`**: Open registry folder in explorer.
    - **`push <name>`**: Push a module to the registry.
    - **`pull <name>`**: Pull a module from the registry.
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

#### Utility Functions

The framework includes several built-in utility functions accessible from anywhere:

- **`CleanEventLog`**: Clear Windows event logs.
- **`DumpEventLog`**: Export Windows event logs.
- **`HostsFile`**: Open the hosts file with elevated privileges.
- **`AiExpander -Type <type> -AdditionalInfo <info>`**: AI-powered text generation with markdown output.
  - Types: `email`, `prompt`, `summarizetext`, `summarizetopic`, `brainstorm`, `expert`, `askme`, `faketool`, `extract`, `plan`
- **`Base64Decode -Base64String <string>`**: Decode base64 encoded strings.
- **`Browse-ModuleRegistry -Action <action>`**: Browse and explore the module registry.
  - Actions: `list`, `info`, `search`, `open`

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

## AI Integration

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
```

All AI responses are formatted in markdown for better readability and sharing.

## Module Registry

Browse and discover modules in your registry:

```powershell
cobra modules registry list                 # List all modules
cobra modules registry info "MyModule"      # Information about module
cobra modules registry search "MyModule"    # Search for module
cobra modules registry open                 # Open registry folder
```

## Recent Updates

### Context-Aware Dashboard (Latest)

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
