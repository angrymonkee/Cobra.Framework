if (-not ($global:coreScriptLoaded)) {
    . "$env:COBRA_ROOT/Core.ps1"
}

Log-CobraActivity "Loading Reporting Scripts..."

# COBRA Setup
$commandName = "reporting"
$global:CobraScriptModules[$commandName] = @("Scripts for showing reports", "Report_Scripts.ps1")

Add-Type -AssemblyName System.Windows.Forms

function Dashboard {
    Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "     #### #### ###  ###  ####    ###  #### #### #  #" -ForegroundColor Yellow
    Write-Host "     #    #  # #__# #__# #__#    #  # #__# #__  #__#" -ForegroundColor Yellow
    Write-Host "     #    #  # #  # # #  #  #    #  # #  #    # #  #" -ForegroundColor Yellow
    Write-Host "     #### #### ###  #  # #  #    ###  #  # #### #  #" -ForegroundColor Yellow
    # Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray

    SysInfo
}

function SysInfo {
    write-host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "SYSTEM INFO" -ForegroundColor DarkGray
    write-host "---------------------------------------------------------" -ForegroundColor DarkGray

    # Get CPU information
    $cpu = Get-WmiObject Win32_Processor | Select-Object -Property Name, NumberOfCores, NumberOfLogicalProcessors
    Write-Host -NoNewline "CPU: " -ForegroundColor DarkYellow
    Write-Host "$($cpu.Name)"
    Write-Host -NoNewline "Cores: " -ForegroundColor DarkYellow
    Write-host "$($cpu.NumberOfCores)"
    Write-Host -NoNewline "Logical Processors: " -ForegroundColor DarkYellow
    Write-Host "$($cpu.NumberOfLogicalProcessors)"

    # Get memory information
    $memory = Get-WmiObject Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum
    $totalMemory = [math]::round($memory.Sum / 1GB, 2)
    Write-Host -NoNewline "Total Memory: " -ForegroundColor DarkYellow
    Write-Host "$totalMemory GB"

    # Get disk information
    $disks = Get-WmiObject Win32_LogicalDisk -Filter "DriveType=3" | Select-Object -Property DeviceID, Size, FreeSpace
    foreach ($disk in $disks) {
        $size = [math]::round($disk.Size / 1GB, 2)
        $freeSpace = [math]::round($disk.FreeSpace / 1GB, 2)
        $percentUsed = [math]::Floor(($size - $freeSpace) / $size * 10)
        Write-Host -NoNewline "Disk $($disk.DeviceID): " -ForegroundColor DarkYellow
        BarGraphZeroToTen $percentUsed
        Write-Host " $size GB (Free: $freeSpace GB)"
    }

    # Get network information
    $network = Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled=TRUE" | Select-Object -Property Description, MACAddress, IPAddress
    foreach ($adapter in $network) {
        Write-Host -NoNewline "Network Adapter: " -ForegroundColor DarkYellow
        Write-host "$($adapter.Description)"
        Write-Host -NoNewline "MAC Address: " -ForegroundColor DarkYellow
        Write-Host "$($adapter.MACAddress)"
        Write-Host -NoNewline "IP Address: " -ForegroundColor DarkYellow
        Write-Host "$($adapter.IPAddress -join ', ')"
    }

    Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
}

