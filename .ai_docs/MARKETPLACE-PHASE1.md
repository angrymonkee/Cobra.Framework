# Cobra Module Marketplace - Phase 1 Implementation

## Overview

Phase 1 of the Cobra Module Marketplace introduces enhanced registry structure with rich metadata, version management, and dependency resolution. This replaces the simple file-based registry with a comprehensive module management system.

## New Features

### 1. Enhanced Module Metadata

Modules now include comprehensive metadata:

- **Basic Info**: Name, Version, Author, Description
- **Categorization**: Tags, Categories for easy discovery
- **Dependencies**: Automatic dependency resolution
- **Community**: Rating/review system, install counts
- **Repository Info**: License, homepage, repository links
- **Versioning**: Multiple version support with release notes

### 2. Advanced Search & Discovery

```powershell
# Search by text, tags, categories, ratings
cobra modules search "automation"
cobra modules search --tags "development,git" --min-rating 4

# Browse by categories
cobra modules registry list
cobra modules info ModuleName
```

### 3. Dependency Resolution

The system automatically resolves and installs module dependencies:

```powershell
# Install with all dependencies
cobra modules install GitUtils

# View dependency tree before installing
cobra modules info GitUtils  # Shows dependencies
```

### 4. Rating & Review System

```powershell
# Rate a module (1-5 stars)
cobra modules rate GitUtils 5 "Excellent Git automation tools!"

# View ratings and reviews
cobra modules info GitUtils  # Shows average rating and recent reviews
```

### 5. Enhanced Registry Structure

```
ModuleRegistry/
├── registry.json          # Central metadata database
├── packages/              # Versioned module packages (*.zip)
├── metadata/              # Individual metadata files
└── cache/                 # Installation cache
```

## Key Commands

### Registry Management

```powershell
cobra modules registry init          # Initialize marketplace
cobra modules registry list          # List all modules
cobra modules registry info <name>   # Get detailed module info
cobra modules registry search <term> # Search registry
```

### Module Lifecycle

```powershell
cobra modules publish <name>         # Publish module to marketplace
cobra modules install <name>         # Install with dependency resolution
cobra modules update <name>          # Update to latest version
cobra modules uninstall <name>       # Remove module
```

### Discovery & Community

```powershell
cobra modules search <term>          # Advanced search
cobra modules rate <name> <1-5>      # Rate and review modules
cobra modules info <name>            # View ratings, dependencies, etc.
```

## Database Structure

The `registry.json` contains:

```json
{
  "modules": {
    "ModuleName": {
      "versions": {
        "1.0.0": { /* metadata */ },
        "1.1.0": { /* metadata */ }
      },
      "ratings": [ /* user reviews */ ],
      "stats": { "InstallCount": 150 }
    }
  },
  "categories": ["Development", "Automation", ...],
  "featured": [...],
  "registryVersion": "1.0.0",
  "lastSync": "2025-08-12T..."
}
```

## Module Package Format

Each module is packaged as `ModuleName-Version.zip` containing:

- Module source files (\*.psm1, config.ps1)
- Enhanced metadata
- Documentation
- Tests (optional)

## Configuration

Update your `sysconfig.ps1`:

```powershell
$global:CobraConfig = @{
    ModuleRegistryLocation = "C:\CobraRegistry"  # Required
    # ... other config
}
```

## Testing

Run the test script to validate Phase 1:

```powershell
.\test-marketplace.ps1
```

## Migration from Legacy System

The new system is designed to work alongside the old registry. Existing modules can be:

1. Published to the new marketplace using `cobra modules publish`
2. Enhanced with rich metadata
3. Discovered through the new search system

## Next Phases

- **Phase 2**: Web interface, remote registries, team collaboration
- **Phase 3**: CI/CD integration, automated testing, quality gates

**📋 For complete roadmap details and current status, see:**

- [MARKETPLACE-ROADMAP.md](MARKETPLACE-ROADMAP.md) - Complete development roadmap with technical details
- [MARKETPLACE-STATUS.md](MARKETPLACE-STATUS.md) - Current status and quick reference guide

## Troubleshooting

### Registry Not Found

```powershell
# Initialize the marketplace
cobra modules registry init
```

### Module Not Publishing

- Ensure module exists in `Modules/<ModuleName>/`
- Check that `ModuleRegistryLocation` is configured
- Verify write permissions to registry directory

### Search Returns No Results

- Initialize marketplace: `cobra modules registry init`
- Publish some modules first: `cobra modules publish <name>`
- Check search terms and try broader queries
