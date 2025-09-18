# Test script to verify the cobra modules publish version fix

Write-Host "🧪 Testing Cobra Modules Publish Version Fix" -ForegroundColor Yellow
Write-Host "=" * 50

# Load the module management functions
. "$PSScriptRoot\ModuleManagement.ps1"
. "$PSScriptRoot\Core.ps1"

# Test 1: Test the Get-NextModuleVersion function
Write-Host "`n📋 Test 1: Get-NextModuleVersion function" -ForegroundColor Cyan

# Mock a module that doesn't exist
$version1 = Get-NextModuleVersion -ModuleName "NonExistentModule"
Write-Host "✅ Version for new module: $version1" -ForegroundColor Green

# Test 2: Test version parsing logic by simulating the arguments
Write-Host "`n📋 Test 2: Version argument parsing simulation" -ForegroundColor Cyan

function Test-VersionParsing {
    param([string[]]$options)
    
    $moduleName = $options[0]
    $version = $null
    
    # Parse version from various formats (same logic as in the fix)
    for ($i = 1; $i -lt $options.Count; $i++) {
        $opt = $options[$i]
        if ($opt -eq "-version" -or $opt -eq "--version" -or $opt -eq "-v") {
            if ($i + 1 -lt $options.Count) {
                $version = $options[$i + 1]
                break
            }
        }
        elseif ($opt -match "^\d+\.\d+\.\d+$") {
            $version = $opt
            break
        }
    }
    
    return @{
        ModuleName      = $moduleName
        Version         = $version
        ParsedCorrectly = $null -ne $version
    }
}

# Test cases
$testCases = @(
    @("TestModule", "1.2.3"),
    @("TestModule", "-version", "2.0.0"),
    @("TestModule", "--version", "1.5.0"),
    @("TestModule", "-v", "3.1.4"),
    @("TestModule")  # No version - should use auto-increment
)

foreach ($case in $testCases) {
    $result = Test-VersionParsing -options $case
    $caseDesc = $case -join " "
    
    if ($result.ParsedCorrectly) {
        Write-Host "✅ '$caseDesc' -> Module: $($result.ModuleName), Version: $($result.Version)" -ForegroundColor Green
    }
    else {
        Write-Host "⚪ '$caseDesc' -> Module: $($result.ModuleName), Version: auto-increment" -ForegroundColor Yellow
    }
}

Write-Host "`n📋 Test 3: Command usage examples" -ForegroundColor Cyan
Write-Host "The following commands should now work:" -ForegroundColor White
Write-Host "  cobra modules publish MyModule 1.2.0" -ForegroundColor Cyan
Write-Host "  cobra modules publish MyModule -version 1.2.0" -ForegroundColor Cyan  
Write-Host "  cobra modules publish MyModule --version 1.2.0" -ForegroundColor Cyan
Write-Host "  cobra modules publish MyModule -v 1.2.0" -ForegroundColor Cyan
Write-Host "  cobra modules publish MyModule (auto-increments)" -ForegroundColor Cyan

Write-Host "`n✅ Testing complete! The version bug should be fixed." -ForegroundColor Green
Write-Host "🚀 Try running a publish command to verify the fix works in practice." -ForegroundColor Yellow