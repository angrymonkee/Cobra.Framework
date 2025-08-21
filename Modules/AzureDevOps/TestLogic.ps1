# AzureDevOps Module Test Logic
# Comprehensive testing of all AzureDevOps module functionality
param(
    [switch]$SkipAzureCliTests,
    [switch]$MockMode,
    [string]$TestOrganization = "testorg",
    [string]$TestProject = "testproject",
    [string]$TestRepository = "testrepo"
)

# Test Results Tracking
$script:TestResults = @{
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [bool]$Skipped = $false
    )
    
    if ($Skipped) {
        Write-Host "⏭️  SKIP: $TestName" -ForegroundColor Yellow
        $script:TestResults.Skipped++
    }
    elseif ($Passed) {
        Write-Host "✅ PASS: $TestName" -ForegroundColor Green
        $script:TestResults.Passed++
    }
    else {
        Write-Host "❌ FAIL: $TestName" -ForegroundColor Red
        if ($Details) {
            Write-Host "   Details: $Details" -ForegroundColor Gray
        }
        $script:TestResults.Failed++
    }
    
    $script:TestResults.Details += @{
        Test = $TestName
        Passed = $Passed
        Skipped = $Skipped
        Details = $Details
        Timestamp = Get-Date
    }
}

function Test-ModuleImport {
    Write-Host "`n=== Testing Module Import ===" -ForegroundColor Cyan
    
    try {
        # Force reload the module
        Import-Module "$PSScriptRoot\AzureDevOps.psm1" -Force
        Write-TestResult "Module Import" $true
        
        # Test alias exists
        $aliasExists = Get-Alias -Name azdevops -ErrorAction SilentlyContinue
        Write-TestResult "azdevops Alias" ($null -ne $aliasExists)
        
        # Test main functions exist
        $functions = @(
            'AzureDevOpsDriver',
            'Show-AzureDevOpsHelp',
            'Get-AzureDevOpsConfigTemplate',
            'Get-AzureDevOpsConfig',
            'Test-AzureDevOpsConfig'
        )
        
        foreach ($func in $functions) {
            $funcExists = Get-Command -Name $func -ErrorAction SilentlyContinue
            Write-TestResult "Function: $func" ($null -ne $funcExists)
        }
    }
    catch {
        Write-TestResult "Module Import" $false $_.Exception.Message
    }
}

function Test-HelpSystem {
    Write-Host "`n=== Testing Help System ===" -ForegroundColor Cyan
    
    try {
        # Test help command
        $helpOutput = azdevops help 2>&1
        $helpWorked = ($helpOutput -join "`n") -match "Azure DevOps Integration"
        Write-TestResult "azdevops help" $helpWorked
        
        # Test help shows required commands
        $requiredCommands = @("help", "template", "workitems", "builds", "pipelines", "repos", "prs", "sprints", "config", "status")
        $helpText = $helpOutput -join "`n"
        foreach ($cmd in $requiredCommands) {
            $cmdInHelp = $helpText -match $cmd
            Write-TestResult "Help shows: $cmd" $cmdInHelp
        }
        
        # Test direct help function
        $directHelp = Show-AzureDevOpsHelp 2>&1
        $directHelpText = $directHelp -join "`n"
        $directHelpWorked = $directHelpText -match "Azure DevOps Integration"
        Write-TestResult "Show-AzureDevOpsHelp function" $directHelpWorked
    }
    catch {
        Write-TestResult "Help System" $false $_.Exception.Message
    }
}

function Test-TemplateGeneration {
    Write-Host "`n=== Testing Template Generation ===" -ForegroundColor Cyan
    
    try {
        # Test basic template generation
        $template = azdevops template -Organization $TestOrganization -Project $TestProject -Repository $TestRepository -NoClipboard 2>&1
        $templateWorked = $template -match "AzureDevOps = @{"
        Write-TestResult "Basic Template Generation" $templateWorked
        
        # Test minimal template
        $minimalTemplate = azdevops template -Minimal -NoClipboard 2>&1
        $minimalWorked = $minimalTemplate -match "AzureDevOps = @{" -and $minimalTemplate -notmatch "Settings"
        Write-TestResult "Minimal Template Generation" $minimalWorked
        
        # Test template with all parameters
        $fullTemplate = azdevops template -Organization $TestOrganization -Project $TestProject -Repository $TestRepository -Team "TestTeam" -DefaultBranch "main" -NoClipboard 2>&1
        $fullWorked = $fullTemplate -match $TestOrganization -and $fullTemplate -match $TestProject -and $fullTemplate -match $TestRepository -and $fullTemplate -match "TestTeam"
        Write-TestResult "Full Template with Parameters" $fullWorked
        
        # Test direct function call
        $directTemplate = Get-AzureDevOpsConfigTemplate -Organization $TestOrganization -Project $TestProject -NoClipboard
        $directWorked = $directTemplate -match "AzureDevOps = @{"
        Write-TestResult "Direct Template Function Call" $directWorked
        
        # Test clipboard functionality (if not in mock mode)
        if (-not $MockMode) {
            try {
                azdevops template -Organization $TestOrganization -Project $TestProject 2>&1 | Out-Null
                $clipboardContent = Get-Clipboard -ErrorAction SilentlyContinue
                $clipboardWorked = $clipboardContent -match "AzureDevOps = @{"
                Write-TestResult "Template Clipboard Integration" $clipboardWorked
            }
            catch {
                Write-TestResult "Template Clipboard Integration" $false "Clipboard not available"
            }
        }
        else {
            Write-TestResult "Template Clipboard Integration" $false "" $true
        }
    }
    catch {
        Write-TestResult "Template Generation" $false $_.Exception.Message
    }
}

