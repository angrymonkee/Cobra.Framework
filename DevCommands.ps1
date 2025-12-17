$global:devCommandsScriptLoaded = $true

# Dependencies:
# Load the core script if it hasn't been loaded yet
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

Log-CobraActivity "Loading development command scripts..."

function AuthApp {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.AuthMethod -ne "") {
            & $appConfig.AuthMethod
        }
        else {
            write-host "No auth method configured."
        }
    }
    finally {
        Set-Location $src
    }

    Log-CobraActivity "Executed AuthApp for $($appConfig.Name) repo"
}

function SetupApp {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.SetupMethod -ne "") {
            & $appConfig.SetupMethod
        }
        else {
            write-host "No setup method configured."
        }
    }
    finally {
        Set-Location $src
    }

    Log-CobraActivity "Executed SetupApp for $($appConfig.Name) repo"
}

enum buildType {
    Build
    BuildAll
    Rebuild
}

function BuildApp ([buildType] $buildType = [buildType]::Build) {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.BuildMethod -ne "") {
            & $appConfig.BuildMethod $buildType
        }
        else {
            write-host "No build method configured."
        }
    }
    finally {
        Set-Location $src
    }

    Log-CobraActivity "Executed BuildApp for $($appConfig.Name) repo with build type: $buildType"
}

function TestApp {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.TestMethod -ne "") {
            & $appConfig.TestMethod
        }
        else {
            write-host "No test method configured."
        }
    }
    finally {
        Set-Location $src
    }

    Log-CobraActivity "Executed TestApp for $($appConfig.Name) repo"
}

function RunApp { 
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.RunMethod -ne "") {
            & $appConfig.RunMethod
        }
        else {
            write-host "No run method configured."
        }
    }
    finally {
        Set-Location $src
    }

    Log-CobraActivity "Executed RunApp for $($appConfig.Name) repo"
}

Function RunPullRequestPrep { 
    BuildApp
    TestApp
}
Set-Alias -Name pr -Value RunPullRequestPrep

function AppInfo {
    $appConfig = (GetCurrentAppConfig)
    if ($null -eq $appConfig) {
        Write-Host "No app config found for this repo." -ForegroundColor Red
        return
    }

    $branch = git rev-parse --abbrev-ref HEAD

    write-host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "APPLICATION INFO" -ForegroundColor DarkGray
    write-host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "AppName:   " -NoNewline -ForegroundColor DarkYellow
    write-host "$($appConfig.Name)"
    Write-Host "Repo:      " -NoNewline -ForegroundColor DarkYellow
    write-host "$($appConfig.Repo)"
    Write-Host "Branch:    " -NoNewline -ForegroundColor DarkYellow
    write-host "$branch"
    Write-host "Methods:   " -NoNewline -ForegroundColor DarkYellow
    write-host "$($appConfig.AuthMethod), $($appConfig.SetupMethod), $($appConfig.BuildMethod), $($appConfig.TestMethod), $($appConfig.RunMethod), $($appConfig.DevMethod)"
    write-host "'Go' Links:" -ForegroundColor DarkYellow
    foreach ($link in $global:goTaskStore.GetEnumerator()) {
        Write-Host "            $($link.Key)" -NoNewline
        write-host " - $($link.Value)" -ForegroundColor DarkGray
    }
    write-host "---------------------------------------------------------" -ForegroundColor DarkGray
}

function DevEnv {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.DevMethod -ne "") {
            & $appConfig.DevMethod
        }
        else {
            write-host "No development method configured."
        }
    }
    finally {
        Set-Location $src
    }
}

function viewPRs {
    $src = Get-Location

    try {
        $appConfig = (GetCurrentAppConfig)

        if ($appConfig.ReviewPullRequests -ne "") {
            & $appConfig.ReviewPullRequests

            if ($appConfig.OpenPullRequests -ne "") {
                Read-host "Open pull request by id?: " | ForEach-Object {
                    if ($_ -ne "") {
                        $pullRequestId = $_
                        & $appConfig.OpenPullRequest $pullRequestId
                    }
                }
            }
        }
        else {
            write-host "No pull request review method configured."
        }
    }
    finally {
        Set-Location $src
    }
}
