# Test script for the new Cobra Module Marketplace
# Run this to test Phase 1 functionality

# Load shared test configuration
. "$PSScriptRoot\TestConfig.ps1"

Write-Host "🚀 Testing Cobra Module Marketplace - Phase 1" -ForegroundColor Cyan
Write-Host ("=" * 60) -ForegroundColor DarkGray

# Load the system first
. "$PSScriptRoot\CobraProfile.ps1"

Write-Host ""
Write-Host "📋 Step 1: Initialize the marketplace" -ForegroundColor Yellow
Initialize-ModuleMarketplace -Force

Write-Host ""
Write-Host "📋 Step 2: Test enhanced module metadata creation" -ForegroundColor Yellow

# Create enhanced metadata for an existing module
$metadata = New-ModuleMetadata -ModuleName "Code" -Version "1.0.0" -Author "YourName" `
    -Description "Enhanced Code repository management module" `
    -Tags @("development", "git", "repository") `
    -Categories @("Development", "Utilities") `
    -Repository "https://github.com/yourusername/cobra.framework"

Write-Host "✅ Created metadata for Code module:" -ForegroundColor Green
Write-Host "   Name: $($metadata.Name)" -ForegroundColor White
Write-Host "   Version: $($metadata.Version)" -ForegroundColor White
Write-Host "   Tags: $($metadata.Tags -join ', ')" -ForegroundColor White

Write-Host ""
Write-Host "📋 Step 3: Publish a module to the marketplace" -ForegroundColor Yellow
$publishResult = Publish-CobraModule -ModuleName "Code" -Version "1.0.0" -Author "TestUser" `
    -Description "Enhanced Code repository management module with Git integration" `
    -Tags @("development", "git", "repository", "automation") `
    -Categories @("Development") `
    -ReleaseNotes "Initial marketplace release with enhanced functionality"

if ($publishResult) {
    Write-Host "✅ Successfully published Code module" -ForegroundColor Green
}
else {
    Write-Host "❌ Failed to publish Code module" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Step 4: Test marketplace search" -ForegroundColor Yellow
$searchResults = Search-Modules -SearchTerm "development"

if ($searchResults.Count -gt 0) {
    Write-Host "✅ Search found $($searchResults.Count) modules:" -ForegroundColor Green
    foreach ($result in $searchResults) {
        Write-Host "   - $($result.Name) v$($result.Version) by $($result.Author)" -ForegroundColor White
    }
}
else {
    Write-Host "❌ No modules found in search" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Step 5: Test module rating system" -ForegroundColor Yellow
$ratingResult = Set-ModuleRating -ModuleName "Code" -Rating 5 -Comment "Excellent module for development workflows!"

if ($ratingResult) {
    Write-Host "✅ Successfully rated the Code module" -ForegroundColor Green
}
else {
    Write-Host "❌ Failed to rate the Code module" -ForegroundColor Red
}

Write-Host ""
Write-Host "📋 Step 6: Test dependency resolution" -ForegroundColor Yellow
$dependencies = Resolve-ModuleDependencies -ModuleName "Code"

if ($dependencies.Count -gt 0) {
    Write-Host "✅ Dependency resolution found $($dependencies.Count) modules:" -ForegroundColor Green
    foreach ($dep in $dependencies) {
        Write-Host "   - $($dep.Name) v$($dep.Version)" -ForegroundColor White
    }
}
else {
    Write-Host "ℹ️  Code module has no dependencies" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "📋 Step 7: Display final marketplace status" -ForegroundColor Yellow
Get-ModuleRegistryInfo -Action "list"

Write-Host ""
Write-Host "🎉 Phase 1 testing complete!" -ForegroundColor Green
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Try: cobra modules registry list" -ForegroundColor Cyan
Write-Host "  2. Try: cobra modules search development" -ForegroundColor Cyan
Write-Host "  3. Try: cobra modules info Code" -ForegroundColor Cyan
Write-Host "  4. Try: cobra modules install Code" -ForegroundColor Cyan
