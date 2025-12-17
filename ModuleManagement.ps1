$global:moduleManagementScriptLoaded = $true

# Dependencies:
# Load the core script if it hasn't been loaded yet
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

Log-CobraActivity "Loading Cobra Module Management and Marketplace..."

# Enhanced module metadata structure
class CobraModuleMetadata {
    [string]$Name
    [string]$Version
    [string]$Author
    [string]$Description
    [string[]]$Tags
    [hashtable]$Dependencies  # ModuleName -> Version
    [string]$CompatibilityVersion
    [string]$ReleaseNotes
    [string]$Repository
    [hashtable]$Rating
    [int]$InstallCount
    [datetime]$LastUpdated
    [string[]]$Categories
    [string]$License
    [string]$Homepage
    [hashtable]$Scripts  # Script purposes -> script names
    [string[]]$RequiredModules
    [string]$MinimumCobraVersion
    
    CobraModuleMetadata() {
        $this.Rating = @{
            Average = 0.0
            Count   = 0
            Reviews = @()
        }
        $this.Dependencies = @{}
        $this.Scripts = @{}
        $this.Tags = @()
        $this.Categories = @()
        $this.RequiredModules = @()
        $this.InstallCount = 0
        $this.LastUpdated = Get-Date
    }
}

class CobraModuleReview {
    [string]$User
    [int]$Rating
    [string]$Comment
    [datetime]$Date
    [string]$Version
    
    CobraModuleReview([string]$user, [int]$rating, [string]$comment, [string]$version) {
        $this.User = $user
        $this.Rating = $rating
        $this.Comment = $comment
        $this.Date = Get-Date
        $this.Version = $version
    }
}

# Registry database structure
class CobraModuleRegistry {
    [hashtable]$Modules
    [string[]]$Categories
    [string[]]$Featured
    [datetime]$LastSync
    [string]$RegistryVersion
    
    CobraModuleRegistry() {
        $this.Modules = @{}
        $this.Categories = @("Development", "Automation", "Utilities", "Integration", "Testing", "Deployment", "Monitoring")
        $this.Featured = @()
        $this.LastSync = Get-Date
        $this.RegistryVersion = "1.0.0"
    }
}

# Initialize marketplace
function Initialize-ModuleMarketplace {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    Log-CobraActivity "Initializing Module Marketplace..."
    
    # Get registry location
    if (-not $global:CobraConfig.ModuleRegistryLocation) {
        Write-Host "ModuleRegistryLocation not configured. Please set this in your sysconfig.ps1" -ForegroundColor Red
        return $false
    }
    
    $registryPath = $global:CobraConfig.ModuleRegistryLocation
    
    # Create registry directory structure
    if (-not (Test-Path $registryPath)) {
        New-Item -Path $registryPath -ItemType Directory -Force | Out-Null
        Write-Host "Created registry directory: $registryPath" -ForegroundColor Green
    }
    
    # Create subdirectories
    $subdirs = @("metadata", "packages", "cache")
    foreach ($subdir in $subdirs) {
        $path = Join-Path $registryPath $subdir
        if (-not (Test-Path $path)) {
            New-Item -Path $path -ItemType Directory -Force | Out-Null
        }
    }
    
    # Initialize registry database
    $registryDbPath = Join-Path $registryPath "registry.json"
    if (-not (Test-Path $registryDbPath) -or $Force) {
        $registry = @{
            Modules         = @{}
            Categories      = @("Development", "Automation", "Utilities", "Integration", "Testing", "Deployment", "Monitoring")
            Featured        = @()
            LastSync        = Get-Date
            RegistryVersion = "1.0.0"
        }
        $registryJson = $registry | ConvertTo-Json -Depth 10
        Set-Content -Path $registryDbPath -Value $registryJson -Encoding UTF8
        Write-Host "Initialized registry database: $registryDbPath" -ForegroundColor Green
    }
    
    Log-CobraActivity "Module Marketplace initialized successfully"
    return $true
}

