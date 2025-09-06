# Cobra Framework AI Agent Instructions

## Architecture Overview

Cobra Framework is a **modular PowerShell productivity framework** built around a **plugin architecture** with centralized configuration and shared state management. The core philosophy is **context-aware development** with **automated workflow management**.

### Key Components

- **Core State Management**: `Core.ps1` manages global state in `$global:AppConfigs`, `$global:CobraStandaloneModules`, and `$global:goTaskStore`
- **Module System**: Two types - Repository modules (tied to Git repos) and Standalone modules (independent services)
- **Template Engine**: Multi-tier template system supporting module, function, and code snippets
- **Marketplace**: Version-controlled module distribution with ratings, dependency resolution, and metadata
- **Dashboard**: Context-aware TUI with real-time Git status and quick actions

## Critical Development Patterns

### Module Registration Pattern

All modules MUST register themselves using one of these patterns:

```powershell
# Repository-based modules
Register-CobraRepository -Name "ModuleName" -Description "..." -Config $config

# Standalone modules
Register-CobraStandaloneModule -Name "ModuleName" -Description "..." -Config $config
```

### Configuration Structure

Every module needs a `config.ps1` with these required keys for repository modules:

```powershell
@{
    Name = "ModuleName"
    Repo = "RelativeOrAbsolutePath"
    AuthMethod = "Function-Name"
    SetupMethod = "Function-Name"
    BuildMethod = "Function-Name"
    TestMethod = "Function-Name"
    RunMethod = "Function-Name"
    DevMethod = "Function-Name"
    ReviewPullRequests = "Function-Name"
    OpenPullRequest = "Function-Name"
    GoLocations = @{ "location" = @("description", "path/url") }
}
```

Standalone modules use `ModuleType = "Standalone"` and have different required fields.

### Activity Logging Pattern

ALL user actions should be logged using:

```powershell
Log-CobraActivity "Action description with context"
```

### Global State Access

- Current repo context: `$global:currentAppConfig`
- All repo configs: `$global:AppConfigs`
- Navigation locations: `$global:goTaskStore`
- Framework config: `$global:CobraConfig` (from `sysconfig.ps1`)

## Essential Workflows

### Module Creation Workflow

1. Use template system: `cobra templates new basic-module ModuleName`
2. Templates auto-generate: `ModuleName.psm1`, `config.ps1`, directory structure
3. Registration happens automatically in `Initialize-ModuleNameModule` function
4. Module loading via `Import-CobraModules` in `Core.ps1`

### Development Commands Flow

The framework expects this command sequence for any repo:

1. `repo ModuleName` - Load repo context and navigate
2. `authApp` - Authenticate (calls module's AuthMethod)
3. `setupApp` - One-time setup (calls SetupMethod)
4. `buildApp` - Build project (calls BuildMethod)
5. `testApp` - Run tests (calls TestMethod)
6. `pr` - Pre-pull request automation

### Navigation System

- `repo <name>` - Switch repository context, load module config, set `$global:currentAppConfig`
- `go <location>` - Navigate using `GoLocations` from current repo config
- Context switches update global state and change working directory

## Integration Points

### Template System Integration

Templates support module-specific templates in `Modules/ModuleName/templates/`:

- Function templates: `.ps1` files with metadata headers
- Text templates: `.txt`, `.md` files
- JSON configs: `.json` with structured metadata

### Marketplace Integration

Publishing flow: `cobra modules publish ModuleName` triggers:

1. Interactive metadata collection (version, description, tags, dependencies)
2. Package creation as `.zip` in `packages/` directory
3. Metadata storage in `metadata/ModuleName/Version/` structure
4. Central registry database update in `registry.json`

### Dashboard Integration

Modules can provide dashboard status via config:

```powershell
Integrations = @{
    Dashboard = @{
        Enabled = $true
        StatusFunction = "Get-ModuleStatus"
        Priority = "High"
    }
}
```

## Common Antipatterns to Avoid

- ❌ Don't call module functions directly - use the command dispatch pattern through `DevCommands.ps1`
- ❌ Don't hardcode paths - use `$global:CobraConfig` values
- ❌ Don't skip activity logging - every user action needs `Log-CobraActivity`
- ❌ Don't create modules without proper config.ps1 structure
- ❌ Don't forget to export functions with `Export-ModuleMember`

## File Naming Conventions

- Module files: `ModuleName.psm1` (matches directory name)
- Config files: Always named `config.ps1`
- Template files: Descriptive names with appropriate extensions
- Job scripts: `*Jobs.psm1` in `Jobs/` directory

## Key Files for Context

- `Core.ps1` - State management and module registration
- `CobraProfile.ps1` - Main entry point and command routing
- `sysconfig.ps1` - Global configuration (paths, registry locations)
- `TemplatesManagement.ps1` - Template system implementation
- `ModuleManagement.ps1` - Marketplace and module lifecycle
- `DevCommands.ps1` - Repository workflow commands

Understanding these patterns will help you work effectively with the modular, context-aware nature of the Cobra Framework.
