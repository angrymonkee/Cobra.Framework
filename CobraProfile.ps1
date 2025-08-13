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

# Load cobra dashboard
if (-not $global:cobraDashboardScriptLoaded) {
    . "$($global:CobraConfig.CobraRoot)/CobraDashboard.ps1"
}

# Load templates management
if (-not $global:templatesManagementScriptLoaded) {
    . "$($global:CobraConfig.CobraRoot)/TemplatesManagement.ps1"
}

Log-CobraActivity "Loaded COBRA driver."

# Log profile load
Log-CobraActivity "Cobra Framework profile loaded with Context Dashboard enabled"

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
        Log-CobraActivity "Loading utility scripts from: $utilsFolder"
        if (-not (Test-Path $utilsFolder)) {
            New-Item -Path $utilsFolder -ItemType Directory | Out-Null
            Log-CobraActivity "Created Utils folder at: $utilsFolder"
        }

        Get-ChildItem -Path $utilsFolder -Filter *.psm1 | ForEach-Object {
            # Write-Host "Loading utility script: $($_.FullName)"
            Import-Module $_.FullName -Force -DisableNameChecking
        }
    }
    catch {
        Write-Host "Failed to load script: $($_.FullName)" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error loading utility scripts: $($_.Exception.Message)"
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
    Log-CobraActivity "Updating system configuration..."

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
    dashboard
    logs
    templates
}