# Get registry database
function Get-ModuleRegistry {
    $registryPath = $global:CobraConfig.ModuleRegistryLocation
    $registryDbPath = Join-Path $registryPath "registry.json"
    
    if (-not (Test-Path $registryDbPath)) {
        Write-Host "Registry database not found. Run 'Initialize-ModuleMarketplace' first." -ForegroundColor Red
        return $null
    }
    
    try {
        $registryJson = Get-Content $registryDbPath -Raw -Encoding UTF8
        $registry = $registryJson | ConvertFrom-Json -AsHashtable
        return $registry
    }
    catch {
        Write-Host "Error reading registry database: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

# Save registry database
function Save-ModuleRegistry {
    param([PSCustomObject]$Registry)
    
    $registryPath = $global:CobraConfig.ModuleRegistryLocation
    $registryDbPath = Join-Path $registryPath "registry.json"
    
    try {
        $Registry.LastSync = Get-Date
        $registryJson = $Registry | ConvertTo-Json -Depth 10
        Set-Content -Path $registryDbPath -Value $registryJson -Encoding UTF8
        return $true
    }
    catch {
        Write-Host "Error saving registry database: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Get module registry information and handle registry commands
function Get-ModuleRegistryInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Action,
        
        [string]$ModuleName = $null,
        [string]$SearchTerm = $null
    )
    
    switch ($Action.ToLower()) {
        "list" {
            $registry = Get-ModuleRegistry
            if (-not $registry) {
                Write-Host "Registry not initialized. Run: cobra modules registry init" -ForegroundColor Red
                return
            }
            
            if (-not $registry.Modules -or $registry.Modules.Count -eq 0) {
                Write-Host "No modules found in registry" -ForegroundColor Yellow
                Write-Host "Use 'cobra modules publish <name>' to add modules to the registry" -ForegroundColor DarkGray
                return
            }
            
            Write-Host "COBRA MODULE REGISTRY" -ForegroundColor Cyan
            Write-Host ("=" * 50) -ForegroundColor DarkGray
            
            $moduleCount = 0
            foreach ($moduleName in $registry.Modules.Keys) {
                $moduleData = $registry.Modules[$moduleName]
                
                # Get latest version - handle hashtable keys correctly
                if ($moduleData.versions -and $moduleData.versions.Keys.Count -gt 0) {
                    # Get version keys and sort them
                    $versionKeys = $moduleData.versions.Keys | Where-Object { 
                        $_ -match '^\d+\.\d+\.\d+$' 
                    }
                    
                    if ($versionKeys) {
                        $latestVersionKey = $versionKeys | Sort-Object { 
                            try { 
                                [Version]$_ 
                            }
                            catch { 
                                [Version]"0.0.0" 
                            } 
                        } | Select-Object -Last 1
                        
                        $latestVersion = @{
                            Name  = $latestVersionKey
                            Value = $moduleData.versions[$latestVersionKey]
                        }
                    }
                    else {
                        $latestVersion = $null
                    }
                }
                else {
                    $latestVersion = $null
                }
                
                if ($latestVersion) {
                    $versionData = $latestVersion.Value
                    $moduleCount++
                    
                    Write-Host "  $moduleName" -ForegroundColor White -NoNewline
                    Write-Host " (v$($latestVersion.Name))" -ForegroundColor Green
                    
                    if ($versionData.Description) {
                        Write-Host "    $($versionData.Description)" -ForegroundColor DarkGray
                    }
                    
                    if ($versionData.Tags -and $versionData.Tags.Count -gt 0) {
                        Write-Host "    Tags: $($versionData.Tags -join ', ')" -ForegroundColor DarkCyan
                    }
                    
                    # Show install count and rating if available
                    $installCount = if ($moduleData.stats -and $moduleData.stats.InstallCount) { $moduleData.stats.InstallCount } else { 0 }
                    $avgRating = if ($moduleData.ratings -and $moduleData.ratings.Count -gt 0) {
                        ($moduleData.ratings | ForEach-Object { $_.Rating } | Measure-Object -Average).Average
                    }
                    else { $null }
                    
                    $statsInfo = @()
                    $statsInfo += "Installs: $installCount"
                    if ($avgRating) {
                        $statsInfo += "Rating: $([math]::Round($avgRating, 1))/5"
                    }
                    Write-Host "    $($statsInfo -join ' | ')" -ForegroundColor Gray
                    
                    Write-Host ""
                }
            }
            
            Write-Host "Total: $moduleCount modules in registry" -ForegroundColor Cyan
            Write-Host "Registry location: $($global:CobraConfig.ModuleRegistryLocation)" -ForegroundColor DarkGray
        }
        
        "info" {
            if (-not $ModuleName) {
                Write-Host "Usage: cobra modules registry info <module-name>" -ForegroundColor Red
                return
            }
            
            $registry = Get-ModuleRegistry
            if (-not $registry) {
                Write-Host "Registry not initialized. Run: cobra modules registry init" -ForegroundColor Red
                return
            }
            
            if (-not $registry.Modules.Keys -contains $ModuleName) {
                Write-Host "Module '$ModuleName' not found in registry" -ForegroundColor Red
                Write-Host "Use 'cobra modules search $ModuleName' to search for similar modules" -ForegroundColor Yellow
                return
            }
            
            $moduleData = $registry.Modules.$ModuleName
            
            Write-Host "MODULE INFORMATION: $ModuleName" -ForegroundColor Cyan
            Write-Host ("=" * 50) -ForegroundColor DarkGray
            
            # Show all versions - use hashtable keys correctly
            $versionKeys = $moduleData.versions.Keys | Where-Object { 
                $_ -match '^\d+\.\d+\.\d+$' 
            }
            $versions = $versionKeys | Sort-Object { 
                try { 
                    [Version]$_ 
                }
                catch { 
                    [Version]"0.0.0" 
                } 
            } | ForEach-Object {
                @{
                    Name  = $_
                    Value = $moduleData.versions[$_]
                }
            }
            $latestVersion = $versions | Select-Object -Last 1
            
            Write-Host "Latest Version: " -ForegroundColor Yellow -NoNewline
            Write-Host "$($latestVersion.Name)" -ForegroundColor White
            
            $latestData = $latestVersion.Value
            
            if ($latestData.Description) {
                Write-Host "Description: " -ForegroundColor Yellow -NoNewline
                Write-Host "$($latestData.Description)" -ForegroundColor White
            }
            
            if ($latestData.Author) {
                Write-Host "Author: " -ForegroundColor Yellow -NoNewline
                Write-Host "$($latestData.Author)" -ForegroundColor White
            }
            
            if ($latestData.Tags -and $latestData.Tags.Count -gt 0) {
                Write-Host "Tags: " -ForegroundColor Yellow -NoNewline
                Write-Host "$($latestData.Tags -join ', ')" -ForegroundColor Cyan
            }
            
            if ($latestData.Categories -and $latestData.Categories.Count -gt 0) {
                Write-Host "Categories: " -ForegroundColor Yellow -NoNewline
                Write-Host "$($latestData.Categories -join ', ')" -ForegroundColor Cyan
            }
            
            if ($latestData.Dependencies -and $latestData.Dependencies.Count -gt 0) {
                Write-Host "Dependencies: " -ForegroundColor Yellow -NoNewline
                Write-Host "$($latestData.Dependencies.Keys -join ', ')" -ForegroundColor White
            }
            
            # Installation stats
            $installCount = if ($moduleData.stats -and $moduleData.stats.InstallCount) { $moduleData.stats.InstallCount } else { 0 }
            Write-Host "Install Count: " -ForegroundColor Yellow -NoNewline
            Write-Host "$installCount" -ForegroundColor White
            
            # Ratings and reviews
            if ($moduleData.ratings -and $moduleData.ratings.Count -gt 0) {
                $avgRating = ($moduleData.ratings | ForEach-Object { $_.Rating } | Measure-Object -Average).Average
                Write-Host "Average Rating: " -ForegroundColor Yellow -NoNewline
                Write-Host "$([math]::Round($avgRating, 1))/5 ($($moduleData.ratings.Count) reviews)" -ForegroundColor White
                
                Write-Host ""
                Write-Host "Recent Reviews:" -ForegroundColor Yellow
                $moduleData.ratings | Select-Object -Last 3 | ForEach-Object {
                    Write-Host "  $($_.Rating)/5 stars" -ForegroundColor Green -NoNewline
                    if ($_.Review) {
                        Write-Host " - $($_.Review)" -ForegroundColor DarkGray
                    }
                    else {
                        Write-Host ""
                    }
                }
            }
            
            # All available versions
            Write-Host ""
            Write-Host "Available Versions:" -ForegroundColor Yellow
            foreach ($version in $versions) {
                $versionData = $version.Value
                $publishDate = if ($versionData.PublishDate) { 
                    try { [DateTime]::Parse($versionData.PublishDate).ToString("yyyy-MM-dd") } 
                    catch { "Unknown" } 
                }
                else { "Unknown" }
                
                Write-Host "  v$($version.Name)" -ForegroundColor White -NoNewline
                Write-Host " (Published: $publishDate)" -ForegroundColor DarkGray
                
                if ($versionData.ReleaseNotes -and $versionData.ReleaseNotes -ne "New release") {
                    Write-Host "    $($versionData.ReleaseNotes)" -ForegroundColor DarkGray
                }
            }
        }
        
        "init" {
            Initialize-ModuleMarketplace -Force:$true
        }
        
        default {
            Write-Host "Invalid registry action: $Action" -ForegroundColor Red
            Write-Host "Available actions: list, info, init" -ForegroundColor Yellow
        }
    }
}

# Create module metadata from existing module
function New-ModuleMetadata {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [string]$Version,
        
        [Parameter(Mandatory = $true)]
        [string]$Author,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [string[]]$Tags = @(),
        [string[]]$Categories = @(),
        [hashtable]$Dependencies = @{},
        [string]$Repository = "",
        [string]$License = "MIT",
        [string]$Homepage = "",
        [string]$ReleaseNotes = "Initial version",
        [string]$CompatibilityVersion = "1.0.0",
        [string]$MinimumCobraVersion = "1.0.0"
    )
    
    $metadata = @{
        Name                 = $ModuleName
        Version              = $Version
        Author               = $Author
        Description          = $Description
        Tags                 = $Tags
        Categories           = $Categories
        Dependencies         = $Dependencies
        Repository           = $Repository
        License              = $License
        Homepage             = $Homepage
        ReleaseNotes         = $ReleaseNotes
        CompatibilityVersion = $CompatibilityVersion
        MinimumCobraVersion  = $MinimumCobraVersion
        Rating               = @{
            Average = 0.0
            Count   = 0
            Reviews = @()
        }
        Scripts              = @{}
        RequiredModules      = @()
        InstallCount         = 0
        LastUpdated          = Get-Date
    }
    
    # Analyze module structure to populate Scripts
    $modulePath = Join-Path $PSScriptRoot "Modules\$ModuleName"
    if (Test-Path $modulePath) {
        $configPath = Join-Path $modulePath "config.ps1"
        if (Test-Path $configPath) {
            $config = & $configPath
            $metadata.Scripts = @{
                "Auth"               = $config.AuthMethod
                "Setup"              = $config.SetupMethod
                "Build"              = $config.BuildMethod
                "Test"               = $config.TestMethod
                "Run"                = $config.RunMethod
                "Dev"                = $config.DevMethod
                "ReviewPullRequests" = $config.ReviewPullRequests
                "OpenPullRequest"    = $config.OpenPullRequest
            }
        }
    }
    
    return $metadata
}

# Resolve module dependencies
function Resolve-ModuleDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [string]$Version = "latest"
    )
    
    $registry = Get-ModuleRegistry
    if (-not $registry) { return @() }
    
    $script:resolved = @()
    $script:resolving = @()
    
    function ResolveDependency($name, $requestedVersion) {
        # Prevent circular dependencies
        if ($script:resolving -contains $name) {
            Write-Warning "Circular dependency detected: $name"
            return
        }
        
        if ($script:resolved | Where-Object { $_.Name -eq $name }) {
            return  # Already resolved
        }
        
        $script:resolving += $name
        
        # Get module info
        if (-not $registry.Modules.Keys -contains $name) {
            Write-Error "Dependency not found in registry: $name"
            return
        }
        
        $moduleInfo = $registry.Modules[$name]
        
        # Select version - use hashtable keys correctly
        $availableVersions = @($moduleInfo.versions.Keys | Where-Object { 
                $_ -match '^\d+\.\d+\.\d+$' 
            } | Sort-Object { 
                try { 
                    [Version]$_ 
                }
                catch { 
                    [Version]"0.0.0" 
                } 
            } -Descending)
        
        $selectedVersion = if ($requestedVersion -eq "latest") {
            if ($availableVersions.Count -gt 0) { $availableVersions[0] } else { $null }
        }
        else {
            $availableVersions | Where-Object { $_ -eq $requestedVersion } | Select-Object -First 1
        }
        
        if (-not $selectedVersion) {
            Write-Error "Version $requestedVersion not found for module: $name"
            return
        }
        
        $metadata = $moduleInfo.versions.$selectedVersion
        
        # Recursively resolve dependencies
        if ($metadata.Dependencies -and $metadata.Dependencies.Count -gt 0) {
            foreach ($dep in $metadata.Dependencies.GetEnumerator()) {
                ResolveDependency $dep.Key $dep.Value
            }
        }
        
        # Add to resolved list
        $script:resolved += [PSCustomObject]@{
            Name     = $name
            Version  = $selectedVersion
            Metadata = $metadata
        }
        
        $script:resolving = $script:resolving | Where-Object { $_ -ne $name }
    }
    
    ResolveDependency $ModuleName $Version
    
    return $script:resolved
}

