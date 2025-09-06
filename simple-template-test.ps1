# Simple test for module template functions
function Get-ModuleTemplates {
    [CmdletBinding()]
    param()
    
    $moduleTemplates = @()
    $modulesPath = "D:\Code\Cobra.Framework\Modules"
    
    if (Test-Path $modulesPath) {
        try {
            $modules = Get-ChildItem -Path $modulesPath -Directory -ErrorAction SilentlyContinue
            
            foreach ($module in $modules) {
                $templatePath = Join-Path $module.FullName "templates"
                
                if (Test-Path $templatePath) {
                    $templates = Get-ChildItem "$templatePath\*" -Include "*.ps1", "*.txt", "*.md", "*.json" -ErrorAction SilentlyContinue
                    
                    foreach ($template in $templates) {
                        $moduleTemplates += [PSCustomObject]@{
                            Name        = "$($module.Name).$($template.BaseName)"
                            Type        = "module-template"
                            Description = "Template from $($module.Name) module"
                            Path        = $template.FullName
                            Author      = "Module: $($module.Name)"
                            Module      = $module.Name
                            Created     = $template.CreationTime
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Error scanning module directories: $($_.Exception.Message)"
        }
    }
    
    return $moduleTemplates
}

# Test the function
Write-Host "Testing Get-ModuleTemplates..." -ForegroundColor Green
$templates = Get-ModuleTemplates
Write-Host "Found $($templates.Count) module templates:" -ForegroundColor Cyan

$templates | ForEach-Object {
    Write-Host "  - $($_.Name) ($($_.Module))" -ForegroundColor Yellow
}
