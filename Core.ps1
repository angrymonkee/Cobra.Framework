$global:coreScriptLoaded = $true

# Profile Hashtable - Allows Cobra to know which modules are loaded (default is "Cobra")
if ($null -eq $global:CobraScriptModules) {
    $global:CobraScriptModules = @{}
}

# =================== Shared Cobra State ==================
$global:currentAppConfig = $null
$global:goTaskStore = @{}
$global:AppConfigs = @{}
$global:requiredKeys = @("Name", "Repo", "AuthMethod", "SetupMethod", "BuildMethod", "TestMethod", "RunMethod", "DevMethod", "ReviewPullRequests", "OpenPullRequest")

# ================= Core Functions =================

function Register-CobraRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Config
    )
    
    # Register the repository configuration
    $global:AppConfigs[$Name] = $Config

    # Register the repository in CobraScriptModules
    $global:CobraScriptModules[$Name] = @($Name, $Description)
    Write-Verbose "Registered repository: $Name"
}

function New-ModuleConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$moduleName
    )
    # Get the module directory
    $moduleDir = Join-Path $PSScriptRoot'\Modules' "$moduleName"
    write-host "Initializing module script: $($moduleDir)"

    # Get the module template file path
    $configPath = Join-Path $moduleDir "config.ps1"

    # Create the config hashtable
    $configString = @"
    @{
        Name           = "$($moduleName)"
        Repo           = "" # Enter the repository path here
        AuthMethod     = "Authenticate-$($moduleName)Repo"
        SetupMethod    = "Configure-$($moduleName)Repo"
        BuildMethod    = "Build-$($moduleName)Repo"
        TestMethod     = "Test-$($moduleName)Repo"
        RunMethod      = "Execute-$($moduleName)Repo"
        DevMethod      = "Develop-$($moduleName)Repo"
        ReviewPullRequests = "Read-$($moduleName)PullRequests"
        OpenPullRequest    = "Open-$($moduleName)PullRequestById"
        GoLocations    = @{}
    }
"@
    
    Set-Content -Path $configPath -Value ($configString | Out-String)
    
    Write-Host "Module Config Created: $($configString)"
}

function New-ModuleTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$moduleName
    )

    # Get the module directory
    $moduleDir = Join-Path $PSScriptRoot'\Modules' "$moduleName"
    write-host "Initializing module script: $($moduleDir)"

    # Get the module template file path
    $modulePath = Join-Path $moduleDir "$moduleName.psm1"

    $moduleContent = @"
function Initialize-$($moduleName)Module {
    [CmdletBinding()]
    param()
    
    # Load repository-specific configuration
    `$config = . "`$PSScriptRoot/config.ps1"
    
    # Register the repository with Cobra
    Register-CobraRepository -Name "$($moduleName)" -Description "$($moduleName)" -Config `$config
}

# Repository-specific functions
function Authenticate-$($moduleName)Repo { # Renamed from Auth-$($moduleName)Repo
    [CmdletBinding()]
    param()
    
    Write-Host "Authenticating with $($moduleName) repository..."
    # Add authentication logic here
}

function Configure-$($moduleName)Repo { # Renamed from Setup-$($moduleName)Repo
    [CmdletBinding()]
    param()
    
    Write-Host "Configuring $($moduleName) repository..."
    # Add setup logic here
}

function Build-$($moduleName)Repo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$false)]
        [ValidateSet('Build', 'BuildAll', 'Rebuild')]
        [string]`$BuildType = 'Build'
    )
    
    Write-Host "Building $($moduleName) repository with type: `$BuildType"
    # Add build logic here
}

function Test-$($moduleName)Repo {
    [CmdletBinding()]
    param()
    
    Write-Host "Testing $($moduleName) repository..."
    # Add test logic here
}

function Execute-$($moduleName)Repo { # Renamed from Run-$($moduleName)Repo
    [CmdletBinding()]
    param()
    
    Write-Host "Executing $($moduleName) repository..."
    # Add run logic here
}

function Develop-$($moduleName)Repo { # Renamed from Dev-$($moduleName)Repo
    [CmdletBinding()]
    param()
    
    Write-Host "Starting development environment for $($moduleName) repository..."
    # Add development environment setup logic here
}