# Update module installation statistics
function Update-ModuleInstallStats {
    param([string]$ModuleName)
    
    $registry = Get-ModuleRegistry
    if (-not $registry) { return }
    
    if (-not $registry.Modules.$ModuleName.stats) {
        $registry.Modules.$ModuleName | Add-Member -NotePropertyName "stats" -NotePropertyValue @{ InstallCount = 0 }
    }
    
    $registry.Modules.$ModuleName.stats.InstallCount++
    Save-ModuleRegistry -Registry $registry
}

# Install single module (internal function)
function Install-SingleModule {
    [CmdletBinding()]
    param(
        [string]$ModuleName,
        [string]$Version,
        [switch]$Force
    )
    
    $modulePath = Join-Path $PSScriptRoot "Modules\$ModuleName"
    
    # Check if already installed
    if ((Test-Path $modulePath) -and -not $Force) {
        Write-Host "Module $ModuleName already exists. Use -Force to overwrite." -ForegroundColor Yellow
        return $false
    }
    
    # Get module package from registry
    $registryPath = $global:CobraConfig.ModuleRegistryLocation
    $packagePath = Join-Path $registryPath "packages\$ModuleName-$Version.zip"
    
    if (-not (Test-Path $packagePath)) {
        Write-Host "Package not found: $ModuleName-$Version.zip" -ForegroundColor Red
        return $false
    }
    
    try {
        # Remove existing if Force
        if ((Test-Path $modulePath) -and $Force) {
            Remove-Item -Path $modulePath -Recurse -Force
        }
        
        # Extract package to temporary directory first
        $tempPath = Join-Path $env:TEMP "CobraModule_$ModuleName_$((Get-Date).Ticks)"
        New-Item -Path $tempPath -ItemType Directory -Force | Out-Null
        
        try {
            # Extract package to temp directory
            Expand-Archive -Path $packagePath -DestinationPath $tempPath -Force
            
            # Find the actual module directory in the extracted content
            $extractedModuleDir = Get-ChildItem -Path $tempPath -Directory | Where-Object { $_.Name -eq $ModuleName } | Select-Object -First 1
            
            if ($extractedModuleDir) {
                # Copy contents from extracted module directory to target location, preserving structure
                Copy-Item -Path "$($extractedModuleDir.FullName)\*" -Destination $modulePath -Recurse -Force
            }
            else {
                # Fallback: copy all extracted content directly (in case package structure is different)
                Copy-Item -Path "$tempPath\*" -Destination $modulePath -Recurse -Force
            }
        }
        finally {
            # Clean up temp directory
            if (Test-Path $tempPath) {
                Remove-Item -Path $tempPath -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        
        # Register module
        if (-not $global:CobraScriptModules) {
            $global:CobraScriptModules = @{}
        }
        
        $global:CobraScriptModules[$ModuleName] = @($ModuleName, "$ModuleName.psm1")
        
        # Load module
        $moduleFile = Join-Path $modulePath "$ModuleName.psm1"
        if (Test-Path $moduleFile) {
            Import-Module $moduleFile -Force -DisableNameChecking
            
            # Initialize module if function exists
            $initFunction = "Initialize-$($ModuleName)Module"
            if (Get-Command $initFunction -ErrorAction SilentlyContinue) {
                & $initFunction
                
                # Additional setup for standalone modules
                $configPath = Join-Path $modulePath "config.ps1"
                if (Test-Path $configPath) {
                    $config = & $configPath
                    if ($config.ModuleType -eq "Standalone") {
                        Write-Host "  ✓ Standalone module '$ModuleName' aliases registered" -ForegroundColor DarkGray
                        Write-Host "  → Type '$ModuleName' or '$($ModuleName.ToLower())' for help" -ForegroundColor DarkGray
                    }
                }
            }
        }
        
        Write-Host "Installed: $ModuleName v$Version" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Error installing $ModuleName : $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Rate and review a module
function Set-ModuleRating {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 5)]
        [int]$Rating,
        
        [string]$Comment = "",
        [string]$UserName = $env:USERNAME
    )
    
    $registry = Get-ModuleRegistry
    if (-not $registry -or -not $registry.Modules.ContainsKey($ModuleName)) {
        Write-Host "Module not found in registry: $ModuleName" -ForegroundColor Red
        return $false
    }
    
    # Create review
    $latestVersion = ($registry.Modules[$ModuleName].versions.Keys | Sort-Object -Descending)[0]
    $review = [CobraModuleReview]::new($UserName, $Rating, $Comment, $latestVersion)
    
    # Add to module ratings
    $registry.Modules[$ModuleName].ratings += $review
    
    # Save registry
    if (Save-ModuleRegistry -Registry $registry) {
        Write-Host "Rating submitted successfully!" -ForegroundColor Green
        Write-Host "⭐$Rating - $Comment" -ForegroundColor Yellow
        Log-CobraActivity "Rated module: $ModuleName ($Rating stars)"
        return $true
    }
    else {
        Write-Host "Failed to save rating" -ForegroundColor Red
        return $false
    }
}

# Get next version number by incrementing patch version
function Get-NextModuleVersion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    try {
        # Get registry to check existing versions
        $registry = Get-ModuleRegistry
        if (-not $registry -or -not $registry.Modules.ContainsKey($ModuleName)) {
            # No existing versions, start with 1.0.0
            return "1.0.0"
        }
        
        # Get all existing versions and find the highest
        $existingVersions = $registry.Modules.$ModuleName.versions.Keys
        if (-not $existingVersions -or $existingVersions.Count -eq 0) {
            return "1.0.0"
        }
        
        # Parse versions and find the highest
        $highestVersion = $existingVersions | 
        ForEach-Object {
            if ($_ -match "^(\d+)\.(\d+)\.(\d+)$") {
                [PSCustomObject]@{
                    Original  = $_
                    Major     = [int]$matches[1]
                    Minor     = [int]$matches[2]
                    Patch     = [int]$matches[3]
                    SortValue = ([int]$matches[1] * 1000000) + ([int]$matches[2] * 1000) + [int]$matches[3]
                }
            }
        } |
        Sort-Object SortValue -Descending |
        Select-Object -First 1
            
        if (-not $highestVersion) {
            return "1.0.0"
        }
        
        # Increment patch version
        $newVersion = "$($highestVersion.Major).$($highestVersion.Minor).$($highestVersion.Patch + 1)"
        Write-Host "Auto-incrementing version from $($highestVersion.Original) to $newVersion" -ForegroundColor Cyan
        return $newVersion
    }
    catch {
        Write-Host "Error determining next version, defaulting to 1.0.0: $($_.Exception.Message)" -ForegroundColor Yellow
        return "1.0.0"
    }
}

