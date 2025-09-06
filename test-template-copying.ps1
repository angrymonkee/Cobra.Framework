# Test module template copying functionality
$global:CobraConfig = @{ 
    CobraRoot = 'D:\Code\Cobra.Framework' 
}
$global:coreScriptLoaded = $false

function Log-CobraActivity { 
    param([string]$Message)
    Write-Host "[LOG] $Message" -ForegroundColor DarkGray
}

try { 
    . "$PSScriptRoot\TemplatesManagement.ps1"
    Write-Host "Testing module template copying functionality..." -ForegroundColor Green 
    
    # Test module template copying
    Write-Host "`nTesting Copy-CobraTemplate with module template:" -ForegroundColor Cyan
    $result = Copy-CobraTemplate -TemplateName "Email.meeting-followup" -DestinationPath "." -Parameters @{
        ProjectName = "TestProject"
        MeetingDate = "2025-08-28"
    }
    
    if ($result) {
        Write-Host "Module template copy: SUCCESS" -ForegroundColor Green
        
        # Check if file was created
        if (Test-Path "meeting-followup.txt") {
            Write-Host "Output file created successfully" -ForegroundColor Green
            Write-Host "File contents:" -ForegroundColor Yellow
            Get-Content "meeting-followup.txt" | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
            
            # Clean up test file
            Remove-Item "meeting-followup.txt" -Force
            Write-Host "Test file cleaned up" -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "Module template copy: FAILED" -ForegroundColor Red
    }
    
    # Test invalid module template
    Write-Host "`nTesting Copy-CobraTemplate with invalid module template:" -ForegroundColor Cyan
    $result2 = Copy-CobraTemplate -TemplateName "NonExistent.template" -DestinationPath "."
    Write-Host "Invalid template test completed (should show error)" -ForegroundColor Gray
    
} 
catch { 
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red 
    Write-Host "Full exception:" -ForegroundColor Red
    Write-Host $_.Exception.ToString()
}
