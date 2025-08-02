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



# Adds a predefined string to clipboard based on type parameter
function AiExpander {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("email", "prompt", "summarize", "brainstorm")]
        [string]$Type,
        [string]$AdditionalInfo
    )
    
    $clipboardText = switch ($Type) {
        "email" {
            gemini -p "Write a professional email with the following information: $AdditionalInfo"
        }
        "prompt" { 
            gemini -p $AdditionalInfo
        }
        "summarize" {
            if ($AdditionalInfo) {
                gemini -p "Summarize this text: $AdditionalInfo"
            }
            else {
                gemini -p "Summarize this text."
            }
        }
        "brainstorm" {
            gemini -p "Brainstorm ideas for: $AdditionalInfo"
        }
    }
    
    # Set-Clipboard -Value $clipboardText
    Write-Host $clipboardText
}

# Decodes a base64 encoded string
function Base64Decode {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Base64String
    )
    
    try {
        # Remove any whitespace that might interfere with decoding
        $cleanBase64 = $Base64String.Trim()
        
        # Decode the base64 string
        $decodedBytes = [Convert]::FromBase64String($cleanBase64)
        $decodedText = [System.Text.Encoding]::UTF8.GetString($decodedBytes)
        
        Write-Host "Decoded text: $decodedText" -ForegroundColor Green
        return $decodedText
    }
    catch {
        Write-Host "Error decoding base64 string: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Export-ModuleMember -Function CleanEventLog, DumpEventLog, HostsFile, AiExpander, Base64Decode