# Publish module to marketplace
function Publish-CobraModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [string]$Version,
        [string]$Author = $env:USERNAME,
        [string]$Description = "",
        [string[]]$Tags = @(),
        [string[]]$Categories = @(),
        [hashtable]$Dependencies = @{},
        [string]$ReleaseNotes = "New release",
        [switch]$Force
    )
    
    Log-CobraActivity "Publishing module: $ModuleName v$Version"
    
    # Validate module exists
    $modulePath = Join-Path $PSScriptRoot "Modules\$ModuleName"
    if (-not (Test-Path $modulePath)) {
        Write-Host "Module not found: $ModuleName" -ForegroundColor Red
        return $false
    }
    
    # Get or create registry
    $registry = Get-ModuleRegistry
    if (-not $registry) {
        Write-Host "Registry not initialized. Run: cobra modules registry init" -ForegroundColor Red
        return $false
    }
    
    # Interactive metadata collection if not provided
    if (-not $Description) {
        $Description = Read-Host "Enter module description"
    }
    
    if ($Tags.Count -eq 0) {
        $tagsInput = Read-Host "Enter tags (comma-separated)"
        if ($tagsInput) {
            $Tags = $tagsInput -split "," | ForEach-Object { $_.Trim() }
        }
    }
    
    if ($Categories.Count -eq 0) {
        Write-Host "Available categories: $($registry.Categories -join ', ')" -ForegroundColor Cyan
        $categoriesInput = Read-Host "Enter categories (comma-separated)"
        if ($categoriesInput) {
            $Categories = $categoriesInput -split "," | ForEach-Object { $_.Trim() }
        }
    }
    
    # Create metadata
    $metadata = New-ModuleMetadata -ModuleName $ModuleName -Version $Version -Author $Author `
        -Description $Description -Tags $Tags -Categories $Categories `
        -Dependencies $Dependencies -ReleaseNotes $ReleaseNotes
    
    # Check if module already exists
    if ($registry.Modules.$ModuleName -and -not $Force) {
        $existingVersions = $registry.Modules.$ModuleName.versions.PSObject.Properties.Name
        if ($existingVersions -contains $Version) {
            Write-Host "Version $Version already exists for $ModuleName. Use -Force to overwrite." -ForegroundColor Red
            return $false
        }
    }
    
    try {
        # Create package
        $registryPath = $global:CobraConfig.ModuleRegistryLocation
        $packagePath = Join-Path $registryPath "packages\$ModuleName-$Version.zip"
        
        # Ensure packages directory exists
        $packagesDir = Join-Path $registryPath "packages"
        if (-not (Test-Path $packagesDir)) {
            New-Item -Path $packagesDir -ItemType Directory -Force | Out-Null
        }
        
        # Create package
        Compress-Archive -Path $modulePath -DestinationPath $packagePath -Force
        
        # Copy extended metadata if it exists
        $moduleMetadataSource = Join-Path $modulePath "metadata"
        if (Test-Path $moduleMetadataSource) {
            $metadataDir = Join-Path $registryPath "metadata"
            $moduleMetadataTarget = Join-Path $metadataDir "$ModuleName\$Version"
            
            # Remove existing metadata for this specific version
            if (Test-Path $moduleMetadataTarget) {
                Remove-Item -Path $moduleMetadataTarget -Recurse -Force
            }
            
            # Ensure parent directory exists
            $moduleDir = Split-Path $moduleMetadataTarget
            if (-not (Test-Path $moduleDir)) {
                New-Item -Path $moduleDir -ItemType Directory -Force | Out-Null
            }
            
            Copy-Item -Path $moduleMetadataSource -Destination $moduleMetadataTarget -Recurse -Force
            Write-Host "Extended metadata copied to registry (version $Version)" -ForegroundColor DarkGray
        }
        
        # Update registry
        if (-not $registry.Modules.ContainsKey($ModuleName)) {
            $registry.Modules[$ModuleName] = @{
                versions = @{}
                ratings  = @()
                stats    = @{ InstallCount = 0 }
            }
        }
        
        # Add version
        $registry.Modules[$ModuleName].versions[$Version] = $metadata
        
        # Save registry
        if (Save-ModuleRegistry -Registry $registry) {
            Write-Host "Successfully published $ModuleName v$Version" -ForegroundColor Green
            Log-CobraActivity "Published module: $ModuleName v$Version"
            return $true
        }
        else {
            Write-Host "Failed to update registry" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "Error publishing module: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Failed to publish module: $ModuleName - $($_.Exception.Message)"
        return $false
    }
}

# Advanced module search
function Search-Modules {
    [CmdletBinding()]
    param(
        [string]$SearchTerm = "",
        [string[]]$Tags = @(),
        [string]$Category = "",
        [double]$MinRating = 0,
        [string]$Author = "",
        [int]$Limit = 50,
        [ValidateSet("Name", "Rating", "InstallCount", "LastUpdated")]
        [string]$SortBy = "Rating",
        [switch]$Descending
    )
    
    # Search local modules first
    $localResults = @()
    if ($global:CobraScriptModules) {
        foreach ($moduleName in $global:CobraScriptModules.Keys) {
            $moduleInfo = $global:CobraScriptModules[$moduleName]
            
            # Apply search filter for local modules
            $isMatch = $true
            if ($SearchTerm -and $isMatch) {
                $searchFields = @($moduleName, $moduleInfo[1])  # Name and description
                $isMatch = $searchFields | Where-Object { $_ -like "*$SearchTerm*" }
            }
            
            if ($isMatch) {
                $localResults += [PSCustomObject]@{
                    Name        = $moduleName
                    Description = $moduleInfo[1]
                    Type        = "Local"
                    Path        = $moduleInfo[0]
                }
            }
        }
    }
    
    # Search registry modules
    $registryResults = @()
    $registry = Get-ModuleRegistry
    if ($registry) {
        foreach ($moduleName in $registry.Modules.Keys) {
            $moduleInfo = $registry.Modules[$moduleName]
            
            # Get latest version metadata (for now, just take the first version)
            $latestVersion = $moduleInfo.versions.Keys | Select-Object -First 1
            $metadata = $moduleInfo.versions[$latestVersion]
            
            # Apply filters
            $isMatch = $true
            
            # Text search
            if ($SearchTerm -and $isMatch) {
                $searchFields = @($metadata.Name, $metadata.Description, ($metadata.Tags -join " "))
                $isMatch = $searchFields | Where-Object { $_ -like "*$SearchTerm*" }
            }
            
            # Tag filter
            if ($Tags.Count -gt 0 -and $isMatch) {
                $hasMatchingTag = $false
                foreach ($tag in $Tags) {
                    if ($metadata.Tags -contains $tag) {
                        $hasMatchingTag = $true
                        break
                    }
                }
                $isMatch = $hasMatchingTag
            }
            
            # Category filter
            if ($Category -and $isMatch) {
                $isMatch = $metadata.Categories -contains $Category
            }
            
            # Author filter
            if ($Author -and $isMatch) {
                $isMatch = $metadata.Author -like "*$Author*"
            }
            
            # Rating filter
            if ($MinRating -gt 0 -and $isMatch) {
                $avgRating = if ($moduleInfo.ratings -and $moduleInfo.ratings.Count -gt 0) {
                    [math]::Round(($moduleInfo.ratings | ForEach-Object { $_.Rating } | Measure-Object -Average).Average, 2)
                }
                else { 0 }
                $isMatch = $avgRating -ge $MinRating
            }
            
            if ($isMatch) {
                $result = [PSCustomObject]@{
                    Name         = $metadata.Name
                    Version      = $metadata.Version
                    Author       = $metadata.Author
                    Description  = $metadata.Description
                    Tags         = $metadata.Tags
                    Categories   = $metadata.Categories
                    Rating       = if ($moduleInfo.ratings) { 
                        [math]::Round(($moduleInfo.ratings | ForEach-Object { $_.Rating } | Measure-Object -Average).Average, 2)
                    }
                    else { 0 }
                    RatingCount  = if ($moduleInfo.ratings) { $moduleInfo.ratings.Count } else { 0 }
                    InstallCount = if ($moduleInfo.stats) { $moduleInfo.stats.InstallCount } else { 0 }
                    LastUpdated  = if ($metadata.LastUpdated) { [datetime]$metadata.LastUpdated } else { Get-Date }
                    Repository   = $metadata.Repository
                    License      = $metadata.License
                    Type         = "Registry"
                }
                $registryResults += $result
            }
        }
    }
    
    # Display results in categories
    Write-Host "SEARCH RESULTS" -ForegroundColor Cyan
    if ($SearchTerm) {
        Write-Host "Search term: '$SearchTerm'" -ForegroundColor DarkGray
    }
    Write-Host ("=" * 80) -ForegroundColor DarkGray
    
    # Display local modules
    if ($localResults.Count -gt 0) {
        Write-Host ""
        Write-Host "LOCAL MODULES ($($localResults.Count) found)" -ForegroundColor Yellow
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        foreach ($result in ($localResults | Sort-Object Name)) {
            Write-Host "  $($result.Name)" -ForegroundColor White -NoNewline
            Write-Host " - $($result.Description)" -ForegroundColor DarkGray
        }
    }
    
    # Display registry modules  
    if ($registryResults.Count -gt 0) {
        Write-Host ""
        Write-Host "SHARED REGISTRY ($($registryResults.Count) found)" -ForegroundColor Green
        Write-Host ("-" * 40) -ForegroundColor DarkGray
        foreach ($result in ($registryResults | Sort-Object Name)) {
            Write-Host "  $($result.Name)" -ForegroundColor White -NoNewline
            Write-Host " v$($result.Version)" -ForegroundColor Green -NoNewline
            Write-Host " by $($result.Author)" -ForegroundColor DarkGray -NoNewline
            if ($result.Rating -gt 0) {
                Write-Host " ⭐$($result.Rating)" -ForegroundColor Yellow -NoNewline
                Write-Host " ($($result.RatingCount))" -ForegroundColor DarkGray -NoNewline
            }
            Write-Host ""
            Write-Host "    $($result.Description)" -ForegroundColor DarkGray
            if ($result.Tags -and $result.Tags.Count -gt 0) {
                Write-Host "    Tags: $($result.Tags -join ', ')" -ForegroundColor DarkGray
            }
        }
    }
    
    # Summary
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor DarkGray
    $totalResults = $localResults.Count + $registryResults.Count
    Write-Host "Total: $totalResults modules found ($($localResults.Count) local, $($registryResults.Count) registry)" -ForegroundColor Cyan
    
    return @{
        Local    = $localResults
        Registry = $registryResults
        Total    = $totalResults
    }
}

