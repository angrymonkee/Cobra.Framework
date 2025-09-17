# Test loading original TemplatesManagement.ps1

# Load shared test configuration
. "$PSScriptRoot\TestConfig.ps1"

$global:CobraConfig = @{ 
    CobraRoot = $global:TestCobraPath 
}
$global:coreScriptLoaded = $false

function Log-CobraActivity { 
    param([string]$Message)
    Write-Host "[LOG] $Message" -ForegroundColor DarkGray
}

try { 
    . "$PSScriptRoot\TemplatesManagement.ps1"
    Write-Host "Original file loads OK" -ForegroundColor Green 
    
    # Test the Get-CobraTemplates function exists
    if (Get-Command Get-CobraTemplates -ErrorAction SilentlyContinue) {
        Write-Host "Get-CobraTemplates function exists" -ForegroundColor Green
    }
    else {
        Write-Host "Get-CobraTemplates function NOT found" -ForegroundColor Red
    }
} 
catch { 
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red 
}
