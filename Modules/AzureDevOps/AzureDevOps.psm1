# Azure DevOps Productivity Module for Cobra Framework
# Version: 1.0.0
# Author: Cobra Framework Team
# Description: Comprehensive Azure DevOps integration for enhanced developer productivity

#region Initialization
function Initialize-AzureDevOpsModule {
    [CmdletBinding()]
    param()
    
    # Validate configuration
    $config = . "$PSScriptRoot/config.ps1"
    if (-not $config) {
        throw "Failed to load module configuration"
    }
    
    # Load module configuration
    $config = . "$PSScriptRoot/config.ps1"
    
    # Register as standalone module (no repository dependency)
    Register-CobraStandaloneModule -Name "AzureDevOps" -Description "$($config.Description)" -Config $config

    Log-CobraActivity "AzureDevOps standalone module initialized"
}

# Initialize the module when loaded
Initialize-AzureDevOpsModule
#endregion

#region Configuration Functions
function Get-AzureDevOpsConfig {
    <#
    .SYNOPSIS
    Gets the Azure DevOps configuration from the current repository context
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Get current repository context
        $currentRepo = GetCurrentAppConfig
        
        if ($null -eq $currentRepo) {
            throw "No repository context is currently active. Please run 'repo <repository-name>' first to set the context."
        }
        
        # Check if repository supports Azure DevOps integration
        if (-not $currentRepo.ContainsKey("AzureDevOps")) {
            throw "Current repository '$($currentRepo.Name)' does not support Azure DevOps integration. Add an 'AzureDevOps' section to the repository configuration."
        }
        
        $azConfig = $currentRepo.AzureDevOps
        
        # Validate required fields
        $validationErrors = @()
        
        if (-not $azConfig.ContainsKey("Organization") -or [string]::IsNullOrWhiteSpace($azConfig.Organization)) {
            $validationErrors += "Organization is required"
        }
        
        if (-not $azConfig.ContainsKey("Project") -or [string]::IsNullOrWhiteSpace($azConfig.Project)) {
            $validationErrors += "Project is required"
        }
        
        if ($validationErrors.Count -gt 0) {
            throw "Azure DevOps configuration validation failed:`n" + ($validationErrors -join "`n")
        }
        
        Write-AzureDevOpsLog "INFO" "Retrieved Azure DevOps configuration for $($azConfig.Organization)/$($azConfig.Project)"
        return $azConfig
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Azure DevOps configuration error: $($_.Exception.Message)"
        throw
    }
}

