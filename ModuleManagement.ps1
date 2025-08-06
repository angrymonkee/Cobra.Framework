$global:moduleManagementScriptLoaded = $true

# Dependencies:
# Load the core script if it hasn't been loaded yet
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

Log-CobraActivity "Loading module management scripts..."

enum CobraModulesCommands {
    add
    remove
    edit
    import
    export
    registry
}

# Browse and explore the Cobra Module Registry
function Browse-ModuleRegistry {
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("list", "info", "search", "open", "push", "pull")]
        [string]$Action = "list",
        
        [Parameter(Mandatory = $false)]
        [string]$ModuleName,
        
        [Parameter(Mandatory = $false)]
        [string]$SearchTerm
    )
    
    # Get the module registry location from global config
    if (-not $global:CobraConfig.ModuleRegistryLocation) {
        Write-Host "ModuleRegistryLocation is not configured in CobraConfig." -ForegroundColor Red
        Write-Host "Please check your sysconfig.ps1 file." -ForegroundColor Yellow
        return
    }
    
    $registryPath = $global:CobraConfig.ModuleRegistryLocation
    
    # Check if the registry path exists
    if (-not (Test-Path $registryPath)) {
        Write-Host "Module registry path does not exist: $registryPath" -ForegroundColor Red
        return
    }
    
    switch ($Action) {
        "list" {
            Write-Host "COBRA MODULE REGISTRY" -ForegroundColor Cyan
            Write-Host "Location: $registryPath" -ForegroundColor DarkGray
            
            $modules = Get-ChildItem -Path $registryPath -File | Sort-Object Name
            
            if ($modules.Count -eq 0) {
                Write-Host "No modules found in the registry." -ForegroundColor Yellow
                return
            }
            
            foreach ($module in $modules) {
                $size = [math]::Round($module.Length / 1KB, 2)
                $lastModified = $module.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                
                Write-Host "  $($module.Name)" -ForegroundColor Green -NoNewline
                Write-Host " ($size KB) - Modified: $lastModified" -ForegroundColor DarkGray
            }
            
            Write-Host ""
            Write-Host "Total modules: $($modules.Count)" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Usage:" -ForegroundColor DarkGray
            Write-Host "  cobra modules registry info <module-name>     # Get module details" -ForegroundColor DarkGray
            Write-Host "  cobra modules registry search <search-term>   # Search modules" -ForegroundColor DarkGray
            Write-Host "  cobra modules registry open                   # Open registry folder" -ForegroundColor DarkGray
            Write-Host "  cobra modules registry push <module-name>     # Push module to registry" -ForegroundColor DarkGray
            Write-Host "  cobra modules registry pull <module-name>     # Pull module from registry" -ForegroundColor DarkGray
        }
        "info" {
            if (-not $ModuleName) {
                Write-Host "Please provide a module name: cobra modules registry info <module-name>" -ForegroundColor Red
                return
            }
            
            $modulePath = Join-Path $registryPath $ModuleName
            
            if (-not (Test-Path $modulePath)) {
                Write-Host "Module not found: $ModuleName" -ForegroundColor Red
                Write-Host "Available modules:" -ForegroundColor Yellow
                Get-ChildItem -Path $registryPath -File | ForEach-Object { Write-Host "  $($_.Name)" -ForegroundColor DarkGray }
                return
            }
            
            $moduleFile = Get-Item $modulePath
            $size = [math]::Round($moduleFile.Length / 1KB, 2)
            
            Write-Host "MODULE INFORMATION" -ForegroundColor Cyan
            Write-Host "Name: $($moduleFile.Name)" -ForegroundColor White
            Write-Host "Size: $size KB" -ForegroundColor White
            Write-Host "Created: $($moduleFile.CreationTime)" -ForegroundColor White
            Write-Host "Modified: $($moduleFile.LastWriteTime)" -ForegroundColor White
            Write-Host "Path: $($moduleFile.FullName)" -ForegroundColor DarkGray
            
            # Try to determine file type and show additional info
            $extension = $moduleFile.Extension.ToLower()
            switch ($extension) {
                ".zip" { 
                    Write-Host "Type: ZIP Archive" -ForegroundColor Green
                    Write-Host "Use 'cobra modules import $($moduleFile.BaseName)' to install this module." -ForegroundColor Yellow
                }
                ".ps1" { 
                    Write-Host "Type: PowerShell Script" -ForegroundColor Green 
                }
                ".psm1" { 
                    Write-Host "Type: PowerShell Module" -ForegroundColor Green 
                }
                default { 
                    Write-Host "Type: $($extension.TrimStart('.').ToUpper()) File" -ForegroundColor Green 
                }
            }
        }
        "search" {
            if (-not $SearchTerm) {
                Write-Host "Please provide a search term: cobra modules registry search <search-term>" -ForegroundColor Red
                return
            }
            
            Write-Host "SEARCHING MODULE REGISTRY" -ForegroundColor Cyan
            Write-Host "Search term: '$SearchTerm'" -ForegroundColor DarkGray
            
            $matchingModules = Get-ChildItem -Path $registryPath -File | Where-Object { $_.Name -like "*$SearchTerm*" }
            
            if ($matchingModules.Count -eq 0) {
                Write-Host "No modules found matching '$SearchTerm'" -ForegroundColor Yellow
                return
            }
            
            foreach ($module in $matchingModules) {
                $size = [math]::Round($module.Length / 1KB, 2)
                $highlightedName = $module.Name -replace [regex]::Escape($SearchTerm), "[$SearchTerm]"
                
                Write-Host "$highlightedName" -ForegroundColor Green -NoNewline
                Write-Host " ($size KB)" -ForegroundColor DarkGray
            }
            
            Write-Host ""
            Write-Host "Found $($matchingModules.Count) matching modules." -ForegroundColor Cyan
        }
        "open" {
            Write-Host "Opening module registry folder..." -ForegroundColor Green
            try {
                Start-Process explorer.exe -ArgumentList $registryPath
                Write-Host "Registry folder opened: $registryPath" -ForegroundColor Green
            }
            catch {
                Write-Host "Error opening folder: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        "push" {
            if (-not $ModuleName) {
                Write-Host "Please provide a module name: cobra modules registry push <module-name>" -ForegroundColor Red
                return
            }

            Write-Host "Pushing module: $ModuleName"
            
            # Export module and push to registry
            Export-CobraModule -moduleName $ModuleName -artifactPath $registryPath
        }
        "pull" {
            if (-not $ModuleName) {
                Write-Host "Please provide a module name: cobra modules registry pull <module-name>" -ForegroundColor Red
                return
            }

            Write-Host "Pulling module: $ModuleName"
            
            # Import module from registry
            $artifactPath = Join-Path $registryPath "$ModuleName.zip"
            Import-CobraModule -moduleName $ModuleName -artifactPath $artifactPath
        }
    }
}

