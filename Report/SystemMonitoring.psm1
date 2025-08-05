function Dashboard {
    Write-Host "---------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "     #### #### ###  ###  ####    ###  #### #### #  #" -ForegroundColor Yellow
    Write-Host "     #    #  # #__# #__# #__#    #  # #__# #__  #__#" -ForegroundColor Yellow
    Write-Host "     #    #  # #  # # #  #  #    #  # #  #    # #  #" -ForegroundColor Yellow
    Write-Host "     #### #### ###  #  # #  #    ###  #  # #### #  #" -ForegroundColor Yellow

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