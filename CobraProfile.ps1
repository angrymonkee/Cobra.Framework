# Import COBRA configuration file
. "$PSScriptRoot\config.ps1"

if (-not ($global:coreScriptLoaded)) {
    . "$env:COBRA_ROOT/CobraGen2/Core.ps1"
}

# ================= Configuration =================

# Profile Hashtable - Allows Cobra to know which modules are loaded (default is "Cobra")
$global:CobraScriptModules["cobra"] = @("Basic Cobra functionality", "CobraProfile.ps1")

# ================== Navigation Commands ==================
# Function to navigate to the desired code repository
function repo ([string] $name) {
    try {
        $appConfig = GetAppConfig $name

        if ($null -eq $appConfig) {
            Write-Host "AppConfig not found for $enumName" -ForegroundColor Red
            return
        }

        # Set the current app config
        $global:currentAppConfig = $appConfig
        Write-Host "Loaded $enumName configuration."

        # Check if CODE_REPO environment variable is set
        if (-not $global:CobraConfig.CodeRoot) {
            Write-Host "CODE_REPO environment variable is not set. Please run 'cobra init' to set environment variables." -ForegroundColor Red
            return
        }

        $repoLocation = "$($global:CobraConfig.CodeRoot)\$($appConfig.Repo)"
        if (-not (Test-Path $repoLocation)) {
            Write-Host "Invalid repository location: $repoLocation. Check configuration." -ForegroundColor Red
            return
        }

        GoToRepo($repoLocation)
        if ($null -ne $appConfig.GoLocations -and $appConfig.GoLocations.Count -gt 0) {
            $global:goTaskStore = $appConfig.GoLocations
            Write-Host "Loaded 'Go' locations."
        }
        else {
            write-host "No Go locations configured." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "An error occurred trying to load repository: $name"
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        write-host "---------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "'repo' HELP" -ForegroundColor DarkGray
        write-host "---------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Navigates to and loads the desired repository by repo name using the following format:" -ForegroundColor DarkGray
        Write-Host "    'repo <app name>'" -ForegroundColor DarkGray
        write-host
        Write-Host "Example:" -ForegroundColor DarkGray
        Write-Host "    PS>repo Code" -ForegroundColor DarkGray
        Write-Host
        Write-Host "Valid repository names:" -ForegroundColor DarkGray
        $global:AppConfigs.GetEnumerator() | Sort-Object -Property Key | ForEach-Object { Write-Host "    $($_.Key)"  -NoNewline
            write-host " - $($_.Value.Repo)" -ForegroundColor DarkGray }
    }
}

# ================== Go Commands ==================
function go ([string] $name) {
    try {
        if ($null -ne $global:goTaskStore -and $global:goTaskStore.ContainsKey($name) -eq $true) {
            Write-Host "Opening URL $name"
            GoToUrl $global:goTaskStore[$name][1]
        }
        else {
            Write-Host "'GO' HELP" -ForegroundColor DarkGray
            write-host "---------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "Opens a named location, using the following format:" -ForegroundColor DarkGray
            Write-Host "    'go <name>'" -ForegroundColor DarkGray
            write-host
            Write-Host "Example:" -ForegroundColor DarkGray
            Write-Host "    PS>go Docs" -ForegroundColor DarkGray
            Write-Host
            Write-Host "Valid 'Go' locations are:" -ForegroundColor DarkGray
            foreach ($key in $global:goTaskStore.Keys | sort-object) {
                Write-Host "    $key" -NoNewline
                write-host " - $($global:goTaskStore[$key][0])" -ForegroundColor DarkGray
            }
        }    
    }
    catch {
        go
    }
}

function Add-GoLocation {
    param (
        [string]$name,
        [string]$description,
        [string]$url
    )

    if ($null -eq $global:goTaskStore) {
        $global:goTaskStore = @{}
    }

    $global:goTaskStore[$name] = @($description, $url)
    $config = GetCurrentAppConfig
    Update-ModuleConfigFile $config.Name
    Write-Host "Added Go location: $name - $description"
}

function Remove-GoLocation {
    param (
        [string]$name
    )

    if ($null -ne $global:goTaskStore -and $global:goTaskStore.ContainsKey($name)) {
        $global:goTaskStore.Remove($name)
        $config = GetCurrentAppConfig
        Update-ModuleConfigFile $config.Name
        Write-Host "Removed Go location: $name"
    }
    else {
        Write-Host "Go location not found: $name" -ForegroundColor Red
    }
}

function Update-GoLocation {
    param (
        [string]$name,
        [string]$description,
        [string]$url
    )

    if ($null -ne $global:goTaskStore -and $global:goTaskStore.ContainsKey($name)) {
        $global:goTaskStore[$name] = @($description, $url)
        $config = GetCurrentAppConfig
        Update-ModuleConfigFile $config.Name
        Write-Host "Updated Go location: $name - $description"
    }
    else {
        Write-Host "Go location not found: $name" -ForegroundColor Red
    }
}


function SwitchSandbox ([string]$SandboxName) {
    if ($SandboxName -eq "") {
        Xblpcsandbox
        Write-Output "Common sandboxes: XDKS.1, MSFT.1, RETAIL"
    }
    else {
        Xblpcsandbox $SandboxName
    }
}

# ================== Developer Commands ==================
function AuthApp {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.AuthMethod -ne "") {
            & $appConfig.AuthMethod
        }
        else {
            write-host "No auth method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

function SetupApp {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.SetupMethod -ne "") {
            & $appConfig.SetupMethod
        }
        else {
            write-host "No setup method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

enum buildType {
    Build
    BuildAll
    Rebuild
}

function BuildApp ([buildType] $buildType = [buildType]::Build) {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.BuildMethod -ne "") {
            & $appConfig.BuildMethod $buildType
        }
        else {
            write-host "No build method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

function TestApp {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.TestMethod -ne "") {
            & $appConfig.TestMethod
        }
        else {
            write-host "No test method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

function RunApp { 
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.RunMethod -ne "") {
            & $appConfig.RunMethod
        }
        else {
            write-host "No run method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

Function RunPullRequestPrep { 
    BuildApp
    TestApp
}
Set-Alias -Name pr -Value RunPullRequestPrep

function AppInfo {
    $appConfig = (GetCurrentAppConfig)
    if ($null -eq $appConfig) {
        Write-Host "No app config found for this repo." -ForegroundColor Red
        return
    }

    $branch = git rev-parse --abbrev-ref HEAD

    write-host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "APPLICATION INFO" -ForegroundColor DarkGray
    write-host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "AppName:   " -NoNewline -ForegroundColor DarkYellow
    write-host "$($appConfig.Name)"
    Write-Host "Repo:      " -NoNewline -ForegroundColor DarkYellow
    write-host "$($appConfig.Repo)"
    Write-Host "Branch:    " -NoNewline -ForegroundColor DarkYellow
    write-host "$branch"
    Write-host "Methods:   " -NoNewline -ForegroundColor DarkYellow
    write-host "$($appConfig.AuthMethod), $($appConfig.SetupMethod), $($appConfig.BuildMethod), $($appConfig.TestMethod), $($appConfig.RunMethod), $($appConfig.DevelopMethod)"
    write-host "'Go' Links:" -ForegroundColor DarkYellow
    foreach ($link in $global:goTaskStore.GetEnumerator()) {
        Write-Host "            $($link.Key)" -NoNewline
        write-host " - $($link.Value)" -ForegroundColor DarkGray
    }
    write-host "---------------------------------------------------------" -ForegroundColor DarkGray
}

function DevEnv {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.DevelopMethod -ne "") {
            & $appConfig.DevelopMethod
        }
        else {
            write-host "No development method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

function viewPRs {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.ReviewPullRequests -ne "") {
            & $appConfig.ReviewPullRequests

            if ($appConfig.OpenPullRequests -ne "") {
                Read-host "Open pull request by id?: " | ForEach-Object {
                    if ($_ -ne "") {
                        $pullRequestId = $_
                        & $appConfig.OpenPullRequest $pullRequestId
                    }
                }
            }
        }
        else {
            write-host "No pull request review method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

# ================= Utility Commands ==================
# When you need to create a CAB file, run wsreset, reproduce the issue, then run wscollect
# function CleanEventLog {
#     wsreset
# }

# function DumpEventLog {
#     wscollect
# }

# function HostsFile {
#     Start-Process notepad "$env:SystemRoot\System32\drivers\etc\hosts" -Verb runAs
# }

# =================== Helper Methods ===================
function GoToRepo([string]$repo) {
    Set-Location -Path $repo
}

function GoToUrl([string]$url) {
    Start-Process $url
}

#====================== Core COBRA METHODS =======================

function Load-CobraUtilityScripts {
    try {
        $utilsFolder = Join-Path $PSScriptRoot "Utils"
        Write-Host "Loading utility scripts from: $utilsFolder"
        if (-not (Test-Path $utilsFolder)) {
            New-Item -Path $utilsFolder -ItemType Directory | Out-Null
            Write-Host "Created Utils folder at: $utilsFolder"
        }

        Get-ChildItem -Path $utilsFolder -Filter *.psm1 | ForEach-Object {
            Write-Host "Loading utility script: $($_.FullName)"
            Import-Module $_.FullName -Force -DisableNameChecking

        }
    }
    catch {
        Write-Host "Failed to load script: $($_.FullName)" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Load utility scripts
Load-CobraUtilityScripts

Import-CobraModules

# Register tab completion for the 'repo' function
Register-ArgumentCompleter -CommandName repo -ParameterName name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)

    # Get keys from the hashtable
    $keys = $global:AppConfigs.Keys

    # Filter keys based on the current input
    $keys | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
        [System.Management.Automation.CompletionResult]::new(
            $_,
            $_,
            'ParameterValue',
            $_
        )
    }
}

function Initialize-CobraEnvironmentVariables {
    Write-Host "Initializing environment variables..." -ForegroundColor Green

    # Define all environment variables used in the workspace with default values
    $envVariables = @(
        @{ Name = "COBRA_ROOT"; Default = if ($null -ne $env:COBRA_ROOT) { $env:COBRA_ROOT } else { "C:\Path\To\<Location of Cobra files and modules>" } },
        @{ Name = "CODE_REPO"; Default = if ($null -ne $env:CODE_REPO) { $env:CODE_REPO } else { "C:\Path\To\<Root code directory where all repos will live>" } }
    )

    # Prompt the user for each environment variable
    foreach ($envVar in $envVariables) {
        $name = $envVar.Name
        $default = $envVar.Default

        # Prompt the user for the value
        $value = Read-Host "Enter value for $name (default: $default)"
        if ([string]::IsNullOrWhiteSpace($value)) {
            $value = $default
        }

        # Set the environment variable
        [System.Environment]::SetEnvironmentVariable($name, $value, [System.EnvironmentVariableTarget]::Process)
        Write-Host "Set environment variable: $name = $value"
    }

    Write-Host "Environment variables initialized successfully." -ForegroundColor Green
}

function Get-CobraEnvironmentConfiguration {
    Write-Host "Current Environment Variables:" -ForegroundColor Green
    Write-Host "--------------------------------------------"
    Write-Host "COBRA_ROOT = $($env:COBRA_ROOT)"
    Write-Host "CODE_REPO = $($env:CODE_REPO)"
}

enum CobraModulesCommands {
    add
    remove
    edit
    import
    export
}

function CobraModulesDriver([CobraModulesCommands] $command, [string[]] $options) {
    switch ($command) {
        add {
            if ($options.Count -eq 1) {
                $moduleName = $options[0]
                $modulePath = Join-Path $PSScriptRoot "CobraGen2\Modules\$moduleName"
                if (-not (Test-Path $modulePath)) {
                    New-Item -Path $modulePath -ItemType Directory
                    New-Item -Path "$modulePath\$moduleName.psm1" -ItemType File
                    New-Item -Path "$modulePath\config.ps1" -ItemType File

                    New-ModuleConfigFile "$moduleName"
                    New-ModuleTemplate "$moduleName"
                    $global:CobraScriptModules[$moduleName] = @($moduleName, $moduleName)

                    Import-Module $modulePath -Force -DisableNameChecking
                    # Initialize the module
                    & "Initialize-$($moduleName)Module"
                    Write-Host "Created new module: $moduleName"
                }
                else {
                    Write-Host "Module already exists: $moduleName" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Invalid options for 'add'. Provide the name of the module to add." -ForegroundColor Red
            }
        }
        edit {
            if ($options.Count -eq 1) {
                $moduleName = $options[0]
                write-host "Editing module: $moduleName at location $PSScriptRoot\CobraGen2\Modules\$moduleName\$moduleName.psm1"
                write-host "Editing module: $moduleName at location $PSScriptRoot\CobraGen2\Modules\$moduleName\config.ps1"
                code "$PSScriptRoot\CobraGen2\Modules\$moduleName\$moduleName.psm1"
                code "$PSScriptRoot\CobraGen2\Modules\$moduleName\config.ps1"
            }
            else {
                Write-Host "Invalid options for 'edit'. Provide the name of the module to edit." -ForegroundColor Red
            }
        }
        remove {
            if ($options.Count -eq 1) {
                $moduleName = $options[0]
                $modulePath = Join-Path $PSScriptRoot "CobraGen2\Modules\$moduleName"
                if (Test-Path $modulePath) {
                    Write-Host "Are you sure you want to remove the module $moduleName? This action cannot be undone." -ForegroundColor Red
                    $confirmation = Read-Host "Type 'yes' to confirm removal of the module"
                    if ($confirmation -ne "yes") {
                        Write-Host "Module removal canceled." -ForegroundColor Yellow
                        return
                    }

                    Remove-Module $moduleName -Force
                    $global:CobraScriptModules.Remove($moduleName)
                    Remove-Item -Path $modulePath -Recurse -Force
                    Write-Host "Removed module: $moduleName"
                }
                else {
                    Write-Host "Module not found: $moduleName" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Invalid options for 'remove'. Provide the name of the module to remove." -ForegroundColor Red
            }
        }
        import {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                $artifactPath = $options[1]
                Import-CobraModule -moduleName $moduleName -artifactPath $artifactPath
            }
            else {
                Write-Host "Invalid options for 'import'. Provide the name of the module and the artifact path." -ForegroundColor Red
            }
        }
        export {
            if ($options.Count -eq 2) {
                $moduleName = $options[0]
                $artifactPath = $options[1]
                Export-CobraModule -moduleName $moduleName -artifactPath $artifactPath
            }
            else {
                Write-Host "Invalid options for 'export'. Provide the name of the module and the artifact path." -ForegroundColor Red
            }
        }
        default {
            CobraHelp
        }
    }
}

function ShowCobraScriptModules() {
    write-host "AVAILABLE COBRA MODULES" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------" -ForegroundColor DarkGray
    $global:CobraScriptModules.GetEnumerator() | Sort-Object -Property Key | ForEach-Object {
        Write-Host " $($_.Key) " -NoNewline
        write-host "- $($_.Value[1])" -ForegroundColor DarkGray
    }
}

enum CobraGoCommands {
    add
    remove
    update
}
function CobraGoDriver([CobraGoCommands] $command, [string[]] $options) {
    switch ($command) {
        add {
            if ($options.Count -eq 3) {
                # Pass parameters directly from the array
                Add-GoLocation -name $options[0] -description $options[1] -url $options[2]
            }
            else {
                Write-Host "Invalid options for 'add'. Provide name, description, and URL as arguments." -ForegroundColor Red
            }
        }
        remove {
            if ($options.Count -eq 1) {
                # Pass the name directly to Remove-GoLocation
                Remove-GoLocation -name $options[0]
            }
            else {
                Write-Host "Invalid options for 'remove'. Provide the name as an argument." -ForegroundColor Red
            }
        }
        update {
            if ($options.Count -eq 3) {
                # Pass parameters directly from the array
                Update-GoLocation -name $options[0] -description $options[1] -url $options[2]
            }
            else {
                Write-Host "Invalid options for 'update'. Provide name, description, and URL as arguments." -ForegroundColor Red
            }
        }
        default {
            Write-Host "Invalid command. Type 'cobra go' for usage."
        }
    }
}

function Import-CobraModule {
    param (
        [string]$moduleName,
        [string]$artifactPath
    )

    $destinationPath = Join-Path $PSScriptRoot "CobraGen2\Modules\$moduleName"

    # If no artifactPath is provided, look in the CobraModuleRegistry
    if (-not $artifactPath) {
        $registryPath = $global:CobraConfig.ModuleRegistryLocation
        $artifactPath = Join-Path $registryPath "$moduleName.zip"

        if (-not (Test-Path $artifactPath)) {
            Write-Host "Artifact for module '$moduleName' not found in the module registry at $artifactPath." -ForegroundColor Red
            return
        }

        Write-Host "Using artifact from module registry: $artifactPath" -ForegroundColor Yellow
    }

    if (Test-Path $destinationPath) {
        Write-Host "Module '$moduleName' already exists at $destinationPath." -ForegroundColor Yellow
        $confirmation = Read-Host "Type 'yes' to overwrite the existing module"
        if ($confirmation -ne "yes") {
            Write-Host "Import canceled." -ForegroundColor Yellow
            return
        }

        Remove-Item -Path $destinationPath -Recurse -Force
        Write-Host "Existing module removed." -ForegroundColor Green
    }

    # Extract the artifact
    if (-not (Test-Path $artifactPath)) {
        Write-Host "Artifact '$artifactPath' does not exist." -ForegroundColor Red
        return
    }

    # Create the destination directory
    New-Item -Path $destinationPath -ItemType Directory | Out-Null

    # Extract only the contents of the module directory from the archive
    Expand-Archive -Path $artifactPath -DestinationPath $env:TEMP -Force
    $tempModulePath = Join-Path $env:TEMP $moduleName
    if (Test-Path $tempModulePath) {
        Move-Item -Path (Join-Path $tempModulePath "*") -Destination $destinationPath -Force
        Remove-Item -Path $tempModulePath -Recurse -Force
        Write-Host "Module '$moduleName' extracted to $destinationPath." -ForegroundColor Green
    }
    else {
        Write-Host "Module directory '$moduleName' not found in the artifact." -ForegroundColor Red
        return
    }

    # Register the module in the global profile
    $global:CobraScriptModules[$moduleName] = @($moduleName, "$moduleName.psm1")

    # Load the module into the current session
    $moduleFile = Join-Path "$destinationPath" "$moduleName.psm1"
    if (Test-Path $moduleFile) {
        Import-Module $moduleFile -Force -DisableNameChecking
        Write-Host "Module '$moduleName' loaded into the current session." -ForegroundColor Green
    }
    else {
        Write-Host "Module file '$moduleFile' not found. Could not load into the session." -ForegroundColor Red
    }
}

function Export-CobraModule {
    param (
        [string]$moduleName,
        [string]$artifactPath
    )

    $modulePath = Join-Path $PSScriptRoot "CobraGen2\Modules\$moduleName"

    if (-not (Test-Path $modulePath)) {
        Write-Host "Module '$moduleName' does not exist at $modulePath." -ForegroundColor Red
        return
    }

    $tempArchivePath = Join-Path $env:TEMP "$moduleName.zip"

    # Create a compressed artifact
    Compress-Archive -Path $modulePath -DestinationPath $tempArchivePath -Force
    Move-Item -Path $tempArchivePath -Destination $artifactPath -Force
    Write-Host "Module '$moduleName' exported as artifact to $artifactPath." -ForegroundColor Green
}

#=================== Script Information ===================
Write-Host -ForegroundColor Green "COBRA tools loaded successfully. For details type 'cobra'."
# Cobra is a collection of PS scripts that help developers work more efficiently

enum CobraCommand {
    help
    modules
    go
    env
    utils # Added new command
}

function ShowUtilityFunctions {
    # List all functions defined in the Utils folder
    $utilsFolder = Join-Path $PSScriptRoot "Utils"
    if (Test-Path $utilsFolder) {
        $childItems = Get-ChildItem -Path $utilsFolder -Filter *.psm1
        if ($childItems.Count -gt 0) {
            Write-Host "USER DEFINED UTILITY FUNCTIONS:" -ForegroundColor DarkGray

            $childItems | ForEach-Object {
                $scriptContent = Get-Content $_.FullName
                $functions = $scriptContent | Select-String -Pattern "function\s+(\w+)" | ForEach-Object { $_.Matches.Groups[1].Value }
                foreach ($function in $functions) {
                    # Extract the comment above the function as the description
                    $description = ($scriptContent -split "`n" | Select-String -Pattern "^\s*#.*" -Context 0, 1 | Where-Object { $_.Context.PostContext -match "function\s+$function" }).Line.TrimStart('#').Trim()
                    Write-Host " $function" -NoNewline
                    if ($description) {
                        Write-Host "`t- $description" -ForegroundColor DarkGray
                    }
                    else {
                        Write-Host "    - No description available." -ForegroundColor DarkGray
                    }
                }
            }
            Write-Host ""
        }
    }
    else {
        Write-Host "No utility scripts found." -ForegroundColor Red
    }
}

function CobraHelp {
    Write-Host -ForegroundColor Yellow " __________ _______ ___    _____  ___"
    Write-Host -ForegroundColor Yellow "|  _____  /  ___  /  __ \ /     \/   \"
    Write-Host -ForegroundColor Yellow "| |    |_/ /   / /  ____//  /   /  |  \"
    Write-Host -ForegroundColor Yellow "| |   _ / /   / /  __  \/ _____/   _   \"
    Write-Host -ForegroundColor Yellow "| |__/ / /___/ /  /_/  /    \ /   / \   \"
    Write-Host -ForegroundColor Yellow "|_____/_______/_______/__/\__/___/   \___\"
    Write-Host -ForegroundColor Red "CENTRALIZED OPS for BUILDING RELIABLE AUTOMATION"
    Write-Host "------------------------------------------------" -ForegroundColor DarkGray
    Write-Host -ForegroundColor DarkGray "DEV COMMANDS:"
    Write-Host " appInfo" -NoNewline
    write-host "   - Gets the app information for your current repo" -ForegroundColor DarkGray
    Write-Host " authApp" -NoNewline
    write-host "   - Run auth setup for your current repo (whenever auth expires)" -ForegroundColor DarkGray
    Write-Host " setupApp" -NoNewline
    write-host "  - Run setup for your current repo (one time prebuild setup)" -ForegroundColor DarkGray
    Write-Host " buildApp" -NoNewline
    write-host "  - Builds your current repo" -ForegroundColor DarkGray
    Write-Host " testApp" -NoNewline
    write-host "   - Run tests for your current repo" -ForegroundColor DarkGray
    Write-Host " runApp" -NoNewline
    write-host "    - Runs the built executables for the current repo" -ForegroundColor DarkGray
    Write-Host " devEnv" -NoNewline
    write-host "    - Opens the development environment for the repo" -ForegroundColor DarkGray
    Write-Host " pr" -NoNewline
    write-host "        - Does the steps required before creating a PR (Build, lint, and gen tests)" -ForegroundColor DarkGray
    write-host " viewPRs" -NoNewline
    write-host "   - Reads assigned pull requests for the current repo" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host -ForegroundColor DarkGray "NAV COMMANDS:"
    Write-Host " repo" -NoNewline
    write-host "            - Allows you to switch between various developer code repositories. Type 'repo' for specific help." -ForegroundColor DarkGray
    Write-Host " go" -NoNewline
    write-host "              - Allows you to navigate to various tasks. Type 'go' for specific help." -ForegroundColor DarkGray
    Write-Host " SwitchSandbox" -NoNewline
    write-host "   - Switch between sandboxes" -ForegroundColor DarkGray
    Write-Host ""
    ShowUtilityFunctions
    Write-Host -ForegroundColor DarkGray "COBRA CONFIG & SETUP COMMANDS:"
    Write-Host " cobra <option>" -NoNewline
    write-host "    - Displays this help information" -ForegroundColor DarkGray
    Write-Host "    env <option>" -NoNewline
    write-host "   - Displays the current environment variables" -ForegroundColor DarkGray
    Write-Host "        init" -NoNewline
    write-host "       - Initializes the environment variables for cobra" -ForegroundColor DarkGray
    Write-Host "    go <option>" -NoNewline
    write-host "    - Displays the available cobra go administrative tasks. Go tasks are used to navigate to various locations." -ForegroundColor DarkGray
    Write-Host "        add <name> <description> <url>" -NoNewline
    Write-host "     - Adds a new go location" -ForegroundColor DarkGray
    Write-Host "        remove <name>" -NoNewline
    Write-host "                      - Removes a go location" -ForegroundColor DarkGray
    Write-Host "        update <name> <description> <url>" -NoNewline
    Write-host "  - Updates a go location" -ForegroundColor DarkGray
    Write-Host "    help" -NoNewline
    write-host "           - Displays this help information" -ForegroundColor DarkGray
    Write-Host "    modules <option>" -NoNewline
    write-host "  - Displays the available cobra modules. Modules contain custom logic for various repositories." -ForegroundColor DarkGray
    write-host "        add <name>" -NoNewline
    write-host "     - Adds a new cobra profile" -ForegroundColor DarkGray
    Write-Host "        remove <name>" -NoNewline
    write-host "  - Removes a cobra profile" -ForegroundColor DarkGray
    Write-Host "        edit <name>" -NoNewline
    write-host "    - Edits a cobra profile" -ForegroundColor DarkGray
    Write-Host "        import <name> <artifactPath>" -NoNewline
    write-host "  - Imports a cobra profile from an artifact" -ForegroundColor DarkGray
    Write-Host "        export <name> <artifactPath>" -NoNewline
    write-host "  - Exports a cobra profile to an artifact" -ForegroundColor DarkGray
    Write-Host "    utils" -NoNewline
    write-host "  - Displays the available utility functions" -ForegroundColor DarkGray
    Write-Host ""
}

function CobraDriver([CobraCommand] $command, [string[]] $options) {
    switch ($command) {
        help {
            CobraHelp
        }
        modules {
            if ($options.Count -le 1) {
                ShowCobraScriptModules
                return
            }

            # Parse the subcommand and remaining options
            $subCommand = $options[0]
            $remainingOptions = $options[1..($options.Count - 1)]
            # Convert the subcommand to the CobraModulesCommands enum
            if ([enum]::IsDefined([CobraModulesCommands], $subCommand)) {
                CobraModulesDriver -command ([CobraModulesCommands]::Parse([CobraModulesCommands], $subCommand)) -options $remainingOptions
            }
            else {
                ShowCobraScriptModules
            }
        }
        go {
            # Parse the subcommand and remaining options
            $subCommand = $options[0]
            $remainingOptions = $options[1..($options.Count - 1)]

            # Convert the subcommand to the CobraGoCommands enum
            if ([enum]::IsDefined([CobraGoCommands], $subCommand)) {
                CobraGoDriver -command ([CobraGoCommands]::Parse([CobraGoCommands], $subCommand)) -options $remainingOptions
            }
            else {
                Write-Host "Invalid 'go' subcommand: $subCommand" -ForegroundColor Red
                CobraHelp
            }
        }
        env {
            $subCommand = $options[0]
            if ($subCommand -eq "init") {
                Initialize-CobraEnvironmentVariables
            }
            else {
                Get-CobraEnvironmentConfiguration
            }
        }
        utils {
            ShowUtilityFunctions
        }
        default {
            CobraHelp
        }
    }
}
function cobra {
    param (
        [CobraCommand]$command
    )

    if ($null -eq $command) {
        CobraDriver
    }
    else {
        CobraDriver -command $command -options $args
    }
}

# ================== Experiments ==================
# Makes a package
# I think this needs to live in either the deploy or the build

# Enum for names of allowable packages
enum packageName {
    GreenbeltCLI
}

# Packages
$global:PackagesRepo = "$($global:CobraConfig.CodeRoot)\Packages"

function MakePackage ([packageName] $package) {
    $src = Get-Location
    $currentDateTime = Get-Date -Format "yyyyMMdd_HHmmss"
    $packageName = $package.ToString()

    repo Packages

    # Create the directory name with the package prefix and current date and time suffix
    $directoryName = $packageName + "_$currentDateTime"
    New-Item -Path $directoryName -ItemType Directory
    Write-Host "Created directory: $directoryName"

    cd $directoryName

    switch ($package) {
        GreenbeltCLI {
            # Follow the instructions here to download the Greenbelt.CommandLine artifacts
            # needed in STEP 2
            # https://microsoft.visualstudio.com/Xbox/_git/Xbox.Greenbelt?path=/Documentation/HowToReleaseSdkAndCli.md&_a=preview

            # STEP 1: Create the directory structure
            Write-Host "Creating directory structure for Greenbelt SDK package"
            mkdir "Greenbelt.Commandline"
            mkdir "Greenbelt.Commandline\Linux"
            mkdir "Greenbelt.Commandline\Windows"

            # STEP 2: Copy the commandline files to the directory
            Write-Host "Go Here: https://dev.azure.com/microsoft/Xbox/_build?definitionId=96334&_a=summary"
            Write-Host "Select the latest build (all stages showing green)"
            Write-Host "1/2 way down the page, click the link that says '1 artifact'"
            Write-Host "Expand heading called 'drop_deploymentfiles->LinuxCLIPublish'"
            Write-Host "On the ellipsis menu for Greenbelt.CommandLine, choose 'Download Artifact'"
            $linuxPath = Read-Host "Enter Linux commandline url"
            Write-Host "Copying commandline files to the Linux directory"
            Invoke-WebRequest -Uri $linuxPath -OutFile "Greenbelt.Commandline\Linux\Greenbelt.CommandLine.exe"
            $windowsPath = Read-Host "Enter Windows commandline url"
            Write-Host "Copying commandline files to the Windows directory"
            Invoke-WebRequest -Uri $windowsPath -OutFile "Greenbelt.Commandline\Windows\Greenbelt.CommandLine.exe"

            # STEP 3: Create a zip file from the directory
            $zipFileName = "Greenbelt.Commandline.zip"
            Compress-Archive -Path "$global:PackageRepo\$directoryName\Greenbelt.Commandline" -DestinationPath "$global:PackageRepo\$directoryName\$zipFileName"
            Write-Host "Created zip file: $zipFileName"
        }
    }

    cd $src
}

# Deploy to environment
function DeployApp {
    $src = Get-Location
    if ($src.Path.StartsWith($global:GreenbeltRepo)) {
        write-host "Changing directory to 'Scripts\Developers\dajon'"
        cd Scripts\Developers\dajon

        if (ShouldContinue "Do you need to authenticate?" "N") {
            write-host "Authenticating..."
            az login --scope https://management.azure.com/.default --use-device-code
        }

        if (ShouldContinue "Would you like to deploy to your current stamp?" "N") {
            write-host "Deploying stamp..."
            .\Deploy-Stamp.ps1
        }

        if (ShouldContinue "Would you like to deploy to your region?" "N") {
            write-host "Deploying region..."
            .\Deploy-Region.ps1
        }

        # Change back to Developers directory
        cd ..

        if (ShouldContinue("Would you like to push your local changes?")) {
            write-host "Deploying local changes to stamp..."
            .\DeployLocalBuild.ps1 dajon "01" CloudDevkitLeaseProcessor
        }

        write-host "Changing directory back to root"
        Set-Location $src
    }
    else {
        Write-Host "You are not in a valid repo to deploy the app"
    }
}

function GetLog() {
    $src = Get-Location
    if ($src.Path.StartsWith($global:GreenbeltRepo)) {
        az account set --subscription c321dad1-fd4e-4242-a667-a47aefd728af
        az aks get-credentials --resource-group dajon-01-shared --name dajon-01-alpha-1-A --overwrite-existing

        write-host "Changing directory back to root"
        Set-Location $src
    }
    else {
        Write-Host "You are not in a valid repo to get the log"
    }
}


# TODO List:
# - Add logic to automatically pull down a repo if it doesn't exist
# - Add logic to load and unload modules from repository
# - Add logic to create jobs (manual, events, or scheduled) at repo level and global level
# - Module and repo health checks
# - Predefined module initialization (e.g. CobraGen2, Xbox, etc.)
# - Export/import modules
# - Add logic for pluggable utility commands