function CobraModulesDriver([CobraModulesCommands] $command, [string[]] $options) {
    switch ($command) {
        add {
            if ($options.Count -eq 1) {
                $moduleName = $options[0]
                $modulePath = Join-Path $PSScriptRoot "Modules\$moduleName"
                if (-not (Test-Path $modulePath)) {
                    New-Item -Path $modulePath -ItemType Directory
                    New-Item -Path "$modulePath\$moduleName.psm1" -ItemType File
                    New-Item -Path "$modulePath\config.ps1" -ItemType File

                    New-ModuleConfigFile "$moduleName"
                    New-ModuleTemplate "$moduleName"
                    $global:CobraScriptModules[$moduleName] = @($moduleName, $moduleName)

                    Import-Module $modulePath -Force -DisableNameChecking
                    # Initialize the module
                    & "Initialize-$($moduleName)Module"
                    Write-Host "Created new module: $moduleName"
                }
                else {
                    Write-Host "Module already exists: $moduleName" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Invalid options for 'add'. Provide the name of the module to add." -ForegroundColor Red
            }
        }
        edit {
            if ($options.Count -eq 1) {
                $moduleName = $options[0]
                write-host "Editing module: $moduleName at location $PSScriptRoot\Modules\$moduleName\$moduleName.psm1"
                write-host "Editing module: $moduleName at location $PSScriptRoot\Modules\$moduleName\config.ps1"
                code "$PSScriptRoot\Modules\$moduleName\$moduleName.psm1"
                code "$PSScriptRoot\Modules\$moduleName\config.ps1"
            }
            else {
                Write-Host "Invalid options for 'edit'. Provide the name of the module to edit." -ForegroundColor Red
            }
        }
        remove {
            if ($options.Count -eq 1) {
                $moduleName = $options[0]
                $modulePath = Join-Path $PSScriptRoot "Modules\$moduleName"
                if (Test-Path $modulePath) {
                    Write-Host "Are you sure you want to remove the module $moduleName? This action cannot be undone." -ForegroundColor Red
                    $confirmation = Read-Host "Type 'yes' to confirm removal of the module"
                    if ($confirmation -ne "yes") {
                        Write-Host "Module removal canceled." -ForegroundColor Yellow
                        return
                    }

                    Remove-Module $moduleName -Force
                    $global:CobraScriptModules.Remove($moduleName)
                    Remove-Item -Path $modulePath -Recurse -Force
                    Write-Host "Removed module: $moduleName"
                }
                else {
                    Write-Host "Module not found: $moduleName" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Invalid options for 'remove'. Provide the name of the module to remove." -ForegroundColor Red
            }
        }
        import {
            if ($options.Count -gt 0) {
                $moduleName = $options[0]
                $artifactPath = $options[1]
                Import-CobraModule -moduleName $moduleName -artifactPath $artifactPath
            }
            else {
                Write-Host "Invalid options for 'import'. Provide the name of the module and the artifact path." -ForegroundColor Red
            }
        }
        export {
            if ($options.Count -eq 2) {
                $moduleName = $options[0]
                $artifactPath = $options[1]
                Export-CobraModule -moduleName $moduleName -artifactPath $artifactPath
            }
            else {
                Write-Host "Invalid options for 'export'. Provide the name of the module and the artifact path." -ForegroundColor Red
            }
        }
        registry {
            $action = if ($options.Count -gt 0) { $options[0] } else { "list" }
            $moduleName = if ($options.Count -gt 1) { $options[1] } else { $null }
            $searchTerm = if ($options.Count -gt 1) { $options[1] } else { $null }
            
            Browse-ModuleRegistry -Action $action -ModuleName $moduleName -SearchTerm $searchTerm
        }
        default {
            CobraHelp
        }
    }

    # Log module operations
    Log-CobraActivity "Executed $command command with options: $($options -join ', ')"
}

function ShowCobraScriptModules() {
    write-host "AVAILABLE COBRA MODULES" -ForegroundColor DarkGray
    Write-Host "--------------------------------------------" -ForegroundColor DarkGray
    $global:CobraScriptModules.GetEnumerator() | Sort-Object -Property Key | ForEach-Object {
        Write-Host " $($_.Key) " -NoNewline
        write-host "- $($_.Value[1])" -ForegroundColor DarkGray
    }
}

function Import-CobraModule {
    param (
        [string]$moduleName,
        [string]$artifactPath
    )

    $destinationPath = Join-Path $PSScriptRoot "Modules\$moduleName"

    # If no artifactPath is provided, look in the CobraModuleRegistry
    if (-not $artifactPath) {
        $registryPath = $global:CobraConfig.ModuleRegistryLocation
        $artifactPath = Join-Path $registryPath "$moduleName.zip"

        if (-not (Test-Path $artifactPath)) {
            Write-Host "Artifact for module '$moduleName' not found in the module registry at $artifactPath." -ForegroundColor Red
            return
        }

        Write-Host "Using artifact from module registry: $artifactPath" -ForegroundColor Yellow
    }

    if (Test-Path $destinationPath) {
        Write-Host "Module '$moduleName' already exists at $destinationPath." -ForegroundColor Yellow
        $confirmation = Read-Host "Type 'yes' to overwrite the existing module"
        if ($confirmation -ne "yes") {
            Write-Host "Import canceled." -ForegroundColor Yellow
            return
        }

        Remove-Item -Path $destinationPath -Recurse -Force
        Write-Host "Existing module removed." -ForegroundColor Green
    }

    # Extract the artifact
    if (-not (Test-Path $artifactPath)) {
        Write-Host "Artifact '$artifactPath' does not exist." -ForegroundColor Red
        return
    }

    # Create the destination directory
    New-Item -Path $destinationPath -ItemType Directory | Out-Null

    # Extract only the contents of the module directory from the archive
    Expand-Archive -Path $artifactPath -DestinationPath $env:TEMP -Force
    $tempModulePath = Join-Path $env:TEMP $moduleName
    if (Test-Path $tempModulePath) {
        Move-Item -Path (Join-Path $tempModulePath "*") -Destination $destinationPath -Force
        Remove-Item -Path $tempModulePath -Recurse -Force
        Write-Host "Module '$moduleName' extracted to $destinationPath." -ForegroundColor Green
    }
    else {
        Write-Host "Module directory '$moduleName' not found in the artifact." -ForegroundColor Red
        return
    }

    # Register the module in the global profile
    $global:CobraScriptModules[$moduleName] = @($moduleName, "$moduleName.psm1")

    # Load the module into the current session
    $moduleFile = Join-Path "$destinationPath" "$moduleName.psm1"
    if (Test-Path $moduleFile) {
        Import-Module $moduleFile -Force -DisableNameChecking
        # Initialize the module
        & "Initialize-$($moduleName)Module"
        Write-Host "Module '$moduleName' loaded into the current session." -ForegroundColor Green
    }
    else {
        Write-Host "Module file '$moduleFile' not found. Could not load into the session." -ForegroundColor Red
    }
}

function Export-CobraModule {
    param (
        [string]$moduleName,
        [string]$artifactPath
    )

    $modulePath = Join-Path $PSScriptRoot "Modules\$moduleName"

    if (-not (Test-Path $modulePath)) {
        Write-Host "Module '$moduleName' does not exist at $modulePath." -ForegroundColor Red
        return
    }

    $tempArchivePath = Join-Path $env:TEMP "$moduleName.zip"

    # Create a compressed artifact
    Compress-Archive -Path $modulePath -DestinationPath $tempArchivePath -Force
    Move-Item -Path $tempArchivePath -Destination $artifactPath -Force
    Write-Host "Module '$moduleName' exported as artifact to $artifactPath." -ForegroundColor Green
}