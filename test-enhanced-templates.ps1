# Test enhanced Get-CobraTemplates with module template support

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
    Write-Host "Enhanced TemplatesManagement.ps1 loaded successfully" -ForegroundColor Green 
    
    # Test regular templates
    Write-Host "`nTesting regular templates:" -ForegroundColor Cyan
    $regularTemplates = Get-CobraTemplates
    Write-Host "Found $($regularTemplates.Count) regular templates"
    
    # Test module templates
    Write-Host "`nTesting module templates only:" -ForegroundColor Cyan  
    $moduleTemplates = Get-ModuleTemplates
    Write-Host "Found $($moduleTemplates.Count) module templates"
    $moduleTemplates | ForEach-Object {
        Write-Host "  - $($_.Name) ($($_.Type)) from $($_.Module)" -ForegroundColor Yellow
    }
    
    # Test combined templates
    Write-Host "`nTesting combined templates (IncludeModuleTemplates):" -ForegroundColor Cyan
    $combinedTemplates = Get-CobraTemplates -IncludeModuleTemplates
    Write-Host "Found $($combinedTemplates.Count) total templates"
    
    $moduleOnly = $combinedTemplates | Where-Object { $_.Module }
    Write-Host "Module templates in combined list: $($moduleOnly.Count)"
    $moduleOnly | ForEach-Object {
        Write-Host "  - $($_.Name) from $($_.Module)" -ForegroundColor Green
    }
    
} 
catch { 
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red 
}
