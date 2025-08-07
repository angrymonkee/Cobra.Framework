$global:cobraDashboardScriptLoaded = $true

# Dependencies:
# Load the core script if it hasn't been loaded yet
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

Log-CobraActivity "Loading Cobra dashboard scripts..."

# ================== Context-Aware Dashboard ==================

function Show-CobraDashboard {
    [CmdletBinding()]
    param(
        [switch]$Interactive
    )

    # Get current context information
    $currentLocation = Get-Location
    $currentConfig = $null
    if ($global:currentAppConfig) {
        $currentConfig = $global:currentAppConfig
    }
    $gitBranch = $null
    $gitStatus = $null
    $buildStatus = "Unknown"
    $testStatus = "Unknown"
    $lastBuildTime = $null
    $lastTestTime = $null
    
    # Try to get Git information
    try {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            $gitBranch = git rev-parse --abbrev-ref HEAD 2>$null
            $gitStatus = git status --porcelain 2>$null
        }
    }
    catch { 
        # Git not available or not in a git repo
    }
    
    # Try to get build/test status from logs
    try {
        $logPath = Join-Path $PSScriptRoot "CobraActivity.log"
        if (Test-Path $logPath) {
            $recentLogs = Get-Content $logPath -Tail 100
            $lastBuild = $recentLogs | Where-Object { $_ -match "BuildApp|Built.*successfully|Build.*failed" } | Select-Object -Last 1
            $lastTest = $recentLogs | Where-Object { $_ -match "TestApp|Test.*successfully|Test.*failed" } | Select-Object -Last 1
            
            if ($lastBuild) {
                $lastBuildTime = ($lastBuild -split " - ")[0]
                $buildStatus = if ($lastBuild -match "successfully|completed|Success") { "✅ Success" } else { "❌ Failed" }
            }
            
            if ($lastTest) {
                $lastTestTime = ($lastTest -split " - ")[0]
                $testStatus = if ($lastTest -match "successfully|passed|Success") { "✅ Success" } else { "❌ Failed" }
            }
        }
    }
    catch {
        # Log parsing failed
    }
    
    # Display the dashboard
    Write-Host "╔══════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                           🐍 COBRA CONTEXT DASHBOARD                         ║" -ForegroundColor Cyan
    Write-Host "╠══════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Cyan
    
    # Current Context Section
    Write-Host "║ 📍 Current Context                                                           ║" -ForegroundColor Yellow
    Write-Host "║   Location:   " -NoNewline -ForegroundColor White
    $locationText = $currentLocation.Path
    if ($locationText.Length -gt 60) { $locationText = "..." + $locationText.Substring($locationText.Length - 57) }
    Write-Host ("{0,-60}" -f $locationText) -NoNewline -ForegroundColor Gray
    Write-Host "   ║" -ForegroundColor Cyan
    
    if ($currentConfig) {
        Write-Host "║   Repository: " -NoNewline -ForegroundColor White
        Write-Host ("{0,-60}" -f $currentConfig.Name) -NoNewline -ForegroundColor Green
        Write-Host "   ║" -ForegroundColor Cyan
    }
    
    if ($gitBranch) {
        Write-Host "║   Git Branch: " -NoNewline -ForegroundColor White
        $branchColor = if ($gitBranch -eq "main" -or $gitBranch -eq "master") { "Green" } else { "Yellow" }
        Write-Host ("{0,-60}" -f $gitBranch) -NoNewline -ForegroundColor $branchColor
        Write-Host "   ║" -ForegroundColor Cyan
        
        $statusText = if ($gitStatus) { "📝 $($gitStatus.Count) changes" } else { "✅ Clean" }
        Write-Host "║   Git Status: " -NoNewline -ForegroundColor White
        Write-Host ("{0,-60}" -f $statusText) -NoNewline -ForegroundColor $(if ($gitStatus) { "Yellow" } else { "Green" })
        Write-Host "   ║" -ForegroundColor Cyan
    }
    
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    
    # Status Section
    Write-Host "║ 📊 Status                                                                    ║" -ForegroundColor Yellow
    Write-Host "║   Last Build: " -NoNewline -ForegroundColor White
    Write-Host ("{0,-23}" -f $buildStatus) -NoNewline -ForegroundColor $(if ($buildStatus -match "Success") { "Green" } else { "Red" })
    if ($lastBuildTime) {
        $timeOnly = ($lastBuildTime -split " ")[1]
        Write-Host (" ({0})" -f $timeOnly) -NoNewline -ForegroundColor Gray
        Write-Host ("{0,22}" -f " ") -NoNewline
    }
    else {
        Write-Host ("{0,32}" -f " ") -NoNewline
    }
    Write-Host "      ║" -ForegroundColor Cyan
    
    Write-Host "║   Last Test:  " -NoNewline -ForegroundColor White
    Write-Host ("{0,-23}" -f $testStatus) -NoNewline -ForegroundColor $(if ($testStatus -match "Success") { "Green" } else { "Red" })
    if ($lastTestTime) {
        $timeOnly = ($lastTestTime -split " ")[1]
        Write-Host (" ({0})" -f $timeOnly) -NoNewline -ForegroundColor Gray
        Write-Host ("{0,22}" -f " ") -NoNewline
    }
    else {
        Write-Host ("{0,32}" -f " ") -NoNewline
    }
    Write-Host "      ║" -ForegroundColor Cyan
    
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    
    # Quick Actions Section
    Write-Host "║ ⚡ Quick Actions                                                             ║" -ForegroundColor Yellow
    Write-Host "║   [B]uild    [T]est     [R]un      [P]R Prep   [A]uth     [S]etup            ║" -ForegroundColor White
    Write-Host "║   [I]nfo     [L]ogs     [M]odules  [G]it       [H]elp     [Q]uit             ║" -ForegroundColor White
    Write-Host "║                                                                              ║" -ForegroundColor Cyan
    
    # Recent Activity Section
    Write-Host "║ 📝 Recent Activity                                                           ║" -ForegroundColor Yellow
    try {
        $logPath = Join-Path $PSScriptRoot "CobraActivity.log"
        if (Test-Path $logPath) {
            $recentLogs = Get-Content $logPath -Tail 5
            foreach ($log in $recentLogs) {
                $logParts = $log -split " - ", 2
                if ($logParts.Count -eq 2) {
                    $time = $logParts[0]
                    $message = $logParts[1]
                    if ($message.Length -gt 62) { $message = $message.Substring(0, 60) + "..." }
                    
                    Write-Host "║   " -NoNewline -ForegroundColor Cyan
                    $timeOnly = ($time -split " ")[1]
                    Write-Host $timeOnly -NoNewline -ForegroundColor Gray
                    Write-Host " - " -NoNewline -ForegroundColor DarkGray
                    Write-Host ("{0,-62}" -f $message) -NoNewline -ForegroundColor White
                    Write-Host "  ║" -ForegroundColor Cyan
                }
            }
        }
        else {
            Write-Host "║   No recent activity                                                     ║" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "║   Unable to read activity log                                            ║" -ForegroundColor Red
    }
    
    Write-Host "╚══════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    if ($Interactive) {
        Write-Host ""
        Write-Host "Press any key for quick action, 'Enter' for command input, or 'Q' to quit: " -NoNewline -ForegroundColor Yellow
        
        while ($true) {
            $key = [System.Console]::ReadKey($true)
            
            switch ($key.Key) {
                'B' { 
                    Write-Host "B" -ForegroundColor Green
                    Write-Host "Building application..." -ForegroundColor Yellow
                    BuildApp
                    break
                }
                'T' { 
                    Write-Host "T" -ForegroundColor Green
                    Write-Host "Testing application..." -ForegroundColor Yellow
                    TestApp
                    break
                }
                'R' { 
                    Write-Host "R" -ForegroundColor Green
                    Write-Host "Running application..." -ForegroundColor Yellow
                    RunApp
                    break
                }
                'P' { 
                    Write-Host "P" -ForegroundColor Green
                    Write-Host "Preparing for PR..." -ForegroundColor Yellow
                    try { RunPullRequestPrep } catch { Write-Host "PR prep function not available" -ForegroundColor Red }
                    break
                }
                'A' { 
                    Write-Host "A" -ForegroundColor Green
                    Write-Host "Authenticating..." -ForegroundColor Yellow
                    AuthApp
                    break
                }
                'S' { 
                    Write-Host "S" -ForegroundColor Green
                    Write-Host "Setting up..." -ForegroundColor Yellow
                    SetupApp
                    break
                }
                'I' { 
                    Write-Host "I" -ForegroundColor Green
                    try { AppInfo } catch { Write-Host "App info not available" -ForegroundColor Red }
                    break
                }
                'L' { 
                    Write-Host "L" -ForegroundColor Green
                    Show-CobraLogs -Action view -Lines 10
                    break
                }
                'M' { 
                    Write-Host "M" -ForegroundColor Green
                    cobra modules
                    break
                }
                'G' { 
                    Write-Host "G" -ForegroundColor Green
                    Write-Host "Git status:" -ForegroundColor Yellow
                    if (Get-Command git -ErrorAction SilentlyContinue) {
                        git status
                    }
                    else {
                        Write-Host "Git not available" -ForegroundColor Red
                    }
                    break
                }
                'H' { 
                    Write-Host "H" -ForegroundColor Green
                    CobraHelp
                    break
                }
                'Q' { 
                    Write-Host "Q" -ForegroundColor Green
                    Write-Host "Exiting dashboard..." -ForegroundColor Yellow
                    return
                }
                'Enter' { 
                    Write-Host ""
                    Write-Host "Enter command: " -NoNewline -ForegroundColor Yellow
                    $command = Read-Host
                    if ($command) {
                        try {
                            Invoke-Expression $command
                        }
                        catch {
                            Write-Host "Error executing command: $($_.Exception.Message)" -ForegroundColor Red
                        }
                    }
                    Write-Host ""
                    Write-Host "Press any key for quick action or 'Q' to quit: " -NoNewline -ForegroundColor Yellow
                }
                default { 
                    Write-Host ""
                    Write-Host "Unknown key. Use [B]uild, [T]est, [R]un, [P]R, [A]uth, [S]etup, [I]nfo, [L]ogs, [M]odules, [G]it, [H]elp, [Q]uit" -ForegroundColor Red
                    Write-Host "Press any key for quick action or 'Q' to quit: " -NoNewline -ForegroundColor Yellow
                }
            }
        }
    }
}

function Show-CobraDashboardInteractive {
    Show-CobraDashboard -Interactive
}

# Create aliases for dashboard
Set-Alias -Name "dash" -Value "Show-CobraDashboard" -Scope Global -Description "Cobra Dashboard (non-interactive)"
Set-Alias -Name "dashi" -Value "Show-CobraDashboardInteractive" -Scope Global -Description "Cobra Dashboard (interactive)"