function Help-$($moduleName)Repo {
    [CmdletBinding()]
    param()
    
    Write-Host "Displaying help for $($moduleName) repository..."
    # Add help logic here
}
set-alias -Name $($moduleName) -Value Help-$($moduleName)Repo -Scope Global

function Read-$($moduleName)PullRequests {
    Get-AzureDevOpsPRs -repo "<repo name>" `
        -project "<project name>" `
        -organization "<organization>" `
        -reviewer `$global:CobraConfig.OwnerEmail
}

function Open-$($moduleName)PullRequestById ([int]`$pullRequestId) {
    Start-Process "<URL location of PR details page>/`$pullRequestId"
}

# Export the initialization function and repository-specific functions
Export-ModuleMember -Function Initialize-$($moduleName)Module, Authenticate-$($moduleName)Repo, Configure-$($moduleName)Repo, Build-$($moduleName)Repo, Test-$($moduleName)Repo, Execute-$($moduleName)Repo, Develop-$($moduleName)Repo, Help-$($moduleName)Repo, Read-$($moduleName)PullRequests, Open-$($moduleName)PullRequestById
"@

    Set-Content -Path $modulePath -Value ($moduleContent | Out-String)
    Write-Host "Module Template Created: $($moduleName)"
}

function Update-ModuleConfigFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$moduleName
    )

    # Get the module directory
    $moduleDir = Join-Path $PSScriptRoot'\Modules' "$moduleName"
    $configPath = Join-Path $moduleDir "config.ps1"
    write-host "Updating module config: $configPath"

    $config = $global:currentAppConfig
    if ($null -eq $configPath) {
        Write-Error "ConfigLocation is not set in the current app config."
        return
    }
    
    $goLocationsString = foreach ($key in $config.GoLocations.Keys) {
        $value = $config.GoLocations[$key]
        "$key = @('$($value[0])', '$($value[1])')" + [Environment]::NewLine
    }

    # Save the updated config back to the file
    $configString = @"
@{
    Name           = "$($config.Name)"
    Repo           = "$($config.Repo)"
    AuthMethod     = "$($config.AuthMethod)"
    SetupMethod    = "$($config.SetupMethod)"
    BuildMethod    = "$($config.BuildMethod)"
    TestMethod     = "$($config.TestMethod)"
    RunMethod      = "$($config.RunMethod)"
    DevMethod      = "$($config.DevMethod)"
    ReviewPullRequests = "$($config.ReviewPullRequests)"
    OpenPullRequest    = "$($config.OpenPullRequest)"
    GoLocations    = @{
    $($goLocationsString)}
}
"@
    $configString | Out-String | Set-Content -Path $configPath

    Write-Host "Module Config Written: $($config)"
}

function Import-CobraModules {
    [CmdletBinding()]
    param()
    
    $modulesPath = Join-Path $PSScriptRoot "Modules"
    $modules = Get-ChildItem -Path $modulesPath -Directory
    
    foreach ($module in $modules) {
        $modulePath = Join-Path $module.FullName "$($module.Name).psm1"
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force -DisableNameChecking
            # Initialize the module
            & "Initialize-$($module.Name)Module"
        }
    }
}

function GetAppConfig([string] $name) {
    try {
        if (-not $global:AppConfigs.ContainsKey($name)) {
            throw "Repository configuration not found: $name"
        }
        return $global:AppConfigs[$name]
    }
    catch {
        Write-Error "Failed to get app config: $_"
        throw
    }
}

function GetCurrentAppConfig() {
    if ($null -eq $global:currentAppConfig) {
        Write-Host "GetCurrentAppConfig: No current app config set."
        return $null
    }
    return $global:currentAppConfig
}

# ================= Shared Functions =================
function VerifyInRepo([string]$repo) {
    $src = Get-Location

    write-host "repo: $repo"
    $cleanRepo = "$($repo -replace "\\\\", "\")"
    # write-host "cleanRepo: $cleanRepo"
    if (-not (Test-Path $cleanRepo)) {
        # Assume the repository is in the code repo
        $cleanRepo = "$($global:CobraConfig.CodeRepo)\$($repo -replace "\\\\", "\")"
        write-host "Checking code repo, cleanRepo: $cleanRepo"
    }

    # If path doesn't start with a drive letter, assume it's a relative path
    # and join it with the current drive letter
    if (-not ($cleanRepo -match "^[a-zA-Z]:\\")) {
        $cleanRepo = Join-Path -Path "$($src.Drive.Name):" -ChildPath $cleanRepo
        write-host "Relative path: $cleanRepo"
    }

    # If path doesn't match the current directory, return false
    if (-not $src.Path.Equals($cleanRepo)) {
        Write-Host "Please run this script from $cleanRepo repository."
        return $false
    }

    return $true
}

