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
                CPU = $cpuUtilization / 10
                Memory = [math]::Floor($memoryUtilization / 10)
                Disk = [math]::Floor($diskTransferRateMB / 10)
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

    if($null -eq $appConfig) {
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
            @{Label = "CPU(s)"; Expression = {if ($_.CPU) {$_.CPU.ToString("N")}}},
            @{Label = "VM(M)"; Expression = {[int]($_.VM / 1MB)}},
            @{Label = "NPM(K)"; Expression = {[int]($_.NPM / 1024)}},
            @{Label = "PM(K)"; Expression = {[int]($_.PM / 1024)}},
            @{Label = "WS(K)"; Expression = {[int]($_.WS / 1024)}},
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