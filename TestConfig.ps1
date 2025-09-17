# Shared Test Configuration for Cobra Framework
# This file contains common configuration values used across all test scripts

# Primary test configuration
$global:TestCobraPath = 'D:\Code\Cobra.Framework'

# Additional test configuration options
$global:TestConfig = @{
    CobraRoot = $global:TestCobraPath
    EnableVerboseLogging = $false
    TestOutputDirectory = Join-Path $global:TestCobraPath "TestOutput"
    CleanupAfterTests = $true
}

# Helper function for test logging
function Write-TestLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level = 'Info'
    )
    
    $colors = @{
        'Info' = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error' = 'Red'
    }
    
    $prefix = switch ($Level) {
        'Info' { "ℹ️" }
        'Success' { "✅" }
        'Warning' { "⚠️" }
        'Error' { "❌" }
    }
    
    Write-Host "$prefix $Message" -ForegroundColor $colors[$Level]
}

# Ensure test output directory exists if needed
if (-not (Test-Path $global:TestConfig.TestOutputDirectory)) {
    New-Item -Path $global:TestConfig.TestOutputDirectory -ItemType Directory -Force | Out-Null
}

Write-TestLog "Test configuration loaded - Cobra Root: $global:TestCobraPath" -Level 'Info'
