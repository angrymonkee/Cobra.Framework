$global:goCommandsScriptLoaded = $true

# Dependencies:
# Load the core script if it hasn't been loaded yet
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

Log-CobraActivity "Loading 'go' command scripts..."

function go ([string] $name) {
    try {
        if ($null -ne $global:goTaskStore -and $global:goTaskStore.ContainsKey($name) -eq $true) {
            Write-Host "Opening URL $name"
            GoToUrl $global:goTaskStore[$name][1]
            Log-CobraActivity "Opened URL for 'Go' location: $name."
        }
        else {
            Write-Host "'GO' HELP" -ForegroundColor DarkGray
            write-host "---------------------------------------------------------" -ForegroundColor DarkGray
            Write-Host "Opens a named location, using the following format:" -ForegroundColor DarkGray
            Write-Host "    'go <name>'" -ForegroundColor DarkGray
            write-host
            Write-Host "Example:" -ForegroundColor DarkGray
            Write-Host "    PS>go Docs" -ForegroundColor DarkGray
            Write-Host
            Write-Host "Valid 'Go' locations are:" -ForegroundColor DarkGray
            foreach ($key in $global:goTaskStore.Keys | sort-object) {
                Write-Host "    $key" -NoNewline
                write-host " - $($global:goTaskStore[$key][0])" -ForegroundColor DarkGray
            }
            Log-CobraActivity "Failed to open 'Go' location: $name. Location not found."
        }    
    }
    catch {
        go
        Log-CobraActivity "Error occurred while executing 'go' command for: $name. Error: $($_.Exception.Message)"
    }
}

function Add-GoLocation {
    param (
        [string]$name,
        [string]$description,
        [string]$url
    )

    if ($null -eq $global:goTaskStore) {
        $global:goTaskStore = @{}
    }

    $global:goTaskStore[$name] = @($description, $url)
    $config = GetCurrentAppConfig
    Update-ModuleConfigFile $config.Name
    Write-Host "Added Go location: $name - $description"
}

function Remove-GoLocation {
    param (
        [string]$name
    )

    if ($null -ne $global:goTaskStore -and $global:goTaskStore.ContainsKey($name)) {
        $global:goTaskStore.Remove($name)
        $config = GetCurrentAppConfig
        Update-ModuleConfigFile $config.Name
        Write-Host "Removed Go location: $name"
    }
    else {
        Write-Host "Go location not found: $name" -ForegroundColor Red
    }
}

function Update-GoLocation {
    param (
        [string]$name,
        [string]$description,
        [string]$url
    )

    if ($null -ne $global:goTaskStore -and $global:goTaskStore.ContainsKey($name)) {
        $global:goTaskStore[$name] = @($description, $url)
        $config = GetCurrentAppConfig
        Update-ModuleConfigFile $config.Name
        Write-Host "Updated Go location: $name - $description"
    }
    else {
        Write-Host "Go location not found: $name" -ForegroundColor Red
    }
}

enum CobraGoCommands {
    add
    remove
    update
}

function CobraGoDriver([CobraGoCommands] $command, [string[]] $options) {
    switch ($command) {
        add {
            if ($options.Count -eq 3) {
                # Pass parameters directly from the array
                Add-GoLocation -name $options[0] -description $options[1] -url $options[2]
            }
            else {
                Write-Host "Invalid options for 'add'. Provide name, description, and URL as arguments." -ForegroundColor Red
            }
        }
        remove {
            if ($options.Count -eq 1) {
                # Pass the name directly to Remove-GoLocation
                Remove-GoLocation -name $options[0]
            }
            else {
                Write-Host "Invalid options for 'remove'. Provide the name as an argument." -ForegroundColor Red
            }
        }
        update {
            if ($options.Count -eq 3) {
                # Pass parameters directly from the array
                Update-GoLocation -name $options[0] -description $options[1] -url $options[2]
            }
            else {
                Write-Host "Invalid options for 'update'. Provide name, description, and URL as arguments." -ForegroundColor Red
            }
        }
        default {
            Write-Host "Invalid command. Type 'cobra go' for usage."
        }
    }

    # Log 'go' location operations
    Log-CobraActivity "Executed $command command with options: $($options -join ', ')"
}