function ShowUtilityFunctions {
    # List all functions defined in the Utils folder
    $utilsFolder = Join-Path $PSScriptRoot "Utils"
    if (Test-Path $utilsFolder) {
        $childItems = Get-ChildItem -Path $utilsFolder -Filter *.psm1
        if ($childItems.Count -gt 0) {
            Write-Host "USER DEFINED UTILITY FUNCTIONS:" -ForegroundColor Yellow

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
    Write-Host -ForegroundColor Yellow "DEV COMMANDS:"
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
    Write-Host -ForegroundColor Yellow "NAV COMMANDS:"
    Write-Host " repo" -NoNewline
    write-host "      - Allows you to switch between various developer code repositories. Type 'repo' for specific help." -ForegroundColor DarkGray
    Write-Host " go" -NoNewline
    write-host "        - Allows you to navigate to various tasks. Type 'go' for specific help." -ForegroundColor DarkGray
    Write-Host ""
    ShowUtilityFunctions
    Write-Host -ForegroundColor Yellow "COBRA CONFIG & SETUP COMMANDS:"
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
    Write-Host "    logs <option>" -NoNewline
    write-host "      - Displays the cobra logs" -ForegroundColor DarkGray
    Write-Host "        search <term>" -NoNewline
    write-host "  - Searches the cobra logs" -ForegroundColor DarkGray
    Write-Host "        view [lines]" -NoNewline
    write-host "   - Displays the last N lines of the cobra logs (Default: 20)." -ForegroundColor DarkGray
    write-host "        clear" -NoNewline
    Write-Host "          - Clears the cobra activity log." -ForegroundColor DarkGray
    Write-Host "    help" -NoNewline
    write-host "               - Displays this help information" -ForegroundColor DarkGray
    Write-Host "    modules <option>" -NoNewline
    write-host "   - Displays the available cobra modules. Modules contain custom logic for various repositories." -ForegroundColor DarkGray
    Write-Host "      ** For detailed module commands, run: " -NoNewline -ForegroundColor DarkGray  
    Write-Host "cobra modules" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "    templates <option>" -NoNewline
    write-host "        - Template and snippet management for rapid code reuse (built-in)" -ForegroundColor DarkGray
    Write-Host "        list [category]" -NoNewline
    write-host "       - List available templates (module/function/snippet)" -ForegroundColor DarkGray
    Write-Host "        new <template> <name>" -NoNewline
    write-host " - Create new module from template" -ForegroundColor DarkGray
    Write-Host "        snippet <name>" -NoNewline
    write-host "        - Copy snippet to clipboard" -ForegroundColor DarkGray
    Write-Host "        save <name> <type>" -NoNewline
    write-host "    - Save current code as template" -ForegroundColor DarkGray
    Write-Host "        search <term>" -NoNewline
    write-host "         - Search for templates and snippets" -ForegroundColor DarkGray
    Write-Host "        wizard [type]" -NoNewline
    write-host "         - Interactive template creation wizard" -ForegroundColor DarkGray
    Write-Host "        registry" -NoNewline
    write-host "              - Browse team template registry" -ForegroundColor DarkGray
    Write-Host "        publish <name> [type]" -NoNewline
    write-host " - Share template with team" -ForegroundColor DarkGray
    Write-Host "        import <name> [type]" -NoNewline
    write-host "  - Import template from registry" -ForegroundColor DarkGray
    Write-Host "    utils" -NoNewline
    write-host "              - Displays the available utility functions" -ForegroundColor DarkGray
    Write-Host "    health <target>" -NoNewline
    write-host "    - Runs health checks for modules and repositories. Target can be 'all', 'modules', or 'repositories'." -ForegroundColor DarkGray
    Write-Host "    dashboard [-i]" -NoNewline
    write-host "     - Show context-aware dashboard. Use -i for interactive mode with quick actions." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "📋 DASHBOARD FEATURES" -ForegroundColor Yellow
    Write-Host "  • Context awareness - shows current location, git status, repository info"
    Write-Host "  • Status monitoring - displays build/test results and timing"
    Write-Host "  • Quick actions - single-key access to common commands ([B]uild, [T]est, [R]un, etc.)"
    Write-Host "  • Recent activity - shows last 5 framework activities"
    Write-Host "  • Log management - integrated log viewing and searching"
    Write-Host "  • Hotkey access - Press Ctrl+D from anywhere to open dashboard (when available)"
    Write-Host "  • Aliases: " -NoNewline -ForegroundColor DarkGray
    Write-Host "'dash'" -NoNewline -ForegroundColor Cyan
    Write-Host " and " -NoNewline -ForegroundColor DarkGray
    Write-Host "'dashboard'" -ForegroundColor Cyan
    Write-Host ""
}

# ================== Log Management Functions ==================

function Show-CobraLogs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("view", "search", "clear")]
        [string]$Action,
        
        [string]$SearchTerm,
        [string]$Lines = "20"
    )
    
    $logPath = Join-Path $PSScriptRoot "CobraActivity.log"
    
    switch ($Action) {
        "view" {
            if (-not (Test-Path $logPath)) {
                Write-Host "No activity log found." -ForegroundColor Yellow
                return
            }
            
            Write-Host "COBRA ACTIVITY LOG" -ForegroundColor Cyan
            Write-Host "Location: $logPath" -ForegroundColor DarkGray
            Write-Host ("=" * 80) -ForegroundColor DarkGray
            
            if ($Lines -eq "all") {
                Get-Content $logPath | ForEach-Object {
                    $parts = $_ -split " - ", 2
                    if ($parts.Count -eq 2) {
                        Write-Host $parts[0] -NoNewline -ForegroundColor Green
                        Write-Host " - " -NoNewline -ForegroundColor DarkGray
                        Write-Host $parts[1] -ForegroundColor White
                    }
                }
            }
            else {
                $tailCount = [int]$Lines
                Get-Content $logPath -Tail $tailCount | ForEach-Object {
                    $parts = $_ -split " - ", 2
                    if ($parts.Count -eq 2) {
                        Write-Host $parts[0] -NoNewline -ForegroundColor Green
                        Write-Host " - " -NoNewline -ForegroundColor DarkGray
                        Write-Host $parts[1] -ForegroundColor White
                    }
                }
            }
            Write-Host ("=" * 80) -ForegroundColor DarkGray
        }
        
        "search" {
            if (-not (Test-Path $logPath)) {
                Write-Host "No activity log found." -ForegroundColor Yellow
                return
            }
            
            if (-not $SearchTerm) {
                Write-Host "Please provide a search term." -ForegroundColor Red
                return
            }
            
            Write-Host "SEARCHING COBRA ACTIVITY LOG" -ForegroundColor Cyan
            Write-Host "Search term: '$SearchTerm'" -ForegroundColor DarkGray
            Write-Host ("=" * 80) -ForegroundColor DarkGray
            
            $logMatches = Get-Content $logPath | Where-Object { $_ -like "*$SearchTerm*" }
            
            if ($logMatches) {
                foreach ($match in $logMatches) {
                    $parts = $match -split " - ", 2
                    if ($parts.Count -eq 2) {
                        Write-Host $parts[0] -NoNewline -ForegroundColor Green
                        Write-Host " - " -NoNewline -ForegroundColor DarkGray
                        
                        # Highlight search term
                        $highlightedText = $parts[1] -replace [regex]::Escape($SearchTerm), "[$SearchTerm]"
                        Write-Host $highlightedText -ForegroundColor White
                    }
                }
                Write-Host ""
                Write-Host "Found $($logMatches.Count) matching entries." -ForegroundColor Green
            }
            else {
                Write-Host "No matches found for '$SearchTerm'" -ForegroundColor Yellow
            }
            Write-Host ("=" * 80) -ForegroundColor DarkGray
        }
        
        "clear" {
            if (Test-Path $logPath) {
                $confirmation = Read-Host "Are you sure you want to clear the activity log? (y/N)"
                if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
                    Clear-Content $logPath
                    Write-Host "Activity log cleared." -ForegroundColor Green
                    Log-CobraActivity "Activity log cleared by user"
                }
                else {
                    Write-Host "Operation cancelled." -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "No activity log found to clear." -ForegroundColor Yellow
            }
        }
    }
}

function Show-CobraModuleHelp {
    Write-Host "COBRA MODULE SYSTEM" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    Write-Host "LOCAL MODULE MANAGEMENT:" -ForegroundColor Yellow
    Write-Host "  cobra modules list                      - Lists locally installed modules" -ForegroundColor DarkGray
    Write-Host "  cobra modules add <name>                - Creates a new cobra module using templates" -ForegroundColor DarkGray
    Write-Host "  cobra modules uninstall <name>         - Uninstalls a cobra module" -ForegroundColor DarkGray
    Write-Host "  cobra modules edit <name>              - Edits a cobra module" -ForegroundColor DarkGray
    Write-Host "  cobra modules import <name> <path>     - Imports a cobra module from an artifact" -ForegroundColor DarkGray
    Write-Host "  cobra modules export <name> <path>     - Exports a cobra module to an artifact" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "MARKETPLACE & REGISTRY:" -ForegroundColor Yellow
    Write-Host "  cobra modules search <term>            - Search modules (searches both local and registry)" -ForegroundColor DarkGray
    Write-Host "  cobra modules registry init            - Initialize the module marketplace" -ForegroundColor DarkGray
    Write-Host "  cobra modules registry list            - List all available registry modules" -ForegroundColor DarkGray
    Write-Host "  cobra modules registry info <name>     - Get detailed info about a module" -ForegroundColor DarkGray
    Write-Host "  cobra modules registry open            - Open registry folder in Explorer" -ForegroundColor DarkGray
    Write-Host "  cobra modules install <name> [version] - Install a module with dependency resolution" -ForegroundColor DarkGray
    Write-Host "  cobra modules update <name>            - Update a module to the latest version" -ForegroundColor DarkGray
    Write-Host "  cobra modules rate <name> <1-5>        - Rate and review a module" -ForegroundColor DarkGray
    Write-Host "  cobra modules info <name>              - Get detailed module information" -ForegroundColor DarkGray
    Write-Host "  cobra modules publish <name>           - Publish a module to the marketplace" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "For complete command list: " -NoNewline -ForegroundColor DarkGray
    Write-Host "cobra help" -ForegroundColor Cyan
}