function Test-AzureDevOpsConfig {
    <#
    .SYNOPSIS
    Tests and validates the Azure DevOps configuration
    #>
    [CmdletBinding()]
    param(
        [switch]$ShowStatus
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        
        if ($ShowStatus) {
            Write-Host "Azure DevOps Configuration Status" -ForegroundColor Cyan
            Write-Host "==================================" -ForegroundColor Cyan
            Write-Host ""
            
            Write-Host "OK - Organization: " -NoNewline -ForegroundColor Green
            Write-Host $config.Organization -ForegroundColor White
            Write-Host "OK - Project: " -NoNewline -ForegroundColor Green
            Write-Host $config.Project -ForegroundColor White
            
            Write-Host ""
            Write-Host "Configuration is valid and ready to use!" -ForegroundColor Green
        }
        
        return $true
    } 
    catch {
        if ($ShowStatus) {
            Write-Host "Azure DevOps Configuration Status" -ForegroundColor Cyan
            Write-Host "==================================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "[ERROR] Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}
#endregion

#region Work Items Functions
function Get-MyWorkItems {
    <#
    .SYNOPSIS
    Retrieves work items assigned to the current user
    #>
    [CmdletBinding()]
    param(
        [string]$State,
        [int]$Top = 10,
        [string[]]$WorkItemTypes = @(),
        [string]$AssignedTo
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        
        # Build WIQL query  
        $wiqlQuery = "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo], [System.CreatedDate] FROM WorkItems WHERE [System.TeamProject] = '$($config.Project)'"
        
        if ($State) {
            $wiqlQuery += " AND [System.State] = '$State'"
        }
        
        if ($WorkItemTypes.Count -gt 0) {
            $typeFilter = ($WorkItemTypes | ForEach-Object { "'$_'" }) -join ", "
            $wiqlQuery += " AND [System.WorkItemType] IN ($typeFilter)"
        }
        
        if ($AssignedTo) {
            $wiqlQuery += " AND [System.AssignedTo] = '$AssignedTo'"
        }
        else {
            $wiqlQuery += " AND [System.AssignedTo] = @Me"
        }
        
        $wiqlQuery += " ORDER BY [System.CreatedDate] DESC"
        
        # Execute query
        $result = az boards query --wiql $wiqlQuery --organization $config.Organization --top $Top --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $queryResult = $result | ConvertFrom-Json
            
            if ($queryResult.workItems.Count -eq 0) {
                Write-Host "No work items found matching the criteria" -ForegroundColor Yellow
                return @()
            }
            
            Write-Host "Work Items:" -ForegroundColor Cyan
            Write-Host "===========" -ForegroundColor Cyan
            Write-Host ""
            
            $queryResult.workItems | ForEach-Object {
                $wi = $_.fields
                $statusColor = switch ($wi.'System.State') {
                    'New' { 'White' }
                    'Active' { 'Yellow' }
                    'Resolved' { 'Green' }
                    'Closed' { 'DarkGreen' }
                    default { 'White' }
                }
                
                $typeIcon = switch ($wi.'System.WorkItemType') {
                    'Bug' { '[BUG]' }
                    'Task' { '[TASK]' }
                    'User Story' { '[STORY]' }
                    'Feature' { '[FEAT]' }
                    default { '[ITEM]' }
                }
                
                Write-Host "$typeIcon $($wi.'System.Id'): " -NoNewline -ForegroundColor Green
                Write-Host $wi.'System.Title' -ForegroundColor White
                Write-Host "   State: " -NoNewline -ForegroundColor DarkGray
                Write-Host $wi.'System.State' -ForegroundColor $statusColor
                if ($wi.'System.AssignedTo') {
                    Write-Host "   Assigned: " -NoNewline -ForegroundColor DarkGray
                    Write-Host $wi.'System.AssignedTo'.displayName -ForegroundColor DarkGray
                }
                Write-Host ""
            }
            
            Write-AzureDevOpsLog "INFO" "Retrieved $($queryResult.workItems.Count) work items"
            return $queryResult.workItems
        }
        else {
            Write-Host "No work items found or error occurred" -ForegroundColor Yellow
            return @()
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get work items: $($_.Exception.Message)"
        Write-Host "Error getting work items: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function New-WorkItem {
    <#
    .SYNOPSIS
    Creates a new work item in Azure DevOps
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [string]$Description = "",
        [string]$AssignedTo = ""
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        
        # Build Azure CLI command
        $cmdArgs = @(
            'boards', 'work-item', 'create',
            '--type', $Type,
            '--title', $Title,
            '--organization', $config.Organization,
            '--project', $config.Project,
            '--output', 'json'
        )
        
        if ($Description) {
            $cmdArgs += @('--description', $Description)
        }
        
        if ($AssignedTo) {
            $cmdArgs += @('--assigned-to', $AssignedTo)
        }
        
        # Execute command
        $result = & az @cmdArgs 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $workItem = $result | ConvertFrom-Json
            Write-Host "SUCCESS - Work item created successfully!" -ForegroundColor Green
            Write-Host "ID: $($workItem.id)" -ForegroundColor White
            Write-Host "Title: $($workItem.fields.'System.Title')" -ForegroundColor White
            Write-Host "Type: $($workItem.fields.'System.WorkItemType')" -ForegroundColor White
            Write-Host "URL: $($workItem._links.html.href)" -ForegroundColor Blue
            
            Write-AzureDevOpsLog "INFO" "Created work item: $($workItem.id) - $($workItem.fields.'System.Title')"
            return $workItem
        }
        else {
            Write-Host "Failed to create work item" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to create work item: $($_.Exception.Message)"
        Write-Host "Error creating work item: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}
#endregion

#region Driver Interface

enum AzureDevOpsCommand {
    help
    config
    status
    template
    workitems
    builds
    pipelines
    repos
    prs
    sprints
}

enum AzureDevOpsSubCommand {
    help
    list
    new
    update
    delete
    show
    active
    completed
    assigned
    created
    recent
    open
    merge
    approve
    abandon
    current
    backlog
    progress
}

function AzureDevOpsDriver {
    <#
    .SYNOPSIS
    Main driver function for Azure DevOps hierarchical commands
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [AzureDevOpsCommand]$Command = [AzureDevOpsCommand]::help,
        
        [Parameter(Position = 1)]
        [AzureDevOpsSubCommand]$SubCommand = [AzureDevOpsSubCommand]::help,
        
        # Common parameters
        [int]$ID,
        [int]$Top = 10,
        [string]$Title,
        [string]$Description,
        [string]$AssignedTo,
        [string]$State,
        [string]$Type,
        [string]$Branch,
        [string]$SourceBranch,
        [string]$TargetBranch,
        [string]$Pipeline,
        [switch]$ShowDetails,
        
        # Template-specific parameters
        [string]$Organization,
        [string]$Project,
        [string]$Repository,
        [string]$Team,
        [string]$DefaultBranch,
        [switch]$Minimal,
        [switch]$NoClipboard
    )

    Log-CobraActivity "Azure DevOps command executed: $Command $SubCommand $(if($ID) { "ID=$ID" })"

    try {
        # Commands that don't require repository context
        $noContextCommands = @([AzureDevOpsCommand]::help, [AzureDevOpsCommand]::template)
        
        # Validate Azure DevOps configuration for current repository (except for help and template commands)
        if ($Command -notin $noContextCommands) {
            $config = Get-AzureDevOpsConfig
            if (-not $config) {
                return
            }
        }
    }
    catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    switch ($Command) {
        help {
            Show-AzureDevOpsHelp
        }
        config {
            Test-AzureDevOpsConfig -ShowStatus
        }
        status {
            Get-AzureDevOpsStatus
        }
        template {
            Get-AzureDevOpsConfigTemplate -Organization $Organization -Project $Project -Repository $Repository -Team $Team -DefaultBranch $DefaultBranch -Minimal:$Minimal -NoClipboard:$NoClipboard
        }
        workitems {
            Invoke-WorkItemsCommand -SubCommand $SubCommand -ID $ID -Top $Top -Title $Title -Description $Description -AssignedTo $AssignedTo -State $State -Type $Type -ShowDetails:$ShowDetails
        }
        builds {
            Invoke-BuildsCommand -SubCommand $SubCommand -ID $ID -Top $Top -Pipeline $Pipeline -ShowDetails:$ShowDetails
        }
        pipelines {
            Invoke-PipelinesCommand -SubCommand $SubCommand -ID $ID -Top $Top -Pipeline $Pipeline -ShowDetails:$ShowDetails
        }
        repos {
            Invoke-ReposCommand -SubCommand $SubCommand -Branch $Branch -ShowDetails:$ShowDetails
        }
        prs {
            Invoke-PrsCommand -SubCommand $SubCommand -ID $ID -Top $Top -SourceBranch $SourceBranch -TargetBranch $TargetBranch -Title $Title -Description $Description -AssignedTo $AssignedTo -State $State -ShowDetails:$ShowDetails
        }
        sprints {
            Invoke-SprintsCommand -SubCommand $SubCommand -ShowDetails:$ShowDetails
        }
    }
}

function Invoke-WorkItemsCommand {
    [CmdletBinding()]
    param(
        [AzureDevOpsSubCommand]$SubCommand,
        [int]$ID,
        [int]$Top,
        [string]$Title,
        [string]$Description,
        [string]$AssignedTo,
        [string]$State,
        [string]$Type,
        [switch]$ShowDetails
    )

    switch ($SubCommand) {
        help {
            Show-WorkItemsHelp
        }
        list {
            if ($State) {
                Get-MyWorkItems -State $State -Top $Top
            }
            else {
                Get-MyWorkItems -Top $Top
            }
        }
        new {
            if (-not $Type) {
                $Type = Read-Host "Work item type (Bug, Task, User Story, etc.)"
            }
            if (-not $Title) {
                $Title = Read-Host "Title"
            }
            New-WorkItem -Type $Type -Title $Title -Description $Description -AssignedTo $AssignedTo
        }
        active {
            Get-MyWorkItems -State "Active" -Top $Top
        }
        assigned {
            Get-MyWorkItems -AssignedTo $AssignedTo -Top $Top
        }
        show {
            if ($ID) {
                Get-WorkItemDetails -ID $ID
            }
            else {
                Write-Host "Error: ID parameter required for show command" -ForegroundColor Red
                Write-Host "Example: azdevops workitems show 1234" -ForegroundColor Yellow
            }
        }
        update {
            if ($ID) {
                Update-WorkItem -ID $ID -Title $Title -Description $Description -AssignedTo $AssignedTo -State $State
            }
            else {
                Write-Host "Error: ID parameter required for update command" -ForegroundColor Red
                Write-Host "Example: azdevops workitems update 1234 -State 'Resolved'" -ForegroundColor Yellow
            }
        }
        default {
            Show-WorkItemsHelp
        }
    }
}

function Invoke-BuildsCommand {
    [CmdletBinding()]
    param(
        [AzureDevOpsSubCommand]$SubCommand,
        [int]$ID,
        [int]$Top,
        [string]$Pipeline,
        [switch]$ShowDetails
    )

    switch ($SubCommand) {
        help {
            Show-BuildsHelp
        }
        list {
            Get-BuildStatus -Top $Top -PipelineName $Pipeline
        }
        recent {
            Get-BuildStatus -Top $Top
        }
        show {
            if ($ID) {
                Get-BuildDetails -BuildID $ID
            }
            else {
                Write-Host "Error: ID parameter required for show command" -ForegroundColor Red
                Write-Host "Example: azdevops builds show 12345" -ForegroundColor Yellow
            }
        }
        default {
            Show-BuildsHelp
        }
    }
}

function Invoke-PipelinesCommand {
    [CmdletBinding()]
    param(
        [AzureDevOpsSubCommand]$SubCommand,
        [int]$ID,
        [int]$Top,
        [string]$Pipeline,
        [switch]$ShowDetails
    )

    switch ($SubCommand) {
        help {
            Show-PipelinesHelp
        }
        list {
            Get-Pipelines
        }
        show {
            if ($Pipeline) {
                Start-BuildPipeline -PipelineName $Pipeline
            }
            else {
                Write-Host "Error: Pipeline parameter required for show command" -ForegroundColor Red
                Write-Host "Example: azdevops pipelines show 'CI Build'" -ForegroundColor Yellow
            }
        }
        default {
            Show-PipelinesHelp
        }
    }
}

function Invoke-ReposCommand {
    [CmdletBinding()]
    param(
        [AzureDevOpsSubCommand]$SubCommand,
        [string]$Branch,
        [switch]$ShowDetails
    )

    switch ($SubCommand) {
        help {
            Show-ReposHelp
        }
        list {
            Get-Repositories
        }
        default {
            Show-ReposHelp
        }
    }
}

function Invoke-PrsCommand {
    [CmdletBinding()]
    param(
        [AzureDevOpsSubCommand]$SubCommand,
        [int]$ID,
        [int]$Top,
        [string]$SourceBranch,
        [string]$TargetBranch,
        [string]$Title,
        [string]$Description,
        [string]$AssignedTo,
        [string]$State,
        [switch]$ShowDetails
    )

    switch ($SubCommand) {
        help {
            Show-PrsHelp
        }
        list {
            if ($State) {
                Get-PullRequests -State $State -Top $Top
            }
            else {
                Get-PullRequests -Top $Top
            }
        }
        new {
            if (-not $SourceBranch) {
                $SourceBranch = Read-Host "Source branch"
            }
            if (-not $TargetBranch) {
                $TargetBranch = Read-Host "Target branch (default: main)"
                if ([string]::IsNullOrEmpty($TargetBranch)) { $TargetBranch = "main" }
            }
            if (-not $Title) {
                $Title = Read-Host "Title"
            }
            New-PullRequest -SourceBranch $SourceBranch -TargetBranch $TargetBranch -Title $Title -Description $Description
        }
        active {
            Get-PullRequests -State "Active" -Top $Top
        }
        show {
            if ($ID) {
                Get-PullRequestDetails -PullRequestID $ID
            }
            else {
                Write-Host "Error: ID parameter required for show command" -ForegroundColor Red
                Write-Host "Example: azdevops prs show 123" -ForegroundColor Yellow
            }
        }
        approve {
            if ($ID) {
                Approve-PullRequest -PullRequestID $ID
            }
            else {
                Write-Host "Error: ID parameter required for approve command" -ForegroundColor Red
                Write-Host "Example: azdevops prs approve 123" -ForegroundColor Yellow
            }
        }
        default {
            Show-PrsHelp
        }
    }
}

function Invoke-SprintsCommand {
    [CmdletBinding()]
    param(
        [AzureDevOpsSubCommand]$SubCommand,
        [switch]$ShowDetails
    )

    switch ($SubCommand) {
        help {
            Show-SprintsHelp
        }
        current {
            Get-CurrentSprint
        }
        progress {
            Get-SprintProgress -ShowBurndown
        }
        backlog {
            Get-SprintBacklog
        }
        default {
            Show-SprintsHelp
        }
    }
}

# Additional Functions for Driver Interface
function Get-BuildStatus {
    <#
    .SYNOPSIS
    Gets the status of recent builds in Azure DevOps
    #>
    [CmdletBinding()]
    param(
        [string]$PipelineName,
        [int]$Top = 10,
        [ValidateSet("inProgress", "completed", "cancelling", "postponed", "notStarted", "all")]
        [string]$Status = "all",
        [switch]$ShowDetails,
        [switch]$Monitor
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        
        do {
            if ($Monitor) { Clear-Host }
            Write-Host "Recent Builds:" -ForegroundColor Cyan
            Write-Host "=============" -ForegroundColor Cyan
            Write-Host ""
            
            $cmdArgs = @('pipelines', 'runs', 'list', '--organization', $config.Organization, '--project', $config.Project, '--top', $Top, '--output', 'json')
            
            if ($PipelineName) {
                $cmdArgs += @('--pipeline-name', $PipelineName)
            }
            
            if ($Status -ne "all") {
                $cmdArgs += @('--status', $Status)
            }
            
            $result = & az @cmdArgs 2>$null
            
            if ($LASTEXITCODE -eq 0 -and $result) {
                $builds = $result | ConvertFrom-Json
                
                if ($builds.Count -eq 0) {
                    Write-Host "No builds found" -ForegroundColor Yellow
                    return @()
                }
                
                $builds | ForEach-Object {
                    $statusColor = switch ($_.status) {
                        "completed" {
                            switch ($_.result) {
                                "succeeded" { 'Green' }
                                "failed" { 'Red' }
                                "canceled" { 'Yellow' }
                                default { 'Gray' }
                            }
                        }
                        "inProgress" { 'Cyan' }
                        default { 'Yellow' }
                    }
                    
                    $statusIcon = if ($_.status -eq "completed") {
                        switch ($_.result) {
                            "succeeded" { "✅" }
                            "failed" { "❌" }
                            "canceled" { "⚠️" }
                            default { "🔄" }
                        }
                    }
                    else {
                        switch ($_.status) {
                            "inProgress" { "🔄" }
                            default { "⏸️" }
                        }
                    }
                    
                    Write-Host "$statusIcon Build #$($_.id): " -NoNewline -ForegroundColor Green
                    Write-Host $_.definition.name -ForegroundColor White
                    Write-Host "   Status: " -NoNewline -ForegroundColor DarkGray
                    Write-Host $_.status -ForegroundColor $statusColor
                    if ($_.result) {
                        Write-Host "   Result: " -NoNewline -ForegroundColor DarkGray
                        Write-Host $_.result -ForegroundColor $statusColor
                    }
                    Write-Host "   Branch: " -NoNewline -ForegroundColor DarkGray
                    Write-Host ($_.sourceBranch -replace '^refs/heads/', '') -ForegroundColor DarkGray
                    Write-Host ""
                }
                
                Write-AzureDevOpsLog "INFO" "Retrieved $($builds.Count) builds"
                
                if ($Monitor) {
                    Write-Host "Press Ctrl+C to stop monitoring..." -ForegroundColor DarkGray
                    Start-Sleep -Seconds 30
                }
                
                return $builds
            }
            else {
                Write-Host "No builds found or error occurred" -ForegroundColor Yellow
                return @()
            }
        } while ($Monitor)
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get build status: $($_.Exception.Message)"
        Write-Host "Error getting build status: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Start-BuildPipeline {
    <#
    .SYNOPSIS
    Starts a build pipeline in Azure DevOps
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PipelineName,
        [string]$Branch,
        [hashtable]$Parameters,
        [switch]$WaitForCompletion,
        [switch]$ShowProgress
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        
        $cmdArgs = @('pipelines', 'run', '--organization', $config.Organization, '--project', $config.Project, '--name', $PipelineName, '--output', 'json')
        
        if ($Branch) {
            $cmdArgs += @('--branch', $Branch)
        }
        
        if ($Parameters) {
            foreach ($param in $Parameters.GetEnumerator()) {
                $cmdArgs += @('--variables', "$($param.Key)=$($param.Value)")
            }
        }
        
        $result = & az @cmdArgs 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $build = $result | ConvertFrom-Json
            Write-Host "✅ Pipeline started successfully!" -ForegroundColor Green
            Write-Host "Build ID: $($build.id)" -ForegroundColor White
            Write-Host "Pipeline: $($build.definition.name)" -ForegroundColor White
            Write-Host "URL: $($build._links.web.href)" -ForegroundColor Blue
            
            if ($WaitForCompletion -or $ShowProgress) {
                Write-Host "`nMonitoring build progress..." -ForegroundColor Yellow
                do {
                    Start-Sleep -Seconds 10
                    $buildStatus = Get-BuildDetails -BuildID $build.id
                    if ($buildStatus) {
                        Write-Host "Status: $($buildStatus.status) | Result: $($buildStatus.result)" -ForegroundColor Cyan
                    }
                } while ($buildStatus -and $buildStatus.status -eq "inProgress")
            }
            
            Write-AzureDevOpsLog "INFO" "Started pipeline: $PipelineName (Build ID: $($build.id))"
            return $build
        }
        else {
            Write-Host "Failed to start pipeline" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to start pipeline: $($_.Exception.Message)"
        Write-Host "Error starting pipeline: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-Pipelines {
    <#
    .SYNOPSIS
    Gets all build pipelines in the current project
    #>
    [CmdletBinding()]
    param()
    
    try {
        $config = Get-AzureDevOpsConfig
        $result = az pipelines list --organization $config.Organization --project $config.Project --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $pipelines = $result | ConvertFrom-Json
            
            Write-Host "Build Pipelines:" -ForegroundColor Cyan
            Write-Host "===============" -ForegroundColor Cyan
            Write-Host ""
            
            $pipelines | ForEach-Object {
                Write-Host "📋 $($_.name)" -ForegroundColor Green
                Write-Host "   ID: $($_.id)" -ForegroundColor DarkGray
                Write-Host "   Folder: $($_.folder)" -ForegroundColor DarkGray
                Write-Host ""
            }
            
            Write-AzureDevOpsLog "INFO" "Retrieved $($pipelines.Count) pipelines"
            return $pipelines
        }
        else {
            Write-Host "No pipelines found or error occurred" -ForegroundColor Yellow
            return @()
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get pipelines: $($_.Exception.Message)"
        Write-Host "Error getting pipelines: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Get-Repositories {
    <#
    .SYNOPSIS
    Gets all repositories in the current project
    #>
    [CmdletBinding()]
    param()
    
    try {
        $config = Get-AzureDevOpsConfig
        $result = az repos list --organization $config.Organization --project $config.Project --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $repos = $result | ConvertFrom-Json
            
            Write-Host "Repositories:" -ForegroundColor Cyan
            Write-Host "============" -ForegroundColor Cyan
            Write-Host ""
            
            $repos | ForEach-Object {
                Write-Host "📂 $($_.name)" -ForegroundColor Green
                Write-Host "   ID: $($_.id)" -ForegroundColor DarkGray
                Write-Host "   URL: $($_.remoteUrl)" -ForegroundColor DarkGray
                Write-Host "   Default Branch: $($_.defaultBranch -replace '^refs/heads/', '')" -ForegroundColor DarkGray
                Write-Host ""
            }
            
            Write-AzureDevOpsLog "INFO" "Retrieved $($repos.Count) repositories"
            return $repos
        }
        else {
            Write-Host "No repositories found or error occurred" -ForegroundColor Yellow
            return @()
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get repositories: $($_.Exception.Message)"
        Write-Host "Error getting repositories: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Get-WorkItemDetails {
    <#
    .SYNOPSIS
    Gets detailed information about a specific work item
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ID
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        $result = az boards work-item show --id $ID --organization $config.Organization --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $workItem = $result | ConvertFrom-Json
            
            Write-Host "Work Item Details:" -ForegroundColor Cyan
            Write-Host "=================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "ID: " -NoNewline -ForegroundColor Yellow
            Write-Host $workItem.id -ForegroundColor Green
            Write-Host "Title: " -NoNewline -ForegroundColor Yellow
            Write-Host $workItem.fields.'System.Title' -ForegroundColor Green
            Write-Host "Type: " -NoNewline -ForegroundColor Yellow
            Write-Host $workItem.fields.'System.WorkItemType' -ForegroundColor Green
            Write-Host "State: " -NoNewline -ForegroundColor Yellow
            Write-Host $workItem.fields.'System.State' -ForegroundColor $(
                switch ($workItem.fields.'System.State') {
                    'New' { 'White' }
                    'Active' { 'Yellow' }
                    'Resolved' { 'Green' }
                    'Closed' { 'DarkGreen' }
                    default { 'White' }
                }
            )
            
            if ($workItem.fields.'System.AssignedTo') {
                Write-Host "Assigned To: " -NoNewline -ForegroundColor Yellow
                Write-Host $workItem.fields.'System.AssignedTo'.displayName -ForegroundColor Green
            }
            
            if ($workItem.fields.'System.CreatedBy') {
                Write-Host "Created By: " -NoNewline -ForegroundColor Yellow
                Write-Host $workItem.fields.'System.CreatedBy'.displayName -ForegroundColor Green
            }
            
            Write-Host "Created Date: " -NoNewline -ForegroundColor Yellow
            Write-Host (Get-Date $workItem.fields.'System.CreatedDate' -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Green
            
            if ($workItem.fields.'System.Description') {
                Write-Host ""
                Write-Host "Description:" -ForegroundColor Yellow
                Write-Host $workItem.fields.'System.Description' -ForegroundColor White
            }
            
            Write-AzureDevOpsLog "INFO" "Retrieved details for work item $ID"
            return $workItem
        }
        else {
            Write-Host "Work item $ID not found or error occurred" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get work item details for $ID : $($_.Exception.Message)"
        Write-Host "Error getting work item details: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Update-WorkItem {
    <#
    .SYNOPSIS
    Updates a work item with new values
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ID,
        [string]$Title,
        [string]$Description,
        [string]$AssignedTo,
        [string]$State
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        $updateFields = @()
        
        if ($Title) { $updateFields += "System.Title=`"$Title`"" }
        if ($Description) { $updateFields += "System.Description=`"$Description`"" }
        if ($AssignedTo) { $updateFields += "System.AssignedTo=`"$AssignedTo`"" }
        if ($State) { $updateFields += "System.State=`"$State`"" }
        
        if ($updateFields.Count -eq 0) {
            Write-Host "No fields to update specified" -ForegroundColor Yellow
            return
        }
        
        $fieldsString = $updateFields -join ' '
        $result = az boards work-item update --id $ID --fields $fieldsString --organization $config.Organization --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $updatedItem = $result | ConvertFrom-Json
            Write-Host "✅ Work item $ID updated successfully" -ForegroundColor Green
            Write-Host "Title: $($updatedItem.fields.'System.Title')" -ForegroundColor White
            Write-Host "State: $($updatedItem.fields.'System.State')" -ForegroundColor White
            
            Write-AzureDevOpsLog "INFO" "Updated work item $ID"
            return $updatedItem
        }
        else {
            Write-Host "Failed to update work item $ID" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to update work item $ID : $($_.Exception.Message)"
        Write-Host "Error updating work item: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-BuildDetails {
    <#
    .SYNOPSIS
    Gets detailed information about a specific build
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$BuildID
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        $result = az pipelines build show --id $BuildID --organization $config.Organization --project $config.Project --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $build = $result | ConvertFrom-Json
            
            Write-Host "Build Details:" -ForegroundColor Cyan
            Write-Host "=============" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Build ID: " -NoNewline -ForegroundColor Yellow
            Write-Host $build.id -ForegroundColor Green
            Write-Host "Pipeline: " -NoNewline -ForegroundColor Yellow
            Write-Host $build.definition.name -ForegroundColor Green
            Write-Host "Status: " -NoNewline -ForegroundColor Yellow
            Write-Host $build.status -ForegroundColor $(
                switch ($build.status) {
                    "completed" {
                        switch ($build.result) {
                            "succeeded" { 'Green' }
                            "failed" { 'Red' }
                            "canceled" { 'Yellow' }
                            default { 'Gray' }
                        }
                    }
                    "inProgress" { 'Cyan' }
                    default { 'Yellow' }
                }
            )
            
            if ($build.result) {
                Write-Host "Result: " -NoNewline -ForegroundColor Yellow
                Write-Host $build.result -ForegroundColor $(
                    switch ($build.result) {
                        "succeeded" { 'Green' }
                        "failed" { 'Red' }
                        "canceled" { 'Yellow' }
                        default { 'Gray' }
                    }
                )
            }
            
            Write-Host "Start Time: " -NoNewline -ForegroundColor Yellow
            Write-Host (Get-Date $build.startTime -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Green
            
            if ($build.finishTime) {
                Write-Host "Finish Time: " -NoNewline -ForegroundColor Yellow
                Write-Host (Get-Date $build.finishTime -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Green
            }
            
            Write-Host "Source Branch: " -NoNewline -ForegroundColor Yellow
            Write-Host ($build.sourceBranch -replace '^refs/heads/', '') -ForegroundColor Green
            
            Write-Host "Triggered By: " -NoNewline -ForegroundColor Yellow
            Write-Host $build.requestedBy.displayName -ForegroundColor Green
            
            Write-AzureDevOpsLog "INFO" "Retrieved build details for $BuildID"
            return $build
        }
        else {
            Write-Host "Build $BuildID not found or error occurred" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get build details for $BuildID : $($_.Exception.Message)"
        Write-Host "Error getting build details: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-PullRequests {
    <#
    .SYNOPSIS
    Gets pull requests with optional filtering
    #>
    [CmdletBinding()]
    param(
        [string]$State,
        [int]$Top = 10
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        $cmdArgs = @('repos', 'pr', 'list', '--organization', $config.Organization, '--project', $config.Project, '--top', $Top, '--output', 'json')
        
        if ($State) {
            $cmdArgs += @('--status', $State.ToLower())
        }
        
        $result = & az @cmdArgs 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $pullRequests = $result | ConvertFrom-Json
            
            if ($pullRequests.Count -eq 0) {
                Write-Host "No pull requests found" -ForegroundColor Yellow
                return @()
            }
            
            Write-Host "Pull Requests:" -ForegroundColor Cyan
            Write-Host "==============" -ForegroundColor Cyan
            Write-Host ""
            
            $pullRequests | ForEach-Object {
                $statusColor = switch ($_.status) {
                    'active' { 'Yellow' }
                    'completed' { 'Green' }
                    'abandoned' { 'Red' }
                    default { 'White' }
                }
                
                Write-Host "🔀 PR #$($_.pullRequestId): " -NoNewline -ForegroundColor Green
                Write-Host $_.title -ForegroundColor White
                Write-Host "   Status: " -NoNewline -ForegroundColor DarkGray
                Write-Host $_.status -ForegroundColor $statusColor
                Write-Host "   $($_.sourceRefName -replace '^refs/heads/', '') → $($_.targetRefName -replace '^refs/heads/', '')" -ForegroundColor DarkGray
                Write-Host "   Created by: $($_.createdBy.displayName)" -ForegroundColor DarkGray
                Write-Host ""
            }
            
            Write-AzureDevOpsLog "INFO" "Retrieved $($pullRequests.Count) pull requests"
            return $pullRequests
        }
        else {
            Write-Host "No pull requests found or error occurred" -ForegroundColor Yellow
            return @()
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get pull requests: $($_.Exception.Message)"
        Write-Host "Error getting pull requests: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function New-PullRequest {
    <#
    .SYNOPSIS
    Creates a new pull request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceBranch,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetBranch,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [string]$Description = ""
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        
        $cmdArgs = @(
            'repos', 'pr', 'create',
            '--organization', $config.Organization,
            '--project', $config.Project,
            '--source-branch', $SourceBranch,
            '--target-branch', $TargetBranch,
            '--title', $Title,
            '--output', 'json'
        )
        
        if ($Description) {
            $cmdArgs += @('--description', $Description)
        }
        
        $result = & az @cmdArgs 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $pullRequest = $result | ConvertFrom-Json
            
            Write-Host "✅ Pull Request created successfully!" -ForegroundColor Green
            Write-Host "PR #$($pullRequest.pullRequestId): $($pullRequest.title)" -ForegroundColor White
            Write-Host "URL: $($pullRequest.remoteUrl)" -ForegroundColor Blue
            
            Write-AzureDevOpsLog "INFO" "Created pull request #$($pullRequest.pullRequestId)"
            return $pullRequest
        }
        else {
            Write-Host "Failed to create pull request" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to create pull request: $($_.Exception.Message)"
        Write-Host "Error creating pull request: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-PullRequestDetails {
    <#
    .SYNOPSIS
    Gets detailed information about a specific pull request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$PullRequestID
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        $result = az repos pr show --id $PullRequestID --organization $config.Organization --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $pr = $result | ConvertFrom-Json
            
            Write-Host "Pull Request Details:" -ForegroundColor Cyan
            Write-Host "===================" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "PR #$($pr.pullRequestId): " -NoNewline -ForegroundColor Yellow
            Write-Host $pr.title -ForegroundColor Green
            Write-Host "Status: " -NoNewline -ForegroundColor Yellow
            Write-Host $pr.status -ForegroundColor $(
                switch ($pr.status) {
                    'active' { 'Yellow' }
                    'completed' { 'Green' }
                    'abandoned' { 'Red' }
                    default { 'White' }
                }
            )
            
            Write-Host "Source: " -NoNewline -ForegroundColor Yellow
            Write-Host ($pr.sourceRefName -replace '^refs/heads/', '') -ForegroundColor Green
            Write-Host "Target: " -NoNewline -ForegroundColor Yellow
            Write-Host ($pr.targetRefName -replace '^refs/heads/', '') -ForegroundColor Green
            
            Write-Host "Created By: " -NoNewline -ForegroundColor Yellow
            Write-Host $pr.createdBy.displayName -ForegroundColor Green
            Write-Host "Created Date: " -NoNewline -ForegroundColor Yellow
            Write-Host (Get-Date $pr.creationDate -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Green
            
            if ($pr.description) {
                Write-Host ""
                Write-Host "Description:" -ForegroundColor Yellow
                Write-Host $pr.description -ForegroundColor White
            }
            
            Write-Host ""
            Write-Host "URL: " -NoNewline -ForegroundColor Yellow
            Write-Host $pr.remoteUrl -ForegroundColor Blue
            
            Write-AzureDevOpsLog "INFO" "Retrieved PR details for #$PullRequestID"
            return $pr
        }
        else {
            Write-Host "Pull request #$PullRequestID not found or error occurred" -ForegroundColor Red
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get PR details for #$PullRequestID : $($_.Exception.Message)"
        Write-Host "Error getting pull request details: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Approve-PullRequest {
    <#
    .SYNOPSIS
    Approves a pull request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$PullRequestID
    )
    
    try {
        $config = Get-AzureDevOpsConfig
        $result = az repos pr set-vote --id $PullRequestID --vote approve --organization $config.Organization --output json 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Pull Request #$PullRequestID approved successfully!" -ForegroundColor Green
            Write-AzureDevOpsLog "INFO" "Approved pull request #$PullRequestID"
        }
        else {
            Write-Host "Failed to approve pull request #$PullRequestID" -ForegroundColor Red
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to approve PR #$PullRequestID : $($_.Exception.Message)"
        Write-Host "Error approving pull request: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Get-CurrentSprint {
    <#
    .SYNOPSIS
    Gets information about the current sprint
    #>
    [CmdletBinding()]
    param()
    
    try {
        $config = Get-AzureDevOpsConfig
        $teamArgs = if ($config.Team) { @('--team', $config.Team) } else { @() }
        
        $result = & az boards iteration team list --organization $config.Organization --project $config.Project @teamArgs --timeframe current --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $sprints = $result | ConvertFrom-Json
            
            if ($sprints.Count -eq 0) {
                Write-Host "No current sprint found" -ForegroundColor Yellow
                return $null
            }
            
            $currentSprint = $sprints[0]
            
            Write-Host "Current Sprint:" -ForegroundColor Cyan
            Write-Host "===============" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Name: " -NoNewline -ForegroundColor Yellow
            Write-Host $currentSprint.name -ForegroundColor Green
            Write-Host "Start Date: " -NoNewline -ForegroundColor Yellow
            Write-Host (Get-Date $currentSprint.attributes.startDate -Format 'yyyy-MM-dd') -ForegroundColor Green
            Write-Host "End Date: " -NoNewline -ForegroundColor Yellow
            Write-Host (Get-Date $currentSprint.attributes.finishDate -Format 'yyyy-MM-dd') -ForegroundColor Green
            
            $totalDays = (Get-Date $currentSprint.attributes.finishDate) - (Get-Date $currentSprint.attributes.startDate)
            $daysRemaining = (Get-Date $currentSprint.attributes.finishDate) - (Get-Date)
            
            Write-Host "Days Remaining: " -NoNewline -ForegroundColor Yellow
            Write-Host "$([math]::Max(0, [math]::Ceiling($daysRemaining.TotalDays))) of $([math]::Ceiling($totalDays.TotalDays))" -ForegroundColor $(
                if ($daysRemaining.TotalDays -lt 2) { 'Red' } elseif ($daysRemaining.TotalDays -lt 5) { 'Yellow' } else { 'Green' }
            )
            
            Write-AzureDevOpsLog "INFO" "Retrieved current sprint: $($currentSprint.name)"
            return $currentSprint
        }
        else {
            Write-Host "No current sprint found or error occurred" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get current sprint: $($_.Exception.Message)"
        Write-Host "Error getting current sprint: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

function Get-SprintBacklog {
    <#
    .SYNOPSIS
    Gets work items in the sprint backlog
    #>
    [CmdletBinding()]
    param()
    
    try {
        $config = Get-AzureDevOpsConfig
        $teamArgs = if ($config.Team) { @('--team', $config.Team) } else { @() }
        
        # First get current sprint
        $sprint = Get-CurrentSprint
        if (-not $sprint) {
            return @()
        }
        
        # Then get work items for the sprint
        $iterationPath = $sprint.path -replace '^\\', ''
        $result = az boards query --wiql "SELECT [System.Id], [System.Title], [System.State], [System.WorkItemType], [System.AssignedTo] FROM WorkItems WHERE [System.IterationPath] = '$iterationPath' AND [System.TeamProject] = '$($config.Project)'" --organization $config.Organization --output json 2>$null
        
        if ($LASTEXITCODE -eq 0 -and $result) {
            $queryResult = $result | ConvertFrom-Json
            
            if ($queryResult.workItems.Count -eq 0) {
                Write-Host "No work items in sprint backlog" -ForegroundColor Yellow
                return @()
            }
            
            Write-Host ""
            Write-Host "Sprint Backlog ($($sprint.name)):" -ForegroundColor Cyan
            Write-Host "================================" -ForegroundColor Cyan
            Write-Host ""
            
            $queryResult.workItems | ForEach-Object {
                $wi = $_.fields
                $statusColor = switch ($wi.'System.State') {
                    'New' { 'White' }
                    'Active' { 'Yellow' }
                    'Resolved' { 'Green' }
                    'Closed' { 'DarkGreen' }
                    default { 'White' }
                }
                
                $typeIcon = switch ($wi.'System.WorkItemType') {
                    'Bug' { '🐛' }
                    'Task' { '📝' }
                    'User Story' { '📖' }
                    'Feature' { '⭐' }
                    default { '📋' }
                }
                
                Write-Host "$typeIcon $($wi.'System.Id'): " -NoNewline -ForegroundColor Green
                Write-Host $wi.'System.Title' -ForegroundColor White
                Write-Host "     State: " -NoNewline -ForegroundColor DarkGray
                Write-Host $wi.'System.State' -ForegroundColor $statusColor
                if ($wi.'System.AssignedTo') {
                    Write-Host "     Assigned: " -NoNewline -ForegroundColor DarkGray
                    Write-Host $wi.'System.AssignedTo'.displayName -ForegroundColor DarkGray
                }
                Write-Host ""
            }
            
            Write-AzureDevOpsLog "INFO" "Retrieved $($queryResult.workItems.Count) items from sprint backlog"
            return $queryResult.workItems
        }
        else {
            Write-Host "No work items found in sprint or error occurred" -ForegroundColor Yellow
            return @()
        }
    }
    catch {
        Write-AzureDevOpsLog "ERROR" "Failed to get sprint backlog: $($_.Exception.Message)"
        Write-Host "Error getting sprint backlog: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Get-SprintProgress {
    <#
    .SYNOPSIS
    Gets current sprint progress and statistics
    #>
    [CmdletBinding()]
    param(
        [string]$Team,
        [switch]$ShowBurndown,
        [switch]$ShowVelocity
    )
    
    try {
        # Get current iteration
        $config = Get-AzureDevOpsConfig
        $teamArgs = if ($Team) { @('--team', $Team) } elseif ($config.Team) { @('--team', $config.Team) } else { @() }
        
        $iterations = & az boards iteration team list --organization $config.Organization --project $config.Project @teamArgs --timeframe current --output json 2>$null | ConvertFrom-Json
        $currentIteration = $iterations | Where-Object { 
            $now = Get-Date
            $start = [DateTime]$_.attributes.startDate
            $end = [DateTime]$_.attributes.finishDate
            $now -ge $start -and $now -le $end
        } | Select-Object -First 1
        
        if ($currentIteration) {
            Write-Host "Current Sprint Progress:" -ForegroundColor Green
            Write-Host "  Sprint: $($currentIteration.name)" -ForegroundColor White
            Write-Host "  Period: $($currentIteration.attributes.startDate) to $($currentIteration.attributes.finishDate)" -ForegroundColor Gray
            
            # Get work items for the sprint  
            $sprintItems = Get-SprintBacklog
            if ($sprintItems -and $sprintItems.Count -gt 0) {
                $totalItems = $sprintItems.Count
                $completedItems = ($sprintItems | Where-Object { $_.fields.'System.State' -in @('Done', 'Closed', 'Resolved') }).Count
                $inProgressItems = ($sprintItems | Where-Object { $_.fields.'System.State' -in @('Active', 'In Progress') }).Count
                $newItems = ($sprintItems | Where-Object { $_.fields.'System.State' -eq 'New' }).Count
                
                $completionPercent = [math]::Round(($completedItems / $totalItems) * 100)
                
                Write-Host "  Progress: $completedItems/$totalItems ($completionPercent%)" -ForegroundColor Cyan
                Write-Host "    Completed: $completedItems" -ForegroundColor Green
                Write-Host "    In Progress: $inProgressItems" -ForegroundColor Yellow
                Write-Host "    New/Planned: $newItems" -ForegroundColor White
            }
            else {
                Write-Host "  No work items found in current sprint" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "No active sprint found" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Host "Error retrieving sprint progress: $($_.Exception.Message)" -ForegroundColor Red
        Write-AzureDevOpsLog "ERROR" "Error retrieving sprint progress: $($_.Exception.Message)"
        throw
    }
}

# Help Functions
function Show-AzureDevOpsHelp {
    Write-Host "Azure DevOps Integration" -ForegroundColor Cyan
    Write-Host "========================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Available Commands:" -ForegroundColor Yellow
    Write-Host "  help               - Show this help information"
    Write-Host "  template           - Generate config template for modules (copies to clipboard)"
    Write-Host "  workitems          - Work item operations (list, new, update, show)"
    Write-Host "  builds             - Build operations (list, show, recent)"
    Write-Host "  pipelines          - Pipeline operations (list, show)"
    Write-Host "  repos              - Repository operations (list)"
    Write-Host "  prs                - Pull request operations (list, new, show, approve)"
    Write-Host "  sprints            - Sprint operations (current, progress, backlog)"
    Write-Host "  config             - Show configuration status"
    Write-Host "  status             - Show Azure DevOps connection status"
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  azdevops <command> [<subcommand>] [parameters]"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  azdevops template -Organization 'microsoft' -Project 'Xbox.Apps'"
    Write-Host "  azdevops workitems list              - List your work items"
    Write-Host "  azdevops builds recent               - Show recent builds"
    Write-Host "  azdevops prs list                    - List pull requests"
}

function Show-WorkItemsHelp {
    Write-Host "Work Items Commands:" -ForegroundColor Yellow
    Write-Host "  list               - List work items (default: your items)"
    Write-Host "  new                - Create new work item (interactive)"
    Write-Host "  active             - Show active work items"
    Write-Host "  assigned           - Show work items assigned to someone"
    Write-Host "  show <ID>          - Show work item details"
    Write-Host "  update <ID>        - Update work item"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Top <n>           - Limit results (default: 10)"
    Write-Host "  -State <state>     - Filter by state"
    Write-Host "  -Type <type>       - Work item type (Bug, Task, User Story)"
    Write-Host "  -AssignedTo <user> - Assigned to user"
    Write-Host "  -Title <title>     - Work item title"
}

function Show-BuildsHelp {
    Write-Host "Builds Commands:" -ForegroundColor Yellow
    Write-Host "  list               - List builds"
    Write-Host "  recent             - Show recent builds (default)"
    Write-Host "  show <ID>          - Show build details"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Top <n>           - Limit results (default: 10)"
    Write-Host "  -Pipeline <name>   - Filter by pipeline name"
}

function Show-PipelinesHelp {
    Write-Host "Pipelines Commands:" -ForegroundColor Yellow
    Write-Host "  list               - List pipelines"
    Write-Host "  show <pipeline>    - Start pipeline"
}

function Show-ReposHelp {
    Write-Host "Repositories Commands:" -ForegroundColor Yellow
    Write-Host "  list               - List repositories"
}

function Show-PrsHelp {
    Write-Host "Pull Requests Commands:" -ForegroundColor Yellow
    Write-Host "  list               - List pull requests"
    Write-Host "  new                - Create new pull request (interactive)"
    Write-Host "  active             - Show active pull requests"
    Write-Host "  show <ID>          - Show PR details"
    Write-Host "  approve <ID>       - Approve pull request"
    Write-Host ""
    Write-Host "Parameters:" -ForegroundColor Yellow
    Write-Host "  -Top <n>           - Limit results (default: 10)"
    Write-Host "  -State <state>     - Filter by state"
    Write-Host "  -SourceBranch <b>  - Source branch for new PR"
    Write-Host "  -TargetBranch <b>  - Target branch for new PR"
}

function Show-SprintsHelp {
    Write-Host "Sprint Commands:" -ForegroundColor Yellow
    Write-Host "  current            - Show current sprint"
    Write-Host "  progress           - Show sprint progress with burndown"
    Write-Host "  backlog            - Show sprint backlog"
}

# Set up the hierarchical command alias
Set-Alias -Name azdevops -Value AzureDevOpsDriver -Scope Global -Description "Azure DevOps Driver"
#endregion

#region Utility Functions
function Write-AzureDevOpsLog {
    param([string]$Level = "INFO", [string]$Message)
    
    # Check if the main Cobra Framework logging function exists
    $cobraLogFunction = Get-Command -Name "Log-CobraActivity" -ErrorAction SilentlyContinue
    
    if ($cobraLogFunction) {
        # Use the main Cobra Framework logging
        Log-CobraActivity $Message
    }
    else {
        # Fallback to console output with color coding
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "INFO" { "Green" }
            default { "White" }
        }
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}
#endregion

#region Core Module Functions  
function Get-AzureDevOpsStatus {
    [CmdletBinding()]
    param()
    
    $config = . "$PSScriptRoot/config.ps1"
    Write-Host "AzureDevOps Module Status:" -ForegroundColor Cyan
    Write-Host "  Name: $($config.Name)" -ForegroundColor White
    Write-Host "  Description: $($config.Description)" -ForegroundColor White
    Write-Host "  Version: $($config.Version)" -ForegroundColor White
    Write-Host "  Type: Standalone" -ForegroundColor Green
}

function Get-AzureDevOpsConfigTemplate {
    <#
    .SYNOPSIS
    Generates AzureDevOps configuration template and copies it to clipboard
    .DESCRIPTION
    Creates a ready-to-use AzureDevOps configuration section that can be pasted into any module's config.ps1 file
    .EXAMPLE
    Get-AzureDevOpsConfigTemplate -Organization "microsoft" -Project "Xbox.Apps" -Repository "Xbox.Apps.GamingApp"
    .EXAMPLE
    azconfig -Organization "contoso" -Project "MyProject" -Minimal
    #>
    [CmdletBinding()]
    param(
        [string]$Organization = "YourOrgName",
        [string]$Project = "YourProjectName", 
        [string]$Repository = "YourRepoName",
        [string]$Team = "",
        [string]$DefaultBranch = "main",
        [switch]$Minimal,
        [switch]$NoClipboard
    )
    
    if ($Minimal) {
        $template = @"
    # AzureDevOps Configuration
    AzureDevOps = @{
        Organization = "$Organization"
        Project      = "$Project"
    }
"@
    }
    else {
        $teamSection = if ($Team) { "`n        Team         = `"$Team`"" } else { "" }
        
        $template = @"
    # AzureDevOps Configuration  
    AzureDevOps = @{
        Organization  = "$Organization"
        Project       = "$Project"
        Repository    = "$Repository"$teamSection
        DefaultBranch = "$DefaultBranch"
        
        Settings      = @{
            DefaultWorkItemType = "Task"
            ActiveStates       = @("New", "Active", "In Progress")
            CompletedStates    = @("Resolved", "Closed")
            
            PullRequest        = @{
                DefaultTargetBranch = "$DefaultBranch"
                AutoComplete        = `$false
                DeleteSourceBranch  = `$true
                RequireWorkItemLink = `$true
            }
        }
    }
"@
    }
    
    if (-not $NoClipboard) {
        try {
            $template | Set-Clipboard
            Write-Host "The config template has been copied to your clipboard." -ForegroundColor Green
        }
        catch {
            Write-Host "Could not copy to clipboard. Please copy the template manually:" -ForegroundColor Yellow
            Write-Host $template -ForegroundColor Gray
        }
    }

    return $template
}

function Test-AzureDevOpsConfiguration {
    [CmdletBinding()]
    param()
    
    $config = . "$PSScriptRoot/config.ps1"
    
    Write-Host "Testing AzureDevOps configuration..." -ForegroundColor Yellow
    
    # Validate required configuration
    $requiredKeys = @('Name', 'Description', 'Version', 'ModuleType')
    $isValid = $true
    
    foreach ($key in $requiredKeys) {
        if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
            Write-Host "  [ERROR] Missing or empty: $key" -ForegroundColor Red
            $isValid = $false
        }
        else {
            Write-Host "  OK - $key`: $($config[$key])" -ForegroundColor Green
        }
    }
    
    if ($isValid) {
        Write-Host "OK - AzureDevOps configuration is valid" -ForegroundColor Green
    }
    else {
        Write-Host "[ERROR] AzureDevOps configuration has errors" -ForegroundColor Red
    }
    
    return $isValid
}

# Create only the main hierarchical interface alias
Set-Alias -Name azdevops -Value AzureDevOpsDriver -Scope Global -Description "Azure DevOps Driver"
#endregion

# Export module functions and aliases
# Export only the hierarchical interface - no direct function access
Export-ModuleMember -Function @(
    'Initialize-AzureDevOpsModule',
    'Get-AzureDevOpsStatus',
    'Test-AzureDevOpsConfiguration',
    'Show-AzureDevOpsHelp',
    'Get-AzureDevOpsConfig',
    'Test-AzureDevOpsConfig',
    'Get-MyWorkItems',
    'New-WorkItem',
    'AzureDevOpsDriver',
    'Write-AzureDevOpsLog',
    'Get-BuildStatus',
    'Start-BuildPipeline',
    'Get-Pipelines',
    'Get-Repositories',
    'Get-WorkItemDetails',
    'Update-WorkItem',
    'Get-BuildDetails',
    'Get-PullRequests',
    'New-PullRequest',
    'Get-PullRequestDetails',
    'Approve-PullRequest',
    'Get-CurrentSprint',
    'Get-SprintBacklog',
    'Get-SprintProgress',
    'Get-AzureDevOpsConfigTemplate'
) -Alias @('azdevops')