function Utilization {

    while ($true) {
        $job = Start-Job -ScriptBlock {

            # CPU Counter
            $cpuCounter = Get-Counter '\Processor(_Total)\% Processor Time'
            $cpuUtilization = $cpuCounter.CounterSamples[0].CookedValue
        
            # Memory Counter
            $memoryCounter = Get-Counter '\Memory\% Committed Bytes In Use'
            $memoryUtilization = $memoryCounter.CounterSamples[0].CookedValue
            
            # Disk Counter
            $diskCounter = Get-Counter '\PhysicalDisk(_Total)\Disk Bytes/sec'
            $diskTransferRateBytes = $diskCounter.CounterSamples[0].CookedValue
            $diskTransferRateMB = [math]::round($diskTransferRateBytes / 1MB, 2) # Convert to MB/s

            [PSCustomObject]@{
                CPU    = $cpuUtilization / 10
                Memory = [math]::Floor($memoryUtilization / 10)
                Disk   = [math]::Floor($diskTransferRateMB / 10)
            }
        }

        Wait-Job $job
        $results = Receive-Job $job
        cls
        Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "UTILIZATION" -ForegroundColor DarkGray
        Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray

        write-host -NoNewline "CPU:  " -ForegroundColor DarkYellow
        BarGraphZeroToTen ($results.CPU)
        write-host -NoNewline " Memory: " -ForegroundColor DarkYellow
        BarGraphZeroToTen ($results.Memory)
        write-host ""
        write-host -NoNewline "Disk: " -ForegroundColor DarkYellow
        BarGraphZeroToTen ($results.Disk)

        Remove-Job $job
        Start-Sleep -Seconds 5
    }
}

function Procs {
    $appConfig = (GetCurrentAppConfig)
    $processMap = $appConfig.Procs

    if ($null -eq $appConfig) {
        Write-Host "No application configuration found for the current repository."
        return
    }

    while ($true) {
        $job = Start-Job -ScriptBlock {
            # TODO: Change this to call the Procs method
            $processMap = $using:processMap
            $processes = @()
            foreach ($key in $processMap.Keys) {
                try {
                    $process = Get-Process -Name $key -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -like $processMap[$key] } -ErrorAction SilentlyContinue
                    if ($process) {
                        $processes += $process
                    }
                }
                catch {}
            }
            $processes | Sort-Object -Property CPU -Descending | Format-Table `
                Id, 
            ProcessName, 
            @{Label = "CPU(s)"; Expression = { if ($_.CPU) { $_.CPU.ToString("N") } } },
            @{Label = "VM(M)"; Expression = { [int]($_.VM / 1MB) } },
            @{Label = "NPM(K)"; Expression = { [int]($_.NPM / 1024) } },
            @{Label = "PM(K)"; Expression = { [int]($_.PM / 1024) } },
            @{Label = "WS(K)"; Expression = { [int]($_.WS / 1024) } },
            StartTime -AutoSize
        }

        Wait-Job $job
        $results = Receive-Job $job
        $resultsString = $results | Format-Table -AutoSize | Out-String
        cls
        write-host "-------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "REPO PROCESSES" -ForegroundColor DarkGray
        write-host "-------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "$resultsString"
        write-host "===================================================================" -ForegroundColor DarkGray
        write-host "(VM) Virtual Memory,(NPM) Non-Paged Memory,(PM)Paged Memory," -ForegroundColor DarkGray
        write-host "(WS)Working Set" -ForegroundColor DarkGray
        write-host "-------------------------------------------------------------------" -ForegroundColor DarkGray
        # Receive-Job $job
        Remove-Job $job
        Start-Sleep -Seconds 5
    }
}

function BarGraphZeroToTen ([int] $value) {

    $clnValue = $value
    $clnValue = [math]::Min($clnValue, 10)
    $clnValue = [math]::Max($clnValue, 0)

    for ($i = 0; $i -lt $clnValue; $i++) {
        if ($i -le 3) {
            $color = "Green"
        }
        elseif ($i -le 7) {
            $color = "Yellow"
        }
        else {
            $color = "Red"
        }
        Write-Host -NoNewline -ForegroundColor $color "#"
    }
    for ($i = $clnValue; $i -lt 10; $i++) {
        Write-Host -NoNewline -ForegroundColor DarkGray "#"
    }

    Write-Host -NoNewline " ($($clnValue * 10)%)"
}

#=================== Script Information ===================
Write-Host -ForegroundColor Green "Reporting tools loaded successfully. For details type '$commandName'."
function ReportingHelp {
    Write-Host "Available Commands:"
    Write-Host "  $commandName - Displays this help information."
}
set-alias -name $commandName -value ReportingHelp