function Test-ConfigurationHandling {
    Write-Host "`n=== Testing Configuration Handling ===" -ForegroundColor Cyan
    
    try {
        # Test config detection in non-configured directory
        Push-Location $env:TEMP
        
        $configStatus = azdevops status 2>&1
        $configStatusText = $configStatus -join "`n"
        $noConfigDetected = $configStatusText -match "does not support Azure DevOps integration"
        Write-TestResult "No Config Detection" $noConfigDetected
        
        $configTest = azdevops config 2>&1
        $configTestText = $configTest -join "`n"
        $configTestWorked = $configTestText -match "does not support Azure DevOps integration"
        Write-TestResult "Config Test Command" $configTestWorked
        
        Pop-Location
        
        # Test direct config functions
        $directConfig = Get-AzureDevOpsConfig -ErrorAction SilentlyContinue
        $directConfigWorked = $null -eq $directConfig  # Should be null in non-configured context
        Write-TestResult "Direct Get-AzureDevOpsConfig" $directConfigWorked
    }
    catch {
        Write-TestResult "Configuration Handling" $false $_.Exception.Message
    }
}

function Test-CommandRouting {
    Write-Host "`n=== Testing Command Routing ===" -ForegroundColor Cyan
    
    $commands = @{
        "help" = "Azure DevOps Integration"
        "template" = "copied to your clipboard"
        "status" = "does not support Azure DevOps integration|Error:"
        "config" = "does not support Azure DevOps integration|Error:"
    }
    
    foreach ($cmd in $commands.Keys) {
        try {
            $output = azdevops $cmd 2>&1
            $outputText = $output -join "`n"
            $pattern = $commands[$cmd]
            $matched = $outputText -match $pattern
            Write-TestResult "Command Routing: $cmd" $matched
        }
        catch {
            Write-TestResult "Command Routing: $cmd" $false $_.Exception.Message
        }
    }
    
    # Test invalid command
    try {
        $invalidOutput = azdevops invalidcommand 2>&1
        $invalidOutputText = $invalidOutput -join "`n"
        $invalidHandled = $invalidOutputText -match "Error|Invalid|not recognized"
        Write-TestResult "Invalid Command Handling" $invalidHandled
    }
    catch {
        Write-TestResult "Invalid Command Handling" $true "Exception thrown as expected"
    }
}

function Test-AzureDevOpsCommands {
    Write-Host "`n=== Testing Azure DevOps Commands (Mock Mode) ===" -ForegroundColor Cyan
    
    if ($SkipAzureCliTests) {
        Write-TestResult "Azure CLI Commands" $false "" $true
        return
    }
    
    # Test Azure CLI availability
    try {
        $azVersion = az version 2>&1
        $azAvailable = $azVersion -match "azure-cli"
        Write-TestResult "Azure CLI Available" $azAvailable
        
        if (-not $azAvailable) {
            Write-Host "   Skipping Azure DevOps command tests - Azure CLI not available" -ForegroundColor Yellow
            return
        }
    }
    catch {
        Write-TestResult "Azure CLI Available" $false "Azure CLI not installed"
        return
    }
    
    # Test commands that would require actual Azure DevOps access
    $azureCommands = @("workitems", "builds", "pipelines", "repos", "prs", "sprints")
    
    foreach ($cmd in $azureCommands) {
        try {
            # These will fail due to no config, but we test if the command routing works
            $output = azdevops $cmd 2>&1
            $outputText = $output -join "`n"
            $routingWorked = $outputText -match "does not support Azure DevOps integration|Error:"
            Write-TestResult "Azure Command Routing: $cmd" $routingWorked
        }
        catch {
            Write-TestResult "Azure Command Routing: $cmd" $false $_.Exception.Message
        }
    }
}

