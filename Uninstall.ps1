# Path to the CobraProfile.ps1 file
$currentDir = Get-Location
$cobraProfilePath = "$currentDir\CobraProfile.ps1"

# Get the current user's PowerShell profile path
$userProfilePath = $PROFILE

# Check if the user's PowerShell profile exists
if (Test-Path $userProfilePath) {
    $profileContent = Get-Content $userProfilePath

    # Remove the CobraProfile.ps1 reference if it exists
    $updatedContent = $profileContent | Where-Object { $_ -notmatch [regex]::Escape(". `"$cobraProfilePath`"") }
    if ($updatedContent.Count -ne $profileContent.Count) {
        $updatedContent | Set-Content -Path $userProfilePath
        Write-Host "CobraProfile.ps1 reference has been removed from your PowerShell profile." -ForegroundColor Green
    }
    else {
        Write-Host "CobraProfile.ps1 reference was not found in your PowerShell profile." -ForegroundColor Yellow
    }
}
else {
    Write-Host "PowerShell profile not found. No changes made." -ForegroundColor Red
}