# Install module with dependency resolution
function Install-CobraModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [string]$Version = "latest",
        [switch]$Force,
        [switch]$NoDependencies
    )
    
    Log-CobraActivity "Installing module: $ModuleName (Version: $Version)"
    
    try {
        # Resolve dependencies
        $dependencies = if ($NoDependencies) { 
            @([PSCustomObject]@{ Name = $ModuleName; Version = $Version })
        }
        else {
            Resolve-ModuleDependencies -ModuleName $ModuleName -Version $Version
        }
        
        if ($dependencies.Count -eq 0) {
            Write-Host "No modules to install." -ForegroundColor Yellow
            return $false
        }
        
        Write-Host "Installation plan:" -ForegroundColor Cyan
        foreach ($dep in $dependencies) {
            Write-Host "  - $($dep.Name) v$($dep.Version)" -ForegroundColor White
        }
        
        if (-not $Force) {
            $confirm = Read-Host "Continue with installation? (y/N)"
            if ($confirm -notmatch '^[yY]') {
                Write-Host "Installation cancelled." -ForegroundColor Yellow
                return $false
            }
        }
        
        # Install each module
        $installed = @()
        foreach ($dep in $dependencies) {
            $installResult = Install-SingleModule -ModuleName $dep.Name -Version $dep.Version -Force:$Force
            if ($installResult) {
                $installed += $dep.Name
                Update-ModuleInstallStats -ModuleName $dep.Name
            }
            else {
                Write-Host "Failed to install: $($dep.Name)" -ForegroundColor Red
                # Rollback installed modules
                foreach ($installedModule in $installed) {
                    Uninstall-CobraModule -ModuleName $installedModule -Force
                }
                return $false
            }
        }
        
        Write-Host "Successfully installed $($installed.Count) modules." -ForegroundColor Green
        Log-CobraActivity "Successfully installed modules: $($installed -join ', ')"
        return $true
    }
    catch {
        Write-Host "Installation failed: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Module installation failed: $($_.Exception.Message)"
        return $false
    }
}

function CobraModulesDriver([string] $command, [string[]] $options) {
    switch ($command.ToLower()) {
        "list" {
            Write-Host "LOCAL COBRA MODULES" -ForegroundColor Cyan
            Write-Host ("=" * 40) -ForegroundColor DarkGray
            if ($global:CobraScriptModules) {
                $sortedModules = $global:CobraScriptModules.GetEnumerator() | Sort-Object -Property Key
                foreach ($module in $sortedModules) {
                    Write-Host "  $($module.Key)" -ForegroundColor White -NoNewline
                    Write-Host " - $($module.Value[1])" -ForegroundColor DarkGray
                }
                Write-Host ""
                Write-Host "Total: $($global:CobraScriptModules.Count) local modules installed" -ForegroundColor Cyan
            }
            else {
                Write-Host "  No modules installed locally." -ForegroundColor Yellow
                Write-Host ""
                Write-Host "Use 'cobra modules search' to find modules to install" -ForegroundColor DarkGray
                Write-Host "Use 'cobra modules install <name>' to install from registry" -ForegroundColor DarkGray
            }
        }
        "registry" {
            $action = if ($options.Count -gt 0) { $options[0] } else { "list" }
            $moduleName = if ($options.Count -gt 1) { $options[1] } else { $null }
            $searchTerm = if ($options.Count -gt 1) { $options[1] } else { $null }
            
            # Handle open command specially for debugging
            if ($action -eq "open") {
                $registryPath = $global:CobraConfig.ModuleRegistryLocation
                if (Test-Path $registryPath) {
                    Write-Host "Opening registry location: $registryPath" -ForegroundColor Cyan
                    try {
                        Start-Process explorer.exe -ArgumentList $registryPath
                        Log-CobraActivity "Opened module registry location: $registryPath"
                    }
                    catch {
                        Write-Host "Error opening explorer: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
                else {
                    Write-Host "Registry path not found: $registryPath" -ForegroundColor Red
                    Write-Host "Run 'cobra modules registry init' to initialize the registry" -ForegroundColor Yellow
                }
            }
            else {
                Get-ModuleRegistryInfo -Action $action -ModuleName $moduleName -SearchTerm $searchTerm
            }
        }
        "search" {
            $searchTerm = if ($options.Count -gt 0) { $options[0] } else { "" }
            $results = Search-Modules -SearchTerm $searchTerm
            # Search-Modules now handles display internally, just check if no results
            if ($results.Total -eq 0) {
                if ($searchTerm) {
                    Write-Host "No modules found matching '$searchTerm'" -ForegroundColor Yellow
                }
                else {
                    Write-Host "No modules found" -ForegroundColor Yellow
                }
            }
        }
        "install" {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                $version = "latest"
                $force = $false
                
                # Parse remaining options
                for ($i = 1; $i -lt $options.Count; $i++) {
                    $opt = $options[$i]
                    if ($opt -eq "-Force" -or $opt -eq "--force" -or $opt -eq "-f") {
                        $force = $true
                    }
                    elseif ($opt -match "^\d+\.\d+\.\d+$") {
                        # Version number
                        $version = $opt
                    }
                    elseif ($opt -notmatch "^-") {
                        # Assume it's a version if not a flag
                        $version = $opt
                    }
                }
                
                Install-CobraModule -ModuleName $moduleName -Version $version -Force:$force
            }
            else {
                Write-Host "Usage: cobra modules install <module-name> [version] [-Force]" -ForegroundColor Red
                Write-Host "Examples:" -ForegroundColor Yellow
                Write-Host "  cobra modules install Code" -ForegroundColor Cyan
                Write-Host "  cobra modules install Code 1.2.0" -ForegroundColor Cyan
                Write-Host "  cobra modules install Code -Force" -ForegroundColor Cyan
            }
        }
        "add" {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                $template = if ($options.Count -gt 1) { $options[1] } else { "basic-module" }
                Add-CobraScriptModule -name $moduleName -template $template
            }
            else {
                Write-Host "Usage: cobra modules add <module-name> [template]" -ForegroundColor Red
                Write-Host "Creates a new local module using templates" -ForegroundColor DarkGray
                Write-Host "Available templates: basic-module, standalone-module" -ForegroundColor DarkGray
            }
        }
        "uninstall" {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                Remove-CobraScriptModule -name $moduleName
            }
            else {
                Write-Host "Usage: cobra modules uninstall <module-name>" -ForegroundColor Red
                Write-Host "Uninstalls a locally installed module" -ForegroundColor DarkGray
            }
        }
        "edit" {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                Edit-CobraScriptModule -name $moduleName
            }
            else {
                Write-Host "Usage: cobra modules edit <module-name>" -ForegroundColor Red
                Write-Host "Opens a module for editing in your default editor" -ForegroundColor DarkGray
            }
        }
        "import" {
            if ($options.Count -gt 1) {
                $moduleName = $options[0]
                $artifactPath = $options[1]
                Import-CobraModule -ModuleName $moduleName -ArtifactPath $artifactPath
            }
            else {
                Write-Host "Usage: cobra modules import <module-name> <artifact-path>" -ForegroundColor Red
                Write-Host "Imports a module from a ZIP artifact" -ForegroundColor DarkGray
            }
        }
        "export" {
            if ($options.Count -gt 1) {
                $moduleName = $options[0]
                $artifactPath = $options[1]
                Export-CobraModule -ModuleName $moduleName -ArtifactPath $artifactPath
            }
            else {
                Write-Host "Usage: cobra modules export <module-name> <artifact-path>" -ForegroundColor Red
                Write-Host "Exports a module to a ZIP artifact" -ForegroundColor DarkGray
            }
        }
        "rate" {
            if ($options.Count -gt 1) {
                $moduleName = $options[0]
                $rating = [int]$options[1]
                $comment = if ($options.Count -gt 2) { $options[2..($options.Count - 1)] -join " " } else { "" }
                Set-CobraModuleRating -ModuleName $moduleName -Rating $rating -Comment $comment
            }
            else {
                Write-Host "Usage: cobra modules rate <module-name> <1-5> [comment]" -ForegroundColor Red
                Write-Host "Rate and review a module in the marketplace" -ForegroundColor DarkGray
            }
        }
        "info" {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                Get-CobraModuleInfo -ModuleName $moduleName
            }
            else {
                Write-Host "Usage: cobra modules info <module-name>" -ForegroundColor Red
                Write-Host "Get detailed information about a module" -ForegroundColor DarkGray
            }
        }
        "update" {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                Update-CobraModule -ModuleName $moduleName
            }
            else {
                Write-Host "Usage: cobra modules update <module-name>" -ForegroundColor Red
                Write-Host "Updates a module to the latest version from the registry" -ForegroundColor DarkGray
            }
        }
        "publish" {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                $version = $null
                
                # Parse version from various formats
                for ($i = 1; $i -lt $options.Count; $i++) {
                    $opt = $options[$i]
                    if ($opt -eq "-version" -or $opt -eq "--version" -or $opt -eq "-v") {
                        if ($i + 1 -lt $options.Count) {
                            $version = $options[$i + 1]
                            break
                        }
                    }
                    elseif ($opt -match "^\d+\.\d+\.\d+$") {
                        # Positional version argument (e.g., cobra modules publish ModuleName 1.2.0)
                        $version = $opt
                        break
                    }
                }
                
                # If no version specified, auto-increment from existing versions in registry
                if (-not $version) {
                    $version = Get-NextModuleVersion -ModuleName $moduleName
                }
                
                Publish-CobraModule -ModuleName $moduleName -Version $version
            }
            else {
                Write-Host "Usage: cobra modules publish <module-name> [version] or [-version <version>]" -ForegroundColor Red
                Write-Host "Examples:" -ForegroundColor Yellow
                Write-Host "  cobra modules publish MyModule 1.2.0" -ForegroundColor Cyan
                Write-Host "  cobra modules publish MyModule -version 1.2.0" -ForegroundColor Cyan
                Write-Host "  cobra modules publish MyModule (auto-increments version)" -ForegroundColor Cyan
            }
        }
        default {
            Write-Host "Available commands: list, add, uninstall, edit, import, export, registry, search, install, update, rate, info, publish" -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Local module management:" -ForegroundColor DarkGray
            Write-Host "  cobra modules add MyModule" -ForegroundColor Cyan
            Write-Host "  cobra modules edit MyModule" -ForegroundColor Cyan
            Write-Host "  cobra modules uninstall MyModule" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Registry operations:" -ForegroundColor DarkGray
            Write-Host "  cobra modules registry init" -ForegroundColor Cyan
            Write-Host "  cobra modules registry list" -ForegroundColor Cyan
            Write-Host "  cobra modules search development" -ForegroundColor Cyan
            Write-Host "  cobra modules install MyModule" -ForegroundColor Cyan
            Write-Host "  cobra modules publish MyModule" -ForegroundColor Cyan
        }
    }

    # Log module operations
    Log-CobraActivity "Executed $command command with options: $($options -join ', ')"
}