function Test-ErrorHandling {
    Write-Host "`n=== Testing Error Handling ===" -ForegroundColor Cyan
    
    try {
        # Test with invalid parameters
        $invalidTemplate = azdevops template -Organization "" -Project "" 2>&1
        $invalidTemplateText = $invalidTemplate -join "`n"
        $errorHandled = $invalidTemplateText -match "copied to your clipboard"  # Should still work with empty params
        Write-TestResult "Empty Parameter Handling" $errorHandled
        
        # Test command with missing subcommand where required
        $missingSubcommand = azdevops workitems 2>&1
        $missingSubcommandText = $missingSubcommand -join "`n"
        $subcommandHandled = $missingSubcommandText -match "Error:|does not support"
        Write-TestResult "Missing Subcommand Handling" $subcommandHandled
        
        # Test non-existent command
        $badCommand = azdevops nonexistentcommand 2>&1
        $badCommandText = $badCommand -join "`n"
        $badCommandHandled = $badCommandText -match "Error|Invalid"
        Write-TestResult "Non-existent Command Handling" $badCommandHandled
    }
    catch {
        Write-TestResult "Error Handling" $false $_.Exception.Message
    }
}

function Test-ParameterValidation {
    Write-Host "`n=== Testing Parameter Validation ===" -ForegroundColor Cyan
    
    try {
        # Test template with various parameter combinations
        $params = @{
            "Valid Org/Project" = @{Org="microsoft"; Project="testproject"; Expected=$true}
            "Empty Org" = @{Org=""; Project="testproject"; Expected=$true}  # Should still work
            "Special Characters" = @{Org="test-org"; Project="test.project"; Expected=$true}
        }
        
        foreach ($testCase in $params.Keys) {
            $testParams = $params[$testCase]
            $result = azdevops template -Organization $testParams.Org -Project $testParams.Project -NoClipboard 2>&1
            $worked = $result -match "AzureDevOps = @{"
            Write-TestResult "Parameter Test: $testCase" ($worked -eq $testParams.Expected)
        }
    }
    catch {
        Write-TestResult "Parameter Validation" $false $_.Exception.Message
    }
}

function Show-TestSummary {
    Write-Host "`n" + "="*50 -ForegroundColor Cyan
    Write-Host "TEST SUMMARY" -ForegroundColor Cyan
    Write-Host "="*50 -ForegroundColor Cyan
    
    $total = $script:TestResults.Passed + $script:TestResults.Failed + $script:TestResults.Skipped
    
    Write-Host "Total Tests: $total" -ForegroundColor White
    Write-Host "Passed: $($script:TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($script:TestResults.Failed)" -ForegroundColor Red
    Write-Host "Skipped: $($script:TestResults.Skipped)" -ForegroundColor Yellow
    
    if ($script:TestResults.Failed -gt 0) {
        Write-Host "`nFAILED TESTS:" -ForegroundColor Red
        $failedTests = $script:TestResults.Details | Where-Object { -not $_.Passed -and -not $_.Skipped }
        foreach ($test in $failedTests) {
            Write-Host "  - $($test.Test): $($test.Details)" -ForegroundColor Red
        }
    }
    
    $passRate = if ($total -gt 0) { [math]::Round(($script:TestResults.Passed / $total) * 100, 1) } else { 0 }
    Write-Host "`nPass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })
    
    # Overall result
    if ($script:TestResults.Failed -eq 0 -and $script:TestResults.Passed -gt 0) {
        Write-Host "`n🎉 ALL TESTS PASSED!" -ForegroundColor Green
        return $true
    }
    elseif ($script:TestResults.Failed -gt 0) {
        Write-Host "`n❌ SOME TESTS FAILED" -ForegroundColor Red
        return $false
    }
    else {
        Write-Host "`n⚠️  NO TESTS RAN" -ForegroundColor Yellow
        return $false
    }
}

# Main Test Execution
Write-Host "AzureDevOps Module Comprehensive Test Suite" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "Start Time: $(Get-Date)" -ForegroundColor Gray
Write-Host "Mock Mode: $MockMode" -ForegroundColor Gray
Write-Host "Skip Azure CLI Tests: $SkipAzureCliTests" -ForegroundColor Gray
Write-Host ""

# Run all test suites
Test-ModuleImport
Test-HelpSystem
Test-TemplateGeneration
Test-ConfigurationHandling
Test-CommandRouting
Test-AzureDevOpsCommands
Test-ErrorHandling
Test-ParameterValidation

# Show final results
$success = Show-TestSummary

Write-Host "`nEnd Time: $(Get-Date)" -ForegroundColor Gray

# Export results for CI/CD or further analysis
$exportPath = Join-Path $PSScriptRoot "TestResults_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$script:TestResults | ConvertTo-Json -Depth 3 | Out-File $exportPath
Write-Host "Test results exported to: $exportPath" -ForegroundColor Gray

# Return exit code for automation
if ($success) {
    exit 0
} else {
    exit 1
}