function ShouldContinue {
    param (
        [string]$msg,
        [string]$default = "Y"
    )

    $shouldContinue = Read-Host "$msg (Y/N)? [$default]"
    if ([string]::IsNullOrWhiteSpace($shouldContinue)) {
        $shouldContinue = $default
    }

    return $shouldContinue -ieq 'Y'
}

function Get-AzureDevOpsPRs ([string]$repo, [string]$project, [string]$organization, [string]$reviewer) {
    az repos pr list --repository "$repo" --project "$project" --organization "$organization" --output json | ConvertFrom-Json | ForEach-Object {
        # Ensure each PR is processed as an individual object
        $_ | Where-Object {
            $_.reviewers | Where-Object { $_.uniqueName -eq "$reviewer" }
        } | ForEach-Object {
            [PSCustomObject]@{
                PR_ID     = $_.pullRequestId
                Title     = $_.title
                CreatedBy = $_.createdBy.displayName
                Status    = $_.status
            }
        }
    } | Format-Table -AutoSize
}

function SendMessage ([string]$message, [string]$recipient) {

    # Placeholder for sending a message to a recipient
    Write-Host "Sending message to $($recipient): $message"
}

function Log-CobraActivity {
    param (
        [string]$message
    )

    # Define the log file path
    $logFilePath = Join-Path $PSScriptRoot "CobraActivity.log"

    # Get the current timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Format the log entry
    $logEntry = "$timestamp - $message"

    # Append the log entry to the log file
    Add-Content -Path $logFilePath -Value $logEntry
}

function CheckHealth {
    param (
        [string]$target = "all" # Options: "all", "modules", "repositories"
    )

    Write-Host "Running health checks for: $target" -ForegroundColor Cyan

    switch ($target) {
        "all" {
            CheckModulesHealth
            CheckRepositoriesHealth
        }
        "modules" {
            CheckModulesHealth
        }
        "repositories" {
            CheckRepositoriesHealth
        }
        default {
            Write-Host "Invalid target specified. Use 'all', 'modules', or 'repositories'." -ForegroundColor Red
        }
    }
}

function CheckModulesHealth {
    Write-Host "Checking module health..." -ForegroundColor Yellow

    foreach ($module in $global:CobraScriptModules.Keys) {
        $modulePath = Join-Path $PSScriptRoot "Modules\$module"
        $configPath = Join-Path $modulePath "config.ps1"

        if (-not (Test-Path $modulePath)) {
            Write-Host "Module '$module' is missing at path: $modulePath" -ForegroundColor Red
        }
        elseif (-not (Test-Path $configPath)) {
            Write-Host "Module '$module' is missing its config.ps1 file at path: $configPath" -ForegroundColor Red
        }
        else {
            Write-Host "Module '$module' is healthy." -ForegroundColor Green
            Write-Host "Validating config.ps1 values for module '$module'..." -ForegroundColor Cyan

            # Load the config.ps1 file
            $config = . $configPath

            foreach ($key in $requiredKeys) {
                if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
                    Write-Host "  Missing or empty value for key: $key" -ForegroundColor Red
                }
                else {
                    Write-Host "  Key '$key' is set to: $($config[$key])" -ForegroundColor Green
                }
            }
        }
    }
}

function CheckRepositoriesHealth {
    Write-Host "Checking repository health..." -ForegroundColor Yellow

    foreach ($appConfig in $global:AppConfigs.GetEnumerator()) {
        $repoPath = "$($global:CobraConfig.CodeRepo)\$($appConfig.Value.Repo)"
        if (-not (Test-Path $repoPath)) {
            Write-Host "Repository '$($appConfig.Key)' is missing at path: $repoPath" -ForegroundColor Red
        }
        else {
            Write-Host "Repository '$($appConfig.Key)' is healthy." -ForegroundColor Green
        }
    }
}

function Get-CobraConfig {
    return $global:CobraConfig
}

function GoToRepo([string]$repo) {
    Set-Location -Path $repo
}

function GoToUrl([string]$url) {
    Start-Process $url
}