function ShowCobraScriptModules() {
    write-host "AVAILABLE COBRA MODULES" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------" -ForegroundColor DarkGray
    if ($global:CobraScriptModules) {
        $global:CobraScriptModules.GetEnumerator() | Sort-Object -Property Key | ForEach-Object {
            Write-Host " $($_.Key) " -NoNewline
            write-host "- $($_.Value[1])" -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "No modules loaded." -ForegroundColor Yellow
    }
}

# Core module management functions
function Add-CobraScriptModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$name,
        
        [ValidateSet("basic-module", "standalone-module")]
        [string]$template = "basic-module"
    )
    
    try {
        # Check if module already exists
        $modulePath = Join-Path $global:CobraConfig.CobraRoot "Modules\$name"
        if (Test-Path $modulePath) {
            Write-Host "Module '$name' already exists at: $modulePath" -ForegroundColor Yellow
            return
        }
        
        # Create the module from template
        New-CobraModuleFromTemplate -TemplateName $template -ModuleName $name
        
        Write-Host "Module '$name' created successfully!" -ForegroundColor Green
        Write-Host "Location: $modulePath" -ForegroundColor DarkGray
        
        if ($template -eq "standalone-module") {
            Write-Host "✓ Standalone module created - type '$name' or '$($name.ToLower())' for help" -ForegroundColor Cyan
        }
        else {
            Write-Host "Use 'cobra modules edit $name' to start editing" -ForegroundColor Cyan
        }
        
        Log-CobraActivity "Created new module: $name (template: $template)"
    }
    catch {
        Write-Host "Error creating module '$name': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error creating module '$name': $($_.Exception.Message)"
    }
}

function Remove-CobraScriptModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$name
    )
    
    try {
        # Check if module exists in global modules
        if (-not $global:CobraScriptModules.ContainsKey($name)) {
            Write-Host "Module '$name' is not currently loaded/installed" -ForegroundColor Yellow
            return
        }
        
        # Get module path
        $modulePath = Join-Path $global:CobraConfig.CobraRoot "Modules\$name"
        
        # Confirm removal
        Write-Host "This will remove the module '$name' and all its files." -ForegroundColor Yellow
        $confirmation = Read-Host "Are you sure you want to continue? (y/N)"
        
        if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
            # Remove from global modules collection
            $global:CobraScriptModules.Remove($name)
            
            # Remove the module directory if it exists
            if (Test-Path $modulePath) {
                Remove-Item -Path $modulePath -Recurse -Force
                Write-Host "Module '$name' removed successfully" -ForegroundColor Green
                Log-CobraActivity "Removed module: $name"
            }
            else {
                Write-Host "Module '$name' removed from loaded modules (directory not found)" -ForegroundColor Green
                Log-CobraActivity "Removed module from memory: $name"
            }
        }
        else {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Error removing module '$name': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error removing module '$name': $($_.Exception.Message)"
    }
}

function Edit-CobraScriptModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$name
    )
    
    try {
        $modulePath = Join-Path $global:CobraConfig.CobraRoot "Modules\$name"
        
        if (-not (Test-Path $modulePath)) {
            Write-Host "Module '$name' not found at: $modulePath" -ForegroundColor Red
            Write-Host "Use 'cobra modules add $name' to create it first" -ForegroundColor Yellow
            return
        }
        
        # Get all files in the module directory
        $moduleFiles = Get-ChildItem -Path $modulePath -File -Recurse | Where-Object { 
            $_.Extension -in @('.ps1', '.psm1', '.psd1', '.json', '.md', '.txt', '.config', '.xml', '.yaml', '.yml') 
        }
        
        if ($moduleFiles.Count -eq 0) {
            Write-Host "No editable files found in module directory: $modulePath" -ForegroundColor Yellow
            return
        }
        
        # Open all module files in default editor
        Write-Host "Opening module '$name' files for editing..." -ForegroundColor Cyan
        Write-Host "Found $($moduleFiles.Count) files to open:" -ForegroundColor DarkGray
        
        foreach ($file in $moduleFiles) {
            Write-Host "  - $($file.Name)" -ForegroundColor DarkGray
            Start-Process $file.FullName
        }
        
        Log-CobraActivity "Opened module for editing: $name ($($moduleFiles.Count) files)"
    }
    catch {
        Write-Host "Error opening module '$name': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error opening module '$name': $($_.Exception.Message)"
    }
}

