# Cobra Framework

Cobra Framework is a modular PowerShell framework for managing multiple repositories and development workflows.

## Features

- Modular architecture for easy extension
- Built-in repository management
- Custom utility scripts
- Global configuration support

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

```bash
# Usage instructions
```

## Structure

```
Cobra.Framework/
├── Core.ps1           # Core framework functionality
├── Utils/             # Custom utility scripts
├── config.ps1         # Global configuration file
└── Modules/           # Repository-specific modules
    └── Code/          # Example module for Code repository
        ├── Code.psm1  # Module implementation
        └── config.ps1 # Repository configuration
```

## Global Configuration

The `config.ps1` file is the global configuration file for the Cobra Framework. It defines key settings and environment variables required for the framework to function properly.

### Example Configuration

```powershell
# filepath: d:\Code\Cobra.Framework\config.ps1
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

### Usage

The global configuration file is automatically imported when the framework is loaded. To modify the configuration:

1. Open the `config.ps1` file in the root directory.
2. Update the values as needed.
3. Reload the framework to apply the changes.

## Adding a New Repository

To add a new repository to the framework:

1. Create a new directory in `Modules/` with your repository name.
2. Create two files:
   - `[RepoName].psm1`: Contains the module implementation.
   - `config.ps1`: Contains the repository configuration.

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

## Available Commands

### Navigation Commands

- **`repo [name]`**: Navigate to a repository.
- **`go [name]`**: Navigate to predefined tasks or locations.

### Developer Commands

- **`AuthApp`**: Authenticate with the current repository.
- **`SetupApp`**: Set up the current repository.
- **`BuildApp`**: Build the current repository.
- **`TestApp`**: Test the current repository.
- **`RunApp`**: Run the current repository.
- **`DevEnv`**: Start the development environment.
- **`pr`**: Run pre-pull request preparation steps (build, lint, and test).
- **`viewPRs`**: View and open assigned pull requests.
- **`ReviewPullRequests`**: Review pull requests for the current repository.
- **`OpenPullRequest`**: Open a specific pull request by ID.

### Module Administration

- **`cobra modules`**: Manage Cobra modules.
  - **`add <name>`**: Create a new module.
  - **`remove <name>`**: Remove an existing module.
  - **`edit <name>`**: Edit a module's configuration and script files.
  - **`import <name> <artifactPath>`**: Import a module from an artifact.
  - **`export <name> <artifactPath>`**: Export a module to an artifact.

### Global Configuration Commands

- **`cobra env init`**: Initialize environment variables based on the global configuration file.
- **`cobra env`**: Display the current environment variables and their values.

### Utility Functions

- Utility scripts can be added to the `Utils` folder. These scripts are automatically loaded and available for use.
- To view available utility functions, use the command:
  ```powershell
  cobra utils
  ```

### Go Location Management

- **`cobra go`**: Manage "Go" locations.
  - **`add <name> <description> <url>`**: Add a new "Go" location.
  - **`remove <name>`**: Remove an existing "Go" location.
  - **`update <name> <description> <url>`**: Update an existing "Go" location.

### Other Features

- **`AppInfo`**: Display detailed information about the current repository/application.

## Contributing

Contributions are welcome! Add new utility scripts to the `Utils` folder or extend the framework by creating new modules.

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the [MIT License](LICENSE).
