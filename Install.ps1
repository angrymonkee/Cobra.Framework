# Path to the CobraProfile.ps1 file
$currentDir = Get-Location
$cobraProfilePath = "$currentDir\CobraProfile.ps1"

# Get the current user's PowerShell profile path
$userProfilePath = $PROFILE

# Check if the CobraProfile.ps1 reference already exists in the profile
if (Test-Path $userProfilePath) {
    $profileContent = Get-Content $userProfilePath
    if ($profileContent -contains ". `"$cobraProfilePath`"") {
        Write-Host "CobraProfile.ps1 is already referenced in your PowerShell profile." -ForegroundColor Yellow
        return
    }
}

# Create the profile file if it doesn't exist
if (-not (Test-Path $userProfilePath)) {
    New-Item -ItemType File -Path $userProfilePath -Force | Out-Null
    Write-Host "Created new PowerShell profile at $userProfilePath" -ForegroundColor Green
}

# Append the dot reference to the user's PowerShell profile
Add-Content -Path $userProfilePath -Value ". `"$cobraProfilePath`""
Write-Host "CobraProfile.ps1 has been added to your PowerShell profile." -ForegroundColor Green