function Import-CobraModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )
    
    try {
        if (-not (Test-Path $ArtifactPath)) {
            Write-Host "Artifact file not found: $ArtifactPath" -ForegroundColor Red
            return
        }
        
        $modulesPath = Join-Path $global:CobraConfig.CobraRoot "Modules"
        $destinationPath = Join-Path $modulesPath $ModuleName
        
        # Extract the ZIP file
        Write-Host "Importing module '$ModuleName' from artifact..." -ForegroundColor Cyan
        Expand-Archive -Path $ArtifactPath -DestinationPath $destinationPath -Force
        
        # Reload modules
        Import-CobraModules
        
        Write-Host "Module '$ModuleName' imported successfully!" -ForegroundColor Green
        Log-CobraActivity "Imported module: $ModuleName from $ArtifactPath"
    }
    catch {
        Write-Host "Error importing module '$ModuleName': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error importing module '$ModuleName': $($_.Exception.Message)"
    }
}

function Export-CobraModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [string]$ArtifactPath
    )
    
    try {
        $modulePath = Join-Path $global:CobraConfig.CobraRoot "Modules\$ModuleName"
        
        if (-not (Test-Path $modulePath)) {
            Write-Host "Module '$ModuleName' not found at: $modulePath" -ForegroundColor Red
            return
        }
        
        # Create the ZIP file
        Write-Host "Exporting module '$ModuleName' to artifact..." -ForegroundColor Cyan
        Compress-Archive -Path $modulePath -DestinationPath $ArtifactPath -Force
        
        Write-Host "Module '$ModuleName' exported successfully to: $ArtifactPath" -ForegroundColor Green
        Log-CobraActivity "Exported module: $ModuleName to $ArtifactPath"
    }
    catch {
        Write-Host "Error exporting module '$ModuleName': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error exporting module '$ModuleName': $($_.Exception.Message)"
    }
}

function Set-CobraModuleRating {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $true)]
        [ValidateRange(1, 5)]
        [int]$Rating,
        
        [Parameter(Mandatory = $false)]
        [string]$Comment = ""
    )
    
    try {
        Set-ModuleRating -ModuleName $ModuleName -Rating $Rating -Comment $Comment -UserName $env:USERNAME
        Write-Host "Rating submitted for module '$ModuleName': $Rating stars" -ForegroundColor Green
        if ($Comment) {
            Write-Host "Comment: $Comment" -ForegroundColor DarkGray
        }
        Log-CobraActivity "Rated module: $ModuleName ($Rating stars)"
    }
    catch {
        Write-Host "Error rating module '$ModuleName': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error rating module '$ModuleName': $($_.Exception.Message)"
    }
}

function Get-CobraModuleInfo {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    try {
        # Check if it's a local module first
        if ($global:CobraScriptModules.ContainsKey($ModuleName)) {
            Write-Host "LOCAL MODULE INFORMATION" -ForegroundColor Cyan
            Write-Host ("=" * 50) -ForegroundColor DarkGray
            Write-Host "Name: " -NoNewline; Write-Host $ModuleName -ForegroundColor White
            Write-Host "Description: " -NoNewline; Write-Host $global:CobraScriptModules[$ModuleName][1] -ForegroundColor White
            Write-Host "Path: " -NoNewline; Write-Host $global:CobraScriptModules[$ModuleName][0] -ForegroundColor DarkGray
            Write-Host "Status: " -NoNewline; Write-Host "Locally installed" -ForegroundColor Green
        }
        
        # Also check registry
        $registry = Get-ModuleRegistry
        if ($registry -and $registry.Modules.ContainsKey($ModuleName)) {
            $moduleInfo = $registry.Modules[$ModuleName]
            $latestVersion = ($moduleInfo.versions.Keys | Sort-Object -Descending)[0]
            $metadata = $moduleInfo.versions[$latestVersion]
            
            Write-Host ""
            Write-Host "REGISTRY MODULE INFORMATION" -ForegroundColor Cyan
            Write-Host ("=" * 50) -ForegroundColor DarkGray
            Write-Host "Name: " -NoNewline; Write-Host $metadata.Name -ForegroundColor White
            Write-Host "Latest Version: " -NoNewline; Write-Host $metadata.Version -ForegroundColor Green
            Write-Host "Author: " -NoNewline; Write-Host $metadata.Author -ForegroundColor White
            Write-Host "Description: " -NoNewline; Write-Host $metadata.Description -ForegroundColor White
            
            if ($metadata.Tags.Count -gt 0) {
                Write-Host "Tags: " -NoNewline; Write-Host ($metadata.Tags -join ", ") -ForegroundColor Cyan
            }
            
            # Show ratings
            if ($moduleInfo.ratings -and $moduleInfo.ratings.Count -gt 0) {
                $avgRating = [math]::Round(($moduleInfo.ratings | ForEach-Object { $_.Rating } | Measure-Object -Average).Average, 1)
                Write-Host "Average Rating: " -NoNewline; Write-Host "$avgRating ⭐ ($($moduleInfo.ratings.Count) reviews)" -ForegroundColor Yellow
            }
            
            # Show install count
            if ($moduleInfo.stats) {
                Write-Host "Install Count: " -NoNewline; Write-Host $moduleInfo.stats.InstallCount -ForegroundColor Cyan
            }
        }
        
        if (-not $global:CobraScriptModules.ContainsKey($ModuleName) -and (-not $registry -or -not $registry.Modules.ContainsKey($ModuleName))) {
            Write-Host "Module '$ModuleName' not found locally or in registry" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error getting module info for '$ModuleName': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error getting module info '$ModuleName': $($_.Exception.Message)"
    }
}

function Update-CobraModule {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModuleName
    )
    
    try {
        # Check if module is in registry
        $registry = Get-ModuleRegistry
        if (-not $registry -or -not $registry.Modules.ContainsKey($ModuleName)) {
            Write-Host "Module '$ModuleName' not found in registry" -ForegroundColor Red
            return
        }
        
        # Check if module is installed locally
        if ($global:CobraScriptModules.ContainsKey($ModuleName)) {
            Write-Host "Local version found, checking for updates..." -ForegroundColor Cyan
        }
        
        # Install latest version
        Install-CobraModule -ModuleName $ModuleName -Version "latest"
        
        Log-CobraActivity "Updated module: $ModuleName"
    }
    catch {
        Write-Host "Error updating module '$ModuleName': $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error updating module '$ModuleName': $($_.Exception.Message)"
    }
}
