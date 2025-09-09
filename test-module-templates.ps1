# Test script for module templates functionality

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

# Load the templates management
. "$PSScriptRoot\TemplatesManagement.ps1"

Write-Host "Testing Get-ModuleTemplates function..." -ForegroundColor Green

# Check if modules directory exists and has templates
$modulesPath = Join-Path $PSScriptRoot "Modules"
Write-Host "Modules path: $modulesPath"

if (Test-Path $modulesPath) {
    $modules = Get-ChildItem $modulesPath -Directory
    Write-Host "Found modules: $($modules.Name -join ', ')"
    
    foreach ($module in $modules) {
        $templatesPath = Join-Path $module.FullName "templates"
        if (Test-Path $templatesPath) {
            Write-Host "Module $($module.Name) has templates:" -ForegroundColor Green
            $templateFiles = Get-ChildItem $templatesPath
            $templateFiles.Name | ForEach-Object { Write-Host "  - $_" }
        }
    }
}

Write-Host "Now testing Get-ModuleTemplates..." -ForegroundColor Cyan
try {
    $moduleTemplates = Get-ModuleTemplates
    Write-Host "Found $($moduleTemplates.Count) module templates"

    if ($moduleTemplates.Count -gt 0) {
        $moduleTemplates | ForEach-Object {
            Write-Host "Template: $($_.Name) | Type: $($_.Type) | Module: $($_.Module)"
        }
    }
}
catch {
    Write-Host "Error testing Get-ModuleTemplates: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Test completed." -ForegroundColor Green
