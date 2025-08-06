$global:jobManagementScriptLoaded = $true

# Dependencies:
# Load the core script if it hasn't been loaded yet
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

Log-CobraActivity "Loading job management scripts..."

# Global store for registered jobs
$global:CobraJobs = @{
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

# Example usage:
# Register-CobraJob -name "DailyBackup" -type "scheduled" -action { Write-Host "Running backup..." } -schedule "02:00"
# Register-CobraJob -name "OnFileChange" -type "event" -action { Write-Host "File changed!" } -eventName "FileChanged"
# Start-CobraJob -name "DailyBackup"
# List-CobraJobs
# Remove-CobraJob -name "DailyBackup"


# Function to register a new job
function Register-CobraJob {
    param (
        [string]$name,
        [string]$type, # manual, scheduled, event
        [scriptblock]$action,
        [string]$schedule = $null, # Cron-like schedule for scheduled jobs
        [string]$eventName = $null # Event name for event-driven jobs
    )

    if ($global:CobraJobs.ContainsKey($name)) {
        Write-Host "Job '$name' already exists." -ForegroundColor Yellow
        return
    }

    $job = @{
        Name      = $name
        Type      = $type
        Action    = $action
        Schedule  = $schedule
        EventName = $eventName
    }

    $global:CobraJobs[$name] = $job
    Write-Host "Registered job: $name" -ForegroundColor Green

    # Schedule or register event-driven jobs
    if ($type -eq "scheduled" -and $schedule) {
        Register-ScheduledJob -Name $name -ScriptBlock $action -Trigger (New-JobTrigger -Daily -At $schedule)
        Write-Host "Scheduled job: $name at $schedule" -ForegroundColor Green
    }
    elseif ($type -eq "event" -and $eventName) {
        Register-EngineEvent -SourceIdentifier $eventName -Action $action
        Write-Host "Registered event-driven job: $name for event '$eventName'" -ForegroundColor Green
    }
}

# Function to execute a job manually
function Start-CobraJob {
    param ([string]$name)

    if (-not $global:CobraJobs.ContainsKey($name)) {
        Write-Host "Job '$name' not found." -ForegroundColor Red
        return
    }

    $job = $global:CobraJobs[$name]
    if ($job.Type -eq "manual") {
        Start-Job -ScriptBlock $job.Action
        Write-Host "Started manual job: $name" -ForegroundColor Green
    }
    else {
        Write-Host "Job '$name' is not a manual job." -ForegroundColor Yellow
    }
}

# Function to list all registered jobs
function List-CobraJobs {
    Write-Host "Registered Jobs:" -ForegroundColor Cyan
    Get-ScheduledJob
    # foreach ($job in $global:CobraJobs.GetEnumerator()) {
    #     Write-Host "Name: $($job.Key), Type: $($job.Value.Type), Schedule: $($job.Value.Schedule), Event: $($job.Value.EventName)"
    # }
}

# Function to remove a job
function Remove-CobraJob {
    param ([string]$name)

    if ($global:CobraJobs.ContainsKey($name)) {
        $global:CobraJobs.Remove($name)
        Unregister-ScheduledJob -Name $name -ErrorAction SilentlyContinue
        Unregister-Event -SourceIdentifier $name -ErrorAction SilentlyContinue
        Write-Host "Removed job: $name" -ForegroundColor Green
    }
    else {
        Write-Host "Job '$name' not found." -ForegroundColor Red
    }
}

# ================== Job Management Helper Functions ==================

# Function to create a new scheduled job trigger
function New-CobraJobTrigger {
    param (
        [string]$schedule
    )

    try {
        # Parse the schedule (e.g., "02:00" for daily at 2 AM)
        $timeParts = $schedule -split ":"
        $hour = [int]$timeParts[0]
        $minute = [int]$timeParts[1]

        # Create a daily job trigger
        return New-JobTrigger -Daily -At ([datetime]::Today.AddHours($hour).AddMinutes($minute))
    }
    catch {
        Write-Host "Invalid schedule format: $schedule. Use HH:mm format." -ForegroundColor Red
        return $null
    }
}

# Function to trigger an event-driven job manually
function Trigger-CobraEvent {
    param (
        [string]$eventName
    )

    try {
        if (-not $global:CobraJobs.Values | Where-Object { $_.EventName -eq $eventName }) {
            Write-Host "No job registered for event: $eventName" -ForegroundColor Red
            return
        }

        # Trigger the event
        New-Event -SourceIdentifier $eventName
        Write-Host "Triggered event: $eventName" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to trigger event: $eventName. Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Function to execute all scheduled jobs immediately (for testing purposes)
function Execute-AllScheduledJobs {
    foreach ($job in $global:CobraJobs.Values | Where-Object { $_.Type -eq "scheduled" }) {
        Write-Host "Executing scheduled job: $($job.Name)" -ForegroundColor Cyan
        & $job.Action
    }
}

# Function to clean up all registered jobs (use with caution)
function Cleanup-CobraJobs {
    Write-Host "Cleaning up all registered jobs..." -ForegroundColor Yellow

    # Remove all scheduled jobs
    Get-ScheduledJob | ForEach-Object { Unregister-ScheduledJob -Name $_.Name -Force }

    # Remove all event-driven jobs
    Get-EventSubscriber | ForEach-Object { Unregister-Event -SourceIdentifier $_.SourceIdentifier -Force }

    # Clear the global job store
    $global:CobraJobs.Clear()
    Write-Host "All jobs have been cleaned up." -ForegroundColor Green
}
