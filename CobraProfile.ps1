# Import COBRA configuration file
. "$PSScriptRoot\sysconfig.ps1"

# Load core scripts
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

# Load developer commands
if (-not $global:devCommandsLoaded) {
    . "$($global:CobraConfig.CobraRoot)/DevCommands.ps1"
}

# Load 'Go' commands
if (-not $global:goCommandsScriptLoaded) {
    . "$($global:CobraConfig.CobraRoot)/GoCommands.ps1"
}

# Load Module Management
if (-not $global:moduleManagementScriptLoaded) {
    . "$($global:CobraConfig.CobraRoot)/ModuleManagement.ps1"
}

# Load job management
if (-not $global:jobManagementScriptLoaded) {
    . "$($global:CobraConfig.CobraRoot)/JobManagement.ps1"
}

#====================== COBRA METHODS =======================
# Function to navigate to the desired code repository
function repo ([string] $name) {
    try {
        if (-not $name) {
            throw "Repository name is required."
        }

        $appConfig = GetAppConfig $name

        if ($null -eq $appConfig) {
            Write-Host "AppConfig not found for $enumName" -ForegroundColor Red
            Log-CobraActivity "Failed to load repository: $name. AppConfig not found."
            return
        }

        # Set the current app config
        $global:currentAppConfig = $appConfig
        Write-Host "Loaded $enumName configuration."
        Log-CobraActivity "Loaded repository configuration for: $name."

        # Check if CodeRepo variable is set in config
        if (-not $global:CobraConfig.CodeRepo) {
            Write-Host "CodeRepo configuration variable is not set. Please run 'cobra env init' to set environment variables." -ForegroundColor Red
            Log-CobraActivity "Failed to load repository: $name. CodeRepo configuration variable is not set."
            return
        }

        $repoLocation = "$($global:CobraConfig.CodeRepo)\$($appConfig.Repo)" # Check common code repo location
        if (-not (Test-Path $repoLocation)) {
            $repoLocation = "$($appConfig.Repo)" # Check absolute path
            if (-not (Test-Path $repoLocation)) {
                Write-Host "Invalid repository location: $repoLocation. Check configuration." -ForegroundColor Red
                Log-CobraActivity "Failed to load repository: $name. Invalid repository location: $repoLocation."
                return
            }
        }

        GoToRepo($repoLocation)
        Log-CobraActivity "Navigated to repository location: $repoLocation."

        if ($null -ne $appConfig.GoLocations -and $appConfig.GoLocations.Count -gt 0) {
            $global:goTaskStore = $appConfig.GoLocations
            Write-Host "Loaded 'Go' locations."
            Log-CobraActivity "Loaded 'Go' locations for repository: $name."
        }
        else {
            write-host "No Go locations configured." -ForegroundColor Yellow
            Log-CobraActivity "No 'Go' locations configured for repository: $name."
        }
    }
    catch {
        Log-CobraActivity "Error occurred while loading repository: $name. Error: $($_.Exception.Message)"
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

function Load-CobraUtilityScripts {
    try {
        $utilsFolder = Join-Path $PSScriptRoot "Utils"
        Write-Host "Loading utility scripts from: $utilsFolder"
        if (-not (Test-Path $utilsFolder)) {
            New-Item -Path $utilsFolder -ItemType Directory | Out-Null
            Write-Host "Created Utils folder at: $utilsFolder"
        }

        Get-ChildItem -Path $utilsFolder -Filter *.psm1 | ForEach-Object {
            # Write-Host "Loading utility script: $($_.FullName)"
            Import-Module $_.FullName -Force -DisableNameChecking

        }
    }
    catch {
        Write-Host "Failed to load script: $($_.FullName)" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Load-CobraJobScripts {
    try {
        $jobsFolder = Join-Path $PSScriptRoot "Jobs"
        Write-Host "Loading job scripts from: $jobsFolder"
        if (-not (Test-Path $jobsFolder)) {
            New-Item -Path $jobsFolder -ItemType Directory | Out-Null
            Write-Host "Created Jobs folder at: $jobsFolder"
        }

        Get-ChildItem -Path $jobsFolder -Filter *.psm1 | ForEach-Object {
            # Write-Host "Loading job script: $($_.FullName)"
            Import-Module $_.FullName -Force -DisableNameChecking
        }
    }
    catch {
        Write-Host "Failed to load script: $($_.FullName)" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Load-CobraUtilityScripts
Load-CobraJobScripts
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

function Update-CobraSystemConfiguration {
    Write-Host "Updating system configuration..."

    # Path to the config.ps1 file
    $configFilePath = Join-Path $PSScriptRoot "sysconfig.ps1"

    # Check if sysconfig.ps1 exists
    if (-not (Test-Path $configFilePath)) {
        Write-Host "sysconfig.ps1 not found. Creating a new one..." -ForegroundColor Yellow
        New-Item -Path $configFilePath -ItemType File -Force | Out-Null
        $global:CobraConfig = @{} # Initialize an empty hashtable if sysconfig.ps1 is missing
    }

    # Prompt the user for each key in $global:CobraConfig
    $keysToLoop = @($global:CobraConfig.Keys)
    foreach ($key in $keysToLoop) {
        $currentValue = $global:CobraConfig[$key]
        $newValue = Read-Host "Enter value for $key (current: $currentValue)"
        if (-not [string]::IsNullOrWhiteSpace($newValue)) {
            write-host "Setting $key to $newValue" -ForegroundColor Green
            $global:CobraConfig[$key] = $newValue
        }
    }

    # Write updated values back to sysconfig.ps1
    $updatedConfigContent = @()
    $updatedConfigContent += "# Global settings for the application"
    $updatedConfigContent += "`$global:CobraConfig = @{"
    foreach ($key in $global:CobraConfig.Keys) {
        $updatedConfigContent += "    $key = '$($global:CobraConfig[$key])'"
    }
    $updatedConfigContent += "}"
    $updatedConfigContent | Set-Content -Path $configFilePath -Force

    Write-Host "System configuration updated successfully." -ForegroundColor Green
}

function Get-CobraSystemConfiguration {
    Write-Host "SYSTEM CONFIGURATION" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------" -ForegroundColor DarkGray
    foreach ($key in $global:CobraConfig.Keys) {
        Write-Host " $key" -NoNewline
        write-host " = $($global:CobraConfig[$key])" -ForegroundColor DarkGray
    }
    Write-Host "--------------------------------------------" -ForegroundColor DarkGray
}

#=================== Script Information ===================
Write-Host -ForegroundColor Green "COBRA tools loaded successfully. For details type 'cobra'."
# Cobra is a collection of PS scripts that help developers work more efficiently

enum CobraCommand {
    help
    modules
    go
    env
    utils
    health
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
                $functions = $scriptContent | Select-String -Pattern "function\s+(\w+)" | Where-Object { $_.Line -notmatch "^\s*#" -and $_.Line -notmatch "Export-ModuleMember" } | ForEach-Object { $_.Matches.Groups[1].Value }
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
    write-host "     - Adds a new cobra module" -ForegroundColor DarkGray
    Write-Host "        remove <name>" -NoNewline
    write-host "  - Removes a cobra module" -ForegroundColor DarkGray
    Write-Host "        edit <name>" -NoNewline
    write-host "    - Edits a cobra module" -ForegroundColor DarkGray
    Write-Host "        import <name> <artifactPath>" -NoNewline
    write-host "  - Imports a cobra module from an artifact" -ForegroundColor DarkGray
    Write-Host "        export <name> <artifactPath>" -NoNewline
    write-host "  - Exports a cobra module to an artifact" -ForegroundColor DarkGray
    Write-Host "        registry <action>" -NoNewline
    write-host "    - Browse and manage the module registry" -ForegroundColor DarkGray
    write-host "            list" -NoNewline
    write-host "             - List all modules in registry" -ForegroundColor DarkGray
    Write-Host "            info <name>" -NoNewline
    write-host "      - Get detailed info about a module" -ForegroundColor DarkGray
    Write-Host "            search <term>" -NoNewline
    write-host "    - Search for modules" -ForegroundColor DarkGray
    Write-Host "            open" -NoNewline
    write-host "             - Open registry folder in Explorer" -ForegroundColor DarkGray
    Write-Host "            push <name>" -NoNewline
    write-host "      - Push a module to the registry" -ForegroundColor DarkGray
    Write-Host "            pull <name>" -NoNewline
    write-host "      - Pull a module from the registry" -ForegroundColor DarkGray
    Write-Host "    utils" -NoNewline
    write-host "  - Displays the available utility functions" -ForegroundColor DarkGray
    Write-Host "    health <target>" -NoNewline
    write-host "    - Runs health checks for modules and repositories. Target can be 'all', 'modules', or 'repositories'." -ForegroundColor DarkGray
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
                Update-CobraSystemConfiguration
            }
            else {
                Get-CobraSystemConfiguration
            }
        }
        utils {
            ShowUtilityFunctions
        }
        health {
            $target = if ($options.Count -gt 0) { $options[0] } else { "all" }
            CheckHealth -target $target
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
