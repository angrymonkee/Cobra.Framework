# Description: Azure DevOps authentication function template
# Author: Cobra Framework
# Created: 2025-08-07 00:00:00
# Type: Function Template

function Confirm-{ModuleName}Repo {
    [CmdletBinding()]
    param()
    
    Write-Host "Authenticating {ModuleName} repository..." -ForegroundColor Green
    
    try {
        # Check if Azure CLI is installed and authenticated
        $azResult = az account show 2>$null
        if (-not $azResult) {
            Write-Host "Azure CLI not authenticated. Running 'az login'..." -ForegroundColor Yellow
            az login
        }
        
        # Verify Azure DevOps extension
        $extensions = az extension list --query "[?name=='azure-devops'].name" -o tsv
        if (-not $extensions) {
            Write-Host "Installing Azure DevOps CLI extension..." -ForegroundColor Yellow
            az extension add --name azure-devops
        }
        
        # Set default organization and project if configured
        if ($global:CobraConfig.AzureDevOpsOrganization) {
            az devops configure --defaults organization=$($global:CobraConfig.AzureDevOpsOrganization)
        }
        
        Log-CobraActivity "Authenticated {ModuleName} repository"
        Write-Host "✓ {ModuleName} repository authentication complete!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error authenticating {ModuleName}: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error authenticating {ModuleName}: $($_.Exception.Message)"
        throw
    }
}
