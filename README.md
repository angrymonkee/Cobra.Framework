# Cobra Framework

Cobra Framework is a modular PowerShell framework for managing multiple repositories and development workflows with advanced productivity features.

## Features

- **Modular architecture** for easy extension and customization
- **Built-in repository management** with context-aware navigation
- **Custom utility scripts** with AI-powered assistance
- **Global configuration support** with secure environment management
- **Activity logging** for tracking usage and debugging
- **Module registry browsing** for discovering and sharing modules
- **Rich output formatting** including markdown support
- **Template and snippet management** for code reuse

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
# Navigate to a repository
repo <RepoName>

# View available modules
cobra modules

# Check system health
cobra health

# View recent activity
cobra logs view

# Get help
cobra help
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

Cobra Framework automatically logs user activities to `CobraActivity.log` for debugging and usage tracking. You can manage these logs using:

```powershell
cobra logs view 100        # View last 100 entries
cobra logs search "GRTS"   # Search for specific terms
cobra logs clear           # Clear logs (creates backup)
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
Browse-ModuleRegistry                    # List all modules
Browse-ModuleRegistry -Action info -ModuleName "MyModule.zip"
Browse-ModuleRegistry -Action search -SearchTerm "GRTS"
Browse-ModuleRegistry -Action open      # Open registry folder
```

## Recent Updates

- Added comprehensive activity logging with search and management capabilities
- Integrated AI-powered text generation with markdown output
- Enhanced module registry browsing and discovery
- Improved error handling and operator precedence fixes
- Added Base64 decoding utilities
- Enhanced build system with multiple build types support
- Expanded utility functions for system administration

## Roadmap

Future enhancements planned for Cobra Framework:

- Interactive CLI with fuzzy finder navigation
- Context-aware command suggestions
- Template and snippet management system
- Task automation and scheduling
- Integration with external tools (Git, Azure DevOps, Slack)
- Cross-platform support for Linux/macOS
- Self-updating mechanism with version management

## Contributing

Contributions are welcome! Add new utility scripts to the `Utils` folder or extend the framework by creating new modules.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).