function CobraDriver([CobraCommand] $command, [string[]] $options) {
    switch ($command) {
        help {
            CobraHelp
        }
        modules {
            if ($options.Count -eq 0) {
                # Show module help instead of listing all modules
                Show-CobraModuleHelp
                return
            }

            # Parse the subcommand and remaining options
            $subCommand = $options[0]
            $remainingOptions = if ($options.Count -gt 1) { $options[1..($options.Count - 1)] } else { @() }
            # Convert the subcommand to the CobraModulesCommands enum
            # Call the modules driver directly
            CobraModulesDriver -command $subCommand -options $remainingOptions
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
        dashboard {
            $interactive = $options -contains "-i" -or $options -contains "--interactive"
            Show-CobraDashboard -Interactive:$interactive
        }
        logs {
            # View the last N log entries
            $searchTerm = ""
            $option = if ($options.Count -gt 0) { 
                $options[0]
                if ($options.Count -gt 1) {
                    $searchTerm = $options[1]
                }
            } 
            else { "view" }

            switch ($option) {
                "view" {
                    $count = if ($options.Count -gt 1) { [int]$options[1] } else { 20 }
                    Show-CobraLogs -Action "view" -Lines $count
                }
                "clear" {
                    Show-CobraLogs -Action "clear"
                }
                "search" {
                    Show-CobraLogs -Action "search" -SearchTerm $searchTerm
                }
                default {
                    Write-Host "Invalid log option: $option" -ForegroundColor Red
                }
            }
        }
        templates {
            if ($options.Count -eq 0) {
                # Show available templates
                Write-Host "COBRA TEMPLATES & SNIPPETS" -ForegroundColor Cyan
                Write-Host "============================" -ForegroundColor Cyan
                $templates = Get-CobraTemplates
                if ($templates) {
                    $templates | Format-Table Name, Type, Description -AutoSize
                }
                else {
                    Write-Host "No templates available. Use 'Initialize-TemplateDirectories' to set up template directories." -ForegroundColor Yellow
                }
                return
            }

            $subCommand = $options[0]
            $remainingOptions = $options[1..($options.Count - 1)]
            
            switch ($subCommand) {
                "list" {
                    $category = if ($remainingOptions.Count -gt 0) { $remainingOptions[0] } else { "all" }
                    $templates = Get-CobraTemplates -Category $category
                    if ($templates) {
                        Write-Host "AVAILABLE TEMPLATES - Category: $($category.ToUpper())" -ForegroundColor Cyan
                        $templates | Format-Table Name, Type, Description, Author -AutoSize
                    }
                    else {
                        Write-Host "No templates found for category: $category" -ForegroundColor Yellow
                    }
                }
                "new" {
                    if ($remainingOptions.Count -lt 2) {
                        Write-Host "Usage: cobra templates new <template-name> <new-module-name>" -ForegroundColor Red
                        return
                    }
                    $templateName = $remainingOptions[0]
                    $moduleName = $remainingOptions[1]
                    New-CobraModuleFromTemplate -TemplateName $templateName -ModuleName $moduleName
                }
                "snippet" {
                    if ($remainingOptions.Count -eq 0) {
                        Write-Host "Usage: cobra templates snippet <snippet-name>" -ForegroundColor Red
                        return
                    }
                    $snippetName = $remainingOptions[0]
                    Copy-CobraSnippet -SnippetName $snippetName
                }
                "search" {
                    if ($remainingOptions.Count -eq 0) {
                        Write-Host "Usage: cobra templates search <search-term>" -ForegroundColor Red
                        return
                    }
                    $searchTerm = $remainingOptions[0]
                    $templates = Get-CobraTemplates -SearchTerm $searchTerm
                    if ($templates) {
                        Write-Host "SEARCH RESULTS FOR: '$searchTerm'" -ForegroundColor Cyan
                        $templates | Format-Table Name, Type, Description, Author -AutoSize
                    }
                    else {
                        Write-Host "No templates found matching: $searchTerm" -ForegroundColor Yellow
                    }
                }
                "save" {
                    Write-Host "Save template functionality requires additional parameters." -ForegroundColor Yellow
                    Write-Host "Usage: cobra templates save <name> <type> -SourcePath <path>" -ForegroundColor Yellow
                }
                "wizard" {
                    $type = if ($remainingOptions.Count -gt 0 -and $remainingOptions[0] -in @("module", "function", "snippet")) { 
                        $remainingOptions[0] 
                    }
                    else { 
                        "module" 
                    }
                    Start-CobraTemplateWizard -Type $type
                }
                "registry" {
                    $registryTemplates = Get-CobraTemplateRegistry
                    if ($registryTemplates) {
                        Write-Host "TEAM TEMPLATE REGISTRY" -ForegroundColor Cyan
                        $registryTemplates | Format-Table Name, Type, Description, Author, Modified -AutoSize
                    }
                    else {
                        Write-Host "Template registry not accessible or empty." -ForegroundColor Yellow
                    }
                }
                "publish" {
                    if ($remainingOptions.Count -eq 0) {
                        Write-Host "Usage: cobra templates publish <template-name> [type]" -ForegroundColor Red
                        Write-Host "  Types: module (default), function, snippet" -ForegroundColor Yellow
                        return
                    }
                    $templateName = $remainingOptions[0]
                    $templateType = if ($remainingOptions.Count -gt 1) { $remainingOptions[1] } else { "module" }
                    Publish-CobraTemplate -Name $templateName -Type $templateType
                }
                "import" {
                    if ($remainingOptions.Count -eq 0) {
                        Write-Host "Usage: cobra templates import <template-name> [type]" -ForegroundColor Red
                        Write-Host "  Types: module (default), function, snippet" -ForegroundColor Yellow
                        return
                    }
                    $templateName = $remainingOptions[0]
                    $templateType = if ($remainingOptions.Count -gt 1) { $remainingOptions[1] } else { "module" }
                    Import-CobraTemplate -Name $templateName -Type $templateType
                }
                default {
                    Write-Host "Invalid templates subcommand: $subCommand" -ForegroundColor Red
                    Write-Host "Available subcommands: list, new, snippet, search, save, wizard, registry, publish, import" -ForegroundColor Yellow
                }
            }
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
