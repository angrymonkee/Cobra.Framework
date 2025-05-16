# This script contains utility functions for various system tasks.

# Clears the event log using the Windows Event Viewer
function CleanEventLog {
    write-host "Cleaning event log..."
}

# Dumps the event log using the Windows Event Viewer
function DumpEventLog {
    write-host "Dumping event log..."
}

# Open the hosts file in Notepad with elevated privileges
function HostsFile {
    Start-Process notepad "$env:SystemRoot\System32\drivers\etc\hosts" -Verb runAs
}

Export-ModuleMember -Function CleanEventLog, DumpEventLog, HostsFile