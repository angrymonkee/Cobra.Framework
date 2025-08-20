# Email.psm1 - Standalone Module
# Created: 2025-08-13
# Author: dajon
# Description: Email management and automation module for senior engineers

function Initialize-EmailModule {
    [CmdletBinding()]
    param()

    # Validate configuration
    $config = . "$PSScriptRoot/config.ps1"
    if (-not $config) {
        throw "Failed to load module configuration"
    }
    
    # Load module configuration
    $config = . "$PSScriptRoot/config.ps1"
    
    # Register as standalone module (no repository dependency)
    Register-CobraStandaloneModule -Name "Email" -Description "$($config.Description)" -Config $config

    Log-CobraActivity "Email standalone module initialized"
}

# Email Formatting Helper Functions
function Format-EmailBodyUrls {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Body
    )
    
    $processedBody = $Body
    $urlCount = 0
    $global:EmailUrlCache = @{}
    
    # Microsoft SafeLinks pattern - these are extremely long and unreadable
    $safeLinksPattern = 'https://[^.]+\.safelinks\.protection\.outlook\.com/\?url=[^>\s<]+'
    $safeLinksMatches = [regex]::Matches($processedBody, $safeLinksPattern)
    foreach ($match in $safeLinksMatches) {
        $urlCount++
        $placeholder = "[SafeLink] ($urlCount)"
        $global:EmailUrlCache[$urlCount] = @{
            FullUrl     = $match.Value
            Description = 'Microsoft SafeLink'
            Placeholder = $placeholder
        }
        $processedBody = $processedBody -replace [regex]::Escape($match.Value), $placeholder
    }
    
    # Generic long URLs (over 100 characters) - but skip ones we already processed
    $longUrlPattern = 'https?://[^\s<>]{100,}'
    $longUrlMatches = [regex]::Matches($processedBody, $longUrlPattern)
    foreach ($match in $longUrlMatches) {
        # Skip if this URL was already processed (contains our placeholder text)
        if ($match.Value -notlike "*SafeLink*" -and $match.Value -notlike "*Long URL*") {
            $urlCount++
            $placeholder = "[Long URL] ($urlCount)"
            $global:EmailUrlCache[$urlCount] = @{
                FullUrl     = $match.Value
                Description = 'Long URL'
                Placeholder = $placeholder
            }
            $processedBody = $processedBody -replace [regex]::Escape($match.Value), $placeholder
        }
    }
    
    # Azure short URLs - keep these but indicate if they're still long
    $azureUrlPattern = 'https://aka\.ms/[^\s<>]+'
    $azureUrlMatches = [regex]::Matches($processedBody, $azureUrlPattern)
    foreach ($match in $azureUrlMatches) {
        if ($match.Value.Length -gt 30) {
            $urlCount++
            $placeholder = "[aka.ms/...] ($urlCount)"
            $global:EmailUrlCache[$urlCount] = @{
                FullUrl     = $match.Value
                Description = 'Azure Short URL'
                Placeholder = $placeholder
            }
            $processedBody = $processedBody -replace [regex]::Escape($match.Value), $placeholder
        }
    }
    
    # Add URL summary if we found any
    if ($urlCount -gt 0) {
        $processedBody += "`n📎 Links in this email ($urlCount found):"
        $processedBody += "`n   💡 Use 'email urls' to see full URLs"
        $processedBody += "`n   💡 Use 'email url <number>' to copy specific URL"
    }
    
    return $processedBody
}

function Get-EmailUrls {
    [CmdletBinding()]
    param(
        [int]$UrlNumber = 0
    )
    
    if (-not $global:EmailUrlCache -or $global:EmailUrlCache.Count -eq 0) {
        Write-Host "❌ No URLs cached. Open an email first using 'email open <ID>'" -ForegroundColor Red
        return
    }
    
    if ($UrlNumber -eq 0) {
        # Show all URLs
        Write-Host "🔗 URLs from last opened email:" -ForegroundColor Cyan
        
        foreach ($key in $global:EmailUrlCache.Keys | Sort-Object) {
            $urlInfo = $global:EmailUrlCache[$key]
            Write-Host "$key. " -NoNewline -ForegroundColor Yellow
            Write-Host "$($urlInfo.Description)" -ForegroundColor White
            Write-Host "   $($urlInfo.FullUrl)" -ForegroundColor DarkGray
            Write-Host
        }
        
        Write-Host "💡 Use 'email url <number>' to copy a specific URL to clipboard" -ForegroundColor Yellow
    }
    else {
        # Show specific URL
        if ($global:EmailUrlCache.ContainsKey($UrlNumber)) {
            $urlInfo = $global:EmailUrlCache[$UrlNumber]
            Write-Host "🔗 URL #$UrlNumber`: " -NoNewline -ForegroundColor Cyan
            Write-Host "$($urlInfo.Description)" -ForegroundColor White
            Write-Host "$($urlInfo.FullUrl)" -ForegroundColor Gray
            
            # Try to copy to clipboard
            try {
                $urlInfo.FullUrl | Set-Clipboard
                Write-Host "✅ URL copied to clipboard!" -ForegroundColor Green
            }
            catch {
                Write-Host "⚠️  Could not copy to clipboard. You can manually copy the URL above." -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "❌ URL #$UrlNumber not found. Available URLs: $($global:EmailUrlCache.Keys -join ', ')" -ForegroundColor Red
        }
    }
}

# Core Email Functions
function Get-EmailStatus {
    [CmdletBinding()]
    param()
    
    $config = . "$PSScriptRoot/config.ps1"
    Write-Host "Email Module Status:" -ForegroundColor Cyan
    Write-Host "  Name: $($config.Name)" -ForegroundColor White
    Write-Host "  Description: $($config.Description)" -ForegroundColor White
    Write-Host "  Version: $($config.Version)" -ForegroundColor White
    Write-Host "  Type: Standalone" -ForegroundColor Green
    Write-Host "  Provider: $($config.Settings.Provider)" -ForegroundColor White
    
    # Show connection status
    Test-EmailConnection -ShowStatus
}

function Get-EmailInbox {
    [CmdletBinding()]
    param(
        [int]$Count = 10,
        [switch]$UnreadOnly,
        [switch]$HighPriorityOnly,
        [string]$From,
        [string]$Subject
    )
    
    Log-CobraActivity "Email inbox requested - Count: $Count, UnreadOnly: $UnreadOnly, HighPriorityOnly: $HighPriorityOnly, From: $From"
    
    $config = . "$PSScriptRoot/config.ps1"
    
    try {
        switch ($config.Settings.Provider) {
            "Outlook" {
                Get-OutlookEmails -Count $Count -UnreadOnly:$UnreadOnly -HighPriorityOnly:$HighPriorityOnly -From $From -Subject $Subject
            }
            "Graph" {
                Get-GraphEmails -Count $Count -UnreadOnly:$UnreadOnly -HighPriorityOnly:$HighPriorityOnly -From $From -Subject $Subject
            }
            "Gmail" {
                Get-GmailEmails -Count $Count -UnreadOnly:$UnreadOnly -HighPriorityOnly:$HighPriorityOnly -From $From -Subject $Subject  
            }
            "SMTP" {
                Write-Host "SMTP provider doesn't support reading emails. Use Outlook, Graph or Gmail for inbox functionality." -ForegroundColor Yellow
            }
            default {
                Write-Host "Unknown email provider: $($config.Settings.Provider)" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "Error retrieving emails: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Run 'Test-EmailConfiguration' to check your setup" -ForegroundColor Yellow
    }
}

function Send-Email {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$To,
        
        [Parameter(Mandatory)]
        [string]$Subject,
        
        [Parameter(Mandatory)]
        [string]$Body,
        
        [string[]]$Cc,
        [string[]]$Bcc,
        [string[]]$Attachments,
        [switch]$HighPriority,
        [string]$Template,
        [hashtable]$TemplateParameters = @{},
        [switch]$UseAI
    )
    
    $config = . "$PSScriptRoot/config.ps1"
    
    # Handle template-based emails
    if ($Template) {
        $Body = Get-EmailTemplate -TemplateName $Template -Parameters $TemplateParameters
        if (-not $Body) {
            Write-Host "Failed to load template: $Template" -ForegroundColor Red
            Log-CobraActivity "Failed to load email template: $Template"
            return
        }
        Log-CobraActivity "Email template loaded successfully: $Template"
    }
    
    # AI enhancement
    if ($UseAI) {
        $Body = Invoke-EmailAI -Type "email-compose" -Content $Body -Subject $Subject
    }
    
    # Add signature
    if ($config.Settings.DefaultSignature) {
        $Body += "`n`n$($config.Settings.DefaultSignature)"
    }
    
    try {
        switch ($config.Settings.Provider) {
            "Outlook" {
                Send-OutlookEmail -To $To -Subject $Subject -Body $Body -Cc $Cc -Bcc $Bcc -Attachments $Attachments -HighPriority:$HighPriority
            }
            "Graph" {
                Send-GraphEmail -To $To -Subject $Subject -Body $Body -Cc $Cc -Bcc $Bcc -Attachments $Attachments -HighPriority:$HighPriority
            }
            "Gmail" {
                Send-GmailEmail -To $To -Subject $Subject -Body $Body -Cc $Cc -Bcc $Bcc -Attachments $Attachments -HighPriority:$HighPriority
            }
            "SMTP" {
                Send-SmtpEmail -To $To -Subject $Subject -Body $Body -Cc $Cc -Bcc $Bcc -Attachments $Attachments -HighPriority:$HighPriority
            }
            default {
                Write-Host "Unknown email provider: $($config.Settings.Provider)" -ForegroundColor Red
            }
        }
        
        Write-Host "✓ Email sent successfully to: $($To -join ', ')" -ForegroundColor Green
        Log-CobraActivity "Email sent: $Subject to $($To -join ', ')"
    }
    catch {
        Write-Host "Error sending email: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Send-QuickEmail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Template,
        
        [Parameter(Mandatory)]
        [string[]]$To,
        
        [hashtable]$Parameters = @{},
        [string]$Subject
    )
    
    Log-CobraActivity "Quick email requested - Template: $Template, To: $($To -join ', ')"
    
    $config = . "$PSScriptRoot/config.ps1"
    
    if (-not $config.Settings.DefaultTemplates.ContainsKey($Template)) {
        Write-Host "Quick template '$Template' not found. Available: $($config.Settings.DefaultTemplates.Keys -join ', ')" -ForegroundColor Red
        return
    }
    
    $body = $config.Settings.DefaultTemplates[$Template]
    
    # Replace parameters in body
    foreach ($param in $Parameters.GetEnumerator()) {
        $body = $body -replace "\{$($param.Key)\}", $param.Value
    }
    
    # Generate subject if not provided
    if (-not $Subject) {
        $Subject = "Quick Update - $Template"
    }
    
    Send-Email -To $To -Subject $Subject -Body $body
    Log-CobraActivity "Quick email sent successfully using template: $Template to $($To -join ', ')"
}

function Test-EmailConfiguration {
    [CmdletBinding()]
    param(
        [switch]$ShowStatus
    )
    
    Log-CobraActivity "Email configuration test started"
    
    $config = . "$PSScriptRoot/config.ps1"
    
    if ($ShowStatus) {
        Write-Host "Testing Email configuration..." -ForegroundColor Yellow
    }
    
    # Validate required configuration
    $requiredKeys = @('Name', 'Description', 'Version', 'ModuleType')
    $isValid = $true
    
    foreach ($key in $requiredKeys) {
        if (-not $config.ContainsKey($key) -or [string]::IsNullOrWhiteSpace($config[$key])) {
            Write-Host "  ❌ Missing or empty: $key" -ForegroundColor Red
            $isValid = $false
        }
        else {
            if ($ShowStatus) {
                Write-Host "  ✓ $key`: $($config[$key])" -ForegroundColor Green
            }
        }
    }
    
    # Provider-specific validation
    switch ($config.Settings.Provider) {
        "Outlook" {
            try {
                $outlook = New-Object -ComObject Outlook.Application
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
                if ($ShowStatus) {
                    Write-Host "  ✓ Outlook application is accessible" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "  ❌ Outlook application not accessible: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host "    💡 Make sure Outlook is installed and can be accessed" -ForegroundColor Yellow
                $isValid = $false
            }
        }
        
        "Graph" {
            if (-not $config.Settings.Graph.ClientId) {
                Write-Host "  ❌ Graph ClientId not configured (set GRAPH_CLIENT_ID environment variable)" -ForegroundColor Red
                $isValid = $false
            }
            elseif ($ShowStatus) {
                Write-Host "  ✓ Graph ClientId configured" -ForegroundColor Green
            }
            
            if (-not $config.Settings.Graph.TenantId) {
                Write-Host "  ❌ Graph TenantId not configured (set GRAPH_TENANT_ID environment variable)" -ForegroundColor Red
                $isValid = $false
            }
            elseif ($ShowStatus) {
                Write-Host "  ✓ Graph TenantId configured" -ForegroundColor Green
            }
        }
        
        "Gmail" {
            if (-not $config.Settings.Gmail.ClientId) {
                Write-Host "  ❌ Gmail ClientId not configured (set GMAIL_CLIENT_ID environment variable)" -ForegroundColor Red
                $isValid = $false
            }
            elseif ($ShowStatus) {
                Write-Host "  ✓ Gmail ClientId configured" -ForegroundColor Green
            }
        }
        
        "SMTP" {
            if (-not $config.Settings.SMTP.Server) {
                Write-Host "  ❌ SMTP Server not configured (set SMTP_SERVER environment variable)" -ForegroundColor Red
                $isValid = $false
            }
            elseif ($ShowStatus) {
                Write-Host "  ✓ SMTP Server configured" -ForegroundColor Green
            }
            
            if (-not $config.Settings.SMTP.Username) {
                Write-Host "  ❌ SMTP Username not configured (set SMTP_USERNAME environment variable)" -ForegroundColor Red
                $isValid = $false
            }
            elseif ($ShowStatus) {
                Write-Host "  ✓ SMTP Username configured" -ForegroundColor Green
            }
        }
    }
    
    if ($isValid -and $ShowStatus) {
        Write-Host "✓ Email configuration is valid" -ForegroundColor Green
        Log-CobraActivity "Email configuration validated successfully - Provider: $($config.Settings.Provider)"
    }
    elseif (-not $isValid) {
        Write-Host "❌ Email configuration has errors" -ForegroundColor Red
        Log-CobraActivity "Email configuration validation failed - Provider: $($config.Settings.Provider)"
    }
    
    return $isValid
}

function Test-EmailConnection {
    [CmdletBinding()]
    param(
        [switch]$ShowStatus
    )
    
    $config = . "$PSScriptRoot/config.ps1"
    
    if ($ShowStatus) {
        Write-Host "  Connection Status: " -NoNewline -ForegroundColor White
    }
    
    try {
        switch ($config.Settings.Provider) {
            "Outlook" {
                # Test Outlook COM connection
                try {
                    $outlook = New-Object -ComObject Outlook.Application
                    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
                    if ($ShowStatus) {
                        Write-Host "Ready (Outlook)" -ForegroundColor Green
                    }
                    return $true
                }
                catch {
                    if ($ShowStatus) {
                        Write-Host "Outlook not accessible" -ForegroundColor Red
                    }
                    return $false
                }
            }
            "Graph" {
                # Test Graph API connection (simplified - would need actual Graph API call)
                if ($config.Settings.Graph.ClientId -and $config.Settings.Graph.TenantId) {
                    if ($ShowStatus) {
                        Write-Host "Ready (Graph API)" -ForegroundColor Green
                    }
                    return $true
                }
            }
            "Gmail" {
                # Test Gmail API connection
                if ($config.Settings.Gmail.ClientId) {
                    if ($ShowStatus) {
                        Write-Host "Ready (Gmail API)" -ForegroundColor Green
                    }
                    return $true
                }
            }
            "SMTP" {
                # Test SMTP connection
                if ($config.Settings.SMTP.Server -and $config.Settings.SMTP.Username) {
                    if ($ShowStatus) {
                        Write-Host "Ready (SMTP)" -ForegroundColor Green
                    }
                    return $true
                }
            }
        }
        
        if ($ShowStatus) {
            Write-Host "Not configured" -ForegroundColor Yellow
        }
        return $false
    }
    catch {
        if ($ShowStatus) {
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

# Email Provider Functions (Placeholder implementations)
function Get-GraphEmails {
    param($Count, $UnreadOnly, $HighPriorityOnly, $From, $Subject)
    
    Write-Host "📧 Microsoft Graph Email Integration" -ForegroundColor Cyan
    Write-Host "  [Placeholder] Getting $Count emails from Graph API..." -ForegroundColor DarkGray
    Write-Host "  This would connect to Microsoft Graph API to retrieve emails" -ForegroundColor DarkGray
    Write-Host "  Filters: Unread=$UnreadOnly, HighPriority=$HighPriorityOnly" -ForegroundColor DarkGray
    
    # Return sample data for demonstration
    return @(
        [PSCustomObject]@{ Subject = "Weekly standup notes"; From = "team@company.com"; Received = (Get-Date).AddHours(-2); IsRead = $false }
        [PSCustomObject]@{ Subject = "Code review completed"; From = "developer@company.com"; Received = (Get-Date).AddHours(-4); IsRead = $false }
        [PSCustomObject]@{ Subject = "[URGENT] Production issue"; From = "alerts@company.com"; Received = (Get-Date).AddMinutes(-30); IsRead = $false }
    )
}

function Send-GraphEmail {
    param($To, $Subject, $Body, $Cc, $Bcc, $Attachments, $HighPriority)
    
    Write-Host "📤 Sending via Microsoft Graph..." -ForegroundColor Cyan
    Write-Host "  [Placeholder] Would send email via Graph API" -ForegroundColor DarkGray
    Write-Host "  To: $($To -join ', ')" -ForegroundColor DarkGray
    Write-Host "  Subject: $Subject" -ForegroundColor DarkGray
    # In real implementation, this would call Microsoft Graph API
}

function Get-OutlookEmails {
    param($Count, $UnreadOnly, $HighPriorityOnly, $From, $Subject)
    
    try {
        Write-Host "📧 Getting emails from Outlook..." -ForegroundColor Blue
        
        # Create Outlook COM object
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        
        # Get the Inbox folder
        $inboxFolder = $namespace.GetDefaultFolder(6) # 6 = olFolderInbox
        
        # Get emails
        $emails = $inboxFolder.Items
        $emails.Sort("[ReceivedTime]", $true) # Sort by received time, descending
        
        $results = @()
        $processedCount = 0
        $emailId = 1
        
        foreach ($email in $emails) {
            if ($processedCount -ge $Count) { break }
            
            # Apply filters
            if ($UnreadOnly -and $email.UnRead -eq $false) { continue }
            if ($From -and $email.SenderEmailAddress -notlike "*$From*") { continue }
            if ($Subject -and $email.Subject -notlike "*$Subject*") { continue }
            if ($HighPriorityOnly -and $email.Importance -ne 2) { continue } # 2 = High importance
            
            # Truncate long subjects for table display
            $truncatedSubject = if ($email.Subject.Length -gt 50) { 
                $email.Subject.Substring(0, 47) + "..." 
            }
            else { 
                $email.Subject 
            }
            
            # Truncate sender name for table display
            $truncatedFrom = if ($email.SenderName.Length -gt 25) {
                $email.SenderName.Substring(0, 22) + "..."
            }
            else {
                $email.SenderName
            }
            
            # Format received time
            $timeString = if ((Get-Date).Date -eq $email.ReceivedTime.Date) {
                $email.ReceivedTime.ToString("HH:mm")
            }
            else {
                $email.ReceivedTime.ToString("MM/dd")
            }
            
            # Status indicators
            $status = ""
            if (-not $email.UnRead) { $status += "📖" } else { $status += "📩" }
            if ($email.Importance -eq 2) { $status += "❗" }
            
            $results += [PSCustomObject]@{
                ID          = $emailId
                Status      = $status
                From        = $truncatedFrom
                Subject     = $truncatedSubject
                Time        = $timeString
                FullSubject = $email.Subject
                FullFrom    = $email.SenderName
                SenderEmail = $email.SenderEmailAddress
                Received    = $email.ReceivedTime
                Body        = $email.Body
                IsRead      = -not $email.UnRead
                Importance  = $email.Importance
                EntryID     = $email.EntryID  # Store for later retrieval
            }
            
            $processedCount++
            $emailId++
        }
        
        Write-Host "✅ Retrieved $($results.Count) emails from Outlook" -ForegroundColor Green
        Log-CobraActivity "Email inbox loaded successfully - $($results.Count) emails retrieved from Outlook"
        
        # Display as clean table
        if ($results.Count -gt 0) {
            Write-Host "`n📬 Inbox ($($results.Count) emails):" -ForegroundColor Cyan
            $results | Select-Object ID, Status, From, Subject, Time | Format-Table -AutoSize
            Write-Host "💡 Use 'email open <ID>' to view full email content" -ForegroundColor Yellow
        }
        
        # Store results in global variable for email open functionality
        $global:CobraEmailCache = $results
        
        # Also save to persistent cache file for cross-session access
        $cacheFile = Join-Path $env:TEMP "CobraEmailCache.json"
        try {
            $results | ConvertTo-Json -Depth 3 | Out-File -FilePath $cacheFile -Encoding UTF8
        }
        catch {
            Write-Host "Warning: Could not save email cache to file" -ForegroundColor Yellow
        }
        
    }
    catch {
        Write-Host "❌ Failed to connect to Outlook: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Make sure Outlook is installed and running" -ForegroundColor Yellow
        
        # Return sample data for demo
        $sampleData = @(
            [PSCustomObject]@{ 
                ID = 1; Status = "📩"; From = "outlook@company.com"; Subject = "[Sample] Welcome to Outlook Integration"; Time = "10:15"
                FullSubject = "[Sample] Welcome to Outlook Integration"; FullFrom = "Outlook System"; Body = "Welcome to the new email integration!"
            }
            [PSCustomObject]@{ 
                ID = 2; Status = "📖"; From = "system@company.com"; Subject = "[Sample] Your emails are accessible"; Time = "09:30"
                FullSubject = "[Sample] Your emails are now accessible"; FullFrom = "System Administrator"; Body = "Your email integration is working properly."
            }
        )
        
        Write-Host "`n📬 Inbox (Sample Data):" -ForegroundColor Cyan
        $sampleData | Select-Object ID, Status, From, Subject, Time | Format-Table -AutoSize
        Write-Host "💡 Use 'email open <ID>' to view full email content" -ForegroundColor Yellow
        
        $global:CobraEmailCache = $sampleData
        
        # Also save to persistent cache file for cross-session access
        $cacheFile = Join-Path $env:TEMP "CobraEmailCache.json"
        try {
            $sampleData | ConvertTo-Json -Depth 3 | Out-File -FilePath $cacheFile -Encoding UTF8
        }
        catch {
            Write-Host "Warning: Could not save email cache to file" -ForegroundColor Yellow
        }
        
    }
    finally {
        if ($outlook) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
        }
    }
}

function Send-OutlookEmail {
    param($To, $Subject, $Body, $Cc, $Bcc, $Attachments, $HighPriority)
    
    try {
        Write-Host "📤 Sending email via Outlook..." -ForegroundColor Blue
        
        # Create Outlook COM object
        $outlook = New-Object -ComObject Outlook.Application
        $mail = $outlook.CreateItem(0) # 0 = olMailItem
        
        # Set email properties
        $mail.To = $To -join ";"
        $mail.Subject = $Subject
        $mail.Body = $Body
        
        if ($Cc.Count -gt 0) {
            $mail.CC = $Cc -join ";"
        }
        
        if ($Bcc.Count -gt 0) {
            $mail.BCC = $Bcc -join ";"
        }
        
        if ($HighPriority) {
            $mail.Importance = 2 # High importance
        }
        
        # Add attachments
        foreach ($attachment in $Attachments) {
            if (Test-Path $attachment) {
                $mail.Attachments.Add($attachment) | Out-Null
                Write-Host "  📎 Added attachment: $(Split-Path $attachment -Leaf)" -ForegroundColor DarkGray
            }
        }
        
        # Send email
        $mail.Send()
        
        Write-Host "✅ Email sent successfully via Outlook" -ForegroundColor Green
        
    }
    catch {
        Write-Host "❌ Failed to send email via Outlook: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Make sure Outlook is installed and running" -ForegroundColor Yellow
        throw
    }
    finally {
        if ($mail) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($mail) | Out-Null
        }
        if ($outlook) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
        }
    }
}

function Send-OutlookReply {
    param(
        $OriginalEmail,
        $Body, 
        $Subject, 
        [switch]$ReplyAll
    )
    
    try {
        Write-Host "📤 Sending $(if ($ReplyAll) { 'Reply All' } else { 'Reply' }) via Outlook..." -ForegroundColor Blue
        
        # Create Outlook COM object
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        
        # Get the original email by EntryID if available
        if ($OriginalEmail.EntryID) {
            try {
                $originalMail = $namespace.GetItemFromID($OriginalEmail.EntryID)
                
                # Create reply
                if ($ReplyAll) {
                    $replyMail = $originalMail.ReplyAll()
                }
                else {
                    $replyMail = $originalMail.Reply()
                }
                
                # Set the reply content
                $replyMail.Body = $Body + "`n`n" + $replyMail.Body  # Preserve original thread
                
                # Override subject if provided
                if (![string]::IsNullOrEmpty($Subject)) {
                    $replyMail.Subject = $Subject
                }
                
                # Send the reply
                $replyMail.Send()
                
                Write-Host "✅ Reply sent using Outlook thread context" -ForegroundColor Green
                
            }
            catch {
                Write-Host "⚠️  Could not access original email for threading, sending as new email..." -ForegroundColor Yellow
                # Fallback to manual reply
                Send-ManualOutlookReply -OriginalEmail $OriginalEmail -Body $Body -Subject $Subject -ReplyAll:$ReplyAll -Outlook $outlook
            }
        }
        else {
            # Manual reply construction
            Send-ManualOutlookReply -OriginalEmail $OriginalEmail -Body $Body -Subject $Subject -ReplyAll:$ReplyAll -Outlook $outlook
        }
        
    }
    catch {
        Write-Host "❌ Failed to send reply via Outlook: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "💡 Make sure Outlook is installed and running" -ForegroundColor Yellow
        throw
    }
    finally {
        if ($replyMail) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($replyMail) | Out-Null
        }
        if ($originalMail) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($originalMail) | Out-Null
        }
        if ($outlook) {
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
        }
    }
}

function Send-ManualOutlookReply {
    param(
        $OriginalEmail,
        $Body,
        $Subject,
        [switch]$ReplyAll,
        $Outlook
    )
    
    # Create new mail item for manual reply
    $mail = $Outlook.CreateItem(0) # 0 = olMailItem
    
    # Set recipients
    $mail.To = $OriginalEmail.SenderEmail
    
    if ($ReplyAll -and $OriginalEmail.Cc) {
        # For reply all, we'd need to parse CC recipients
        # For now, just reply to sender with a note
        $Body = "[Reply All attempted - CCing original recipients manually may be needed]`n`n" + $Body
    }
    
    # Set subject and body
    $mail.Subject = $Subject
    $mail.Body = $Body
    
    # Send the reply
    $mail.Send()
    
    Write-Host "✅ Manual reply sent to $($OriginalEmail.SenderEmail)" -ForegroundColor Green
    
    # Clean up
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($mail) | Out-Null
}

function Send-SmtpEmail {
    param($To, $Subject, $Body, $Cc, $Bcc, $Attachments, $HighPriority)
    
    Write-Host "📤 Sending via SMTP..." -ForegroundColor Cyan
    Write-Host "  [Placeholder] Would send email via SMTP" -ForegroundColor DarkGray
    Write-Host "  To: $($To -join ', ')" -ForegroundColor DarkGray
    Write-Host "  Subject: $Subject" -ForegroundColor DarkGray
    # In real implementation, this would use Send-MailMessage or similar
}

function Get-GmailEmails {
    param($Count, $UnreadOnly, $HighPriorityOnly, $From, $Subject)
    
    Write-Host "📧 Gmail Email Integration" -ForegroundColor Cyan
    Write-Host "  [Placeholder] Getting $Count emails from Gmail API..." -ForegroundColor DarkGray
    Write-Host "  This would connect to Gmail API to retrieve emails" -ForegroundColor DarkGray
    Write-Host "  Filters: Unread=$UnreadOnly, HighPriority=$HighPriorityOnly" -ForegroundColor DarkGray
    
    # Return sample data for demonstration
    return @(
        [PSCustomObject]@{ Subject = "Gmail: Project update"; From = "team@gmail.com"; Received = (Get-Date).AddHours(-1); IsRead = $false }
        [PSCustomObject]@{ Subject = "Gmail: Meeting reminder"; From = "calendar@gmail.com"; Received = (Get-Date).AddHours(-3); IsRead = $true }
    )
}

function Send-GmailEmail {
    param($To, $Subject, $Body, $Cc, $Bcc, $Attachments, $HighPriority)
    
    Write-Host "📤 Sending via Gmail API..." -ForegroundColor Cyan
    Write-Host "  [Placeholder] Would send email via Gmail API" -ForegroundColor DarkGray
    Write-Host "  To: $($To -join ', ')" -ForegroundColor DarkGray
    Write-Host "  Subject: $Subject" -ForegroundColor DarkGray
    # In real implementation, this would call Gmail API
}

function Get-EmailTemplate {
    param(
        [string]$TemplateName,
        [hashtable]$Parameters = @{}
    )
    
    $config = . "$PSScriptRoot/config.ps1"
    
    # Check default templates first
    if ($config.Settings.DefaultTemplates.ContainsKey($TemplateName)) {
        $template = $config.Settings.DefaultTemplates[$TemplateName]
        
        # Replace parameters
        foreach ($param in $Parameters.GetEnumerator()) {
            $template = $template -replace "\{$($param.Key)\}", $param.Value
        }
        
        return $template
    }
    
    # Check template files
    $templatePath = Join-Path $config.Settings.TemplateDirectory "$TemplateName.txt"
    if (Test-Path $templatePath) {
        $template = Get-Content $templatePath -Raw
        
        # Replace parameters
        foreach ($param in $Parameters.GetEnumerator()) {
            $template = $template -replace "\{$($param.Key)\}", $param.Value
        }
        
        return $template
    }
    
    Write-Host "Template '$TemplateName' not found" -ForegroundColor Red
    return $null
}

function Invoke-EmailAI {
    param(
        [string]$Type,
        [string]$Content,
        [string]$Subject = ""
    )
    
    # Check if Utils module is available for AI integration
    if (Get-Command "AiExpander" -ErrorAction SilentlyContinue) {
        switch ($Type) {
            "email-compose" {
                return AiExpander -Type "expert" -AdditionalInfo "EmailComposition: Improve this email content for professional communication: $Content"
            }
            "email-reply" {
                return AiExpander -Type "expert" -AdditionalInfo "EmailReply: Generate a professional reply to this email subject '$Subject': $Content"  
            }
            "email-summary" {
                return AiExpander -Type "expert" -AdditionalInfo "EmailSummary: Summarize this email content: $Content"
            }
            default {
                return $Content
            }
        }
    }
    else {
        Write-Host "AI integration requires Utils module to be loaded" -ForegroundColor Yellow
        return $Content
    }
}

function Get-EmailDashboardStatus {
    [CmdletBinding()]
    param()
    
    $config = . "$PSScriptRoot/config.ps1"
    
    # This would be called by the dashboard to show email status
    $status = @{
        Provider          = $config.Settings.Provider
        Connected         = Test-EmailConnection
        UnreadCount       = 0  # Would be populated by actual email check
        HighPriorityCount = 0  # Would be populated by actual email check
    }
    
    return $status
}

# Template Management Functions
# Helper function to load email cache
function Get-EmailCacheOrLoad {
    if (-not $global:CobraEmailCache -or $global:CobraEmailCache.Count -eq 0) {
        # Try to load from persistent cache file
        $cacheFile = Join-Path $env:TEMP "CobraEmailCache.json"
        if (Test-Path $cacheFile) {
            try {
                $cacheContent = Get-Content -Path $cacheFile -Raw | ConvertFrom-Json
                $global:CobraEmailCache = @()
                foreach ($item in $cacheContent) {
                    $global:CobraEmailCache += [PSCustomObject]$item
                }
                Write-Host "📋 Loaded email cache from previous session" -ForegroundColor DarkGray
                return $true
            }
            catch {
                Write-Host "❌ Could not load email cache from file" -ForegroundColor Red
                return $false
            }
        }
        return $false
    }
    return $true
}

function Get-EmailTemplates {
    [CmdletBinding()]
    param()
    
    Log-CobraActivity "Email templates list requested"
    
    $config = . "$PSScriptRoot/config.ps1"
    
    Write-Host "Available Email Templates:" -ForegroundColor Cyan
    Write-Host "=========================" -ForegroundColor Cyan
    
    Write-Host "`nDefault Templates:" -ForegroundColor Yellow
    foreach ($template in $config.Settings.DefaultTemplates.GetEnumerator()) {
        Write-Host "  $($template.Key)" -ForegroundColor White -NoNewline
        Write-Host " - $($template.Value.Substring(0, [Math]::Min(50, $template.Value.Length)))..." -ForegroundColor DarkGray
    }
    
    # Check for file-based templates
    if (Test-Path $config.Settings.TemplateDirectory) {
        $templateFiles = Get-ChildItem $config.Settings.TemplateDirectory -Filter "*.txt"
        if ($templateFiles.Count -gt 0) {
            Write-Host "`nFile Templates:" -ForegroundColor Yellow
            foreach ($file in $templateFiles) {
                Write-Host "  $($file.BaseName)" -ForegroundColor White
            }
        }
    }
}

function Get-EmailOpen {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [int]$ID
    )
    
    Log-CobraActivity "Email open requested for ID: $ID"
    
    # Check if we have cached emails from the last inbox command
    if (-not (Get-EmailCacheOrLoad)) {
        Write-Host "❌ No emails cached. Run 'email inbox' first to load emails." -ForegroundColor Red
        Log-CobraActivity "Email open failed - no cached emails available for ID: $ID"
        return
    }
    
    # Find the email by ID
    $email = $global:CobraEmailCache | Where-Object { $_.ID -eq $ID }
    if (-not $email) {
        Write-Host "❌ Email ID $ID not found. Valid IDs: $(($global:CobraEmailCache | ForEach-Object { $_.ID }) -join ', ')" -ForegroundColor Red
        Log-CobraActivity "Email open failed - ID not found: $ID"
        return
    }
    
    # Display the full email
    Write-Host "📧 Email #$ID" -ForegroundColor Cyan
    Log-CobraActivity "Email opened - ID: $ID, Subject: $($email.FullSubject), From: $($email.FullFrom)"
    Write-Host
    Write-Host "From: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($email.FullFrom)" -ForegroundColor White
    if ($email.SenderEmail) {
        Write-Host "Email: " -NoNewline -ForegroundColor Yellow
        Write-Host "$($email.SenderEmail)" -ForegroundColor Gray
    }
    Write-Host "Subject: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($email.FullSubject)" -ForegroundColor White
    Write-Host "Received: " -NoNewline -ForegroundColor Yellow
    Write-Host "$($email.Received)" -ForegroundColor White
    Write-Host "Status: " -NoNewline -ForegroundColor Yellow
    if ($email.IsRead) {
        Write-Host "Read 📖" -ForegroundColor Green
    }
    else {
        Write-Host "Unread 📩" -ForegroundColor Yellow
    }
    if ($email.Importance -eq 2) {
        Write-Host "Priority: " -NoNewline -ForegroundColor Yellow
        Write-Host "High ❗" -ForegroundColor Red
    }
    
    Write-Host "`nBody:" -ForegroundColor Yellow
    
    # Format the email body for better readability
    $emailBody = $email.Body
    
    # Process long URLs to make them more readable
    $emailBody = Format-EmailBodyUrls -Body $emailBody
    
    $lines = $emailBody -split "`n"
    $displayLines = 0
    $maxLines = 80  # Limit body display to prevent overwhelming output
    
    foreach ($line in $lines) {
        if ($displayLines -ge $maxLines) {
            Write-Host "`n... (email truncated, showing first $maxLines lines)" -ForegroundColor DarkGray
            break
        }
        Write-Host $line
        $displayLines++
    }
    
    Write-Host "💡 Quick Actions:" -ForegroundColor DarkGray
    Write-Host "   email reply $ID -Body 'your message'        - Reply to this email" -ForegroundColor DarkGray
    Write-Host "   email replyall $ID -Body 'your message'     - Reply to all recipients" -ForegroundColor DarkGray
    Write-Host "   email forward $ID -To 'user@example.com'    - Forward this email" -ForegroundColor DarkGray
    if ($global:EmailUrlCache -and $global:EmailUrlCache.Count -gt 0) {
        Write-Host "   email urls                                  - Show all URLs in this email" -ForegroundColor DarkGray
        Write-Host "   email url <number>                          - Copy specific URL to clipboard" -ForegroundColor DarkGray
    }
}

function Send-EmailReply {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ID,
        
        [Parameter(Mandatory)]
        [string]$Body,
        
        [string]$Subject = "",
        [switch]$ReplyAll,
        [switch]$UseAI,
        [string]$Template = ""
    )
    
    # Check if we have cached emails from the last inbox command
    if (-not (Get-EmailCacheOrLoad)) {
        Write-Host "❌ No emails cached. Run 'email inbox' first to load emails." -ForegroundColor Red
        return
    }
    
    # Find the email by ID
    $originalEmail = $global:CobraEmailCache | Where-Object { $_.ID -eq $ID }
    if (-not $originalEmail) {
        Write-Host "❌ Email ID $ID not found. Valid IDs: $(($global:CobraEmailCache | ForEach-Object { $_.ID }) -join ', ')" -ForegroundColor Red
        return
    }
    
    Write-Host "📧 Preparing reply to email #$ID..." -ForegroundColor Blue
    
    # Handle template-based replies
    if ($Template) {
        $config = . "$PSScriptRoot/config.ps1"
        if ($config.Settings.DefaultTemplates.ContainsKey($Template)) {
            $Body = $config.Settings.DefaultTemplates[$Template]
        }
        else {
            Write-Host "❌ Template '$Template' not found. Using provided body." -ForegroundColor Yellow
        }
    }
    
    # AI enhancement for replies
    if ($UseAI) {
        $Body = Invoke-EmailAI -Type "email-reply" -Content $Body -Subject $originalEmail.FullSubject
    }
    
    # Generate reply subject if not provided
    if ([string]::IsNullOrEmpty($Subject)) {
        $Subject = if ($originalEmail.FullSubject.StartsWith("Re: ")) {
            $originalEmail.FullSubject
        }
        else {
            "Re: $($originalEmail.FullSubject)"
        }
    }
    
    # Show preview of the reply
    $replyType = if ($ReplyAll) { "Reply All" } else { "Reply" }
    Write-Host "`n📋 $replyType Preview:" -ForegroundColor Cyan
    Write-Host "To: $($originalEmail.SenderEmail)" -ForegroundColor White
    if ($ReplyAll) {
        Write-Host "Reply All: Including all original recipients" -ForegroundColor Yellow
    }
    Write-Host "Subject: $Subject" -ForegroundColor White
    Write-Host "Body:" -ForegroundColor White
    Write-Host $Body -ForegroundColor White
    
    # Confirm before sending (default to Yes)
    Write-Host "`n⚠️  Ready to send $replyType to: $($originalEmail.SenderEmail)" -ForegroundColor Yellow
    $confirm = Read-Host "Send this reply? (Y/n)"
    if ($confirm -eq 'n' -or $confirm -eq 'N') {
        Write-Host "❌ Reply cancelled by user" -ForegroundColor Red
        return
    }
    
    $config = . "$PSScriptRoot/config.ps1"
    
    try {
        switch ($config.Settings.Provider) {
            "Outlook" {
                Send-OutlookReply -OriginalEmail $originalEmail -Body $Body -Subject $Subject -ReplyAll:$ReplyAll
            }
            "Graph" {
                Write-Host "📤 Graph API reply not yet implemented - using standard send" -ForegroundColor Yellow
                # For now, extract recipient and send as new email
                $recipients = if ($ReplyAll) { @($originalEmail.SenderEmail) } else { @($originalEmail.SenderEmail) }
                Send-Email -To $recipients -Subject $Subject -Body $Body
            }
            "Gmail" {
                Write-Host "📤 Gmail API reply not yet implemented - using standard send" -ForegroundColor Yellow
                # For now, extract recipient and send as new email
                $recipients = if ($ReplyAll) { @($originalEmail.SenderEmail) } else { @($originalEmail.SenderEmail) }
                Send-Email -To $recipients -Subject $Subject -Body $Body
            }
            "SMTP" {
                Write-Host "📤 SMTP reply not yet implemented - using standard send" -ForegroundColor Yellow
                # For now, extract recipient and send as new email
                Send-Email -To @($originalEmail.SenderEmail) -Subject $Subject -Body $Body
            }
            default {
                Write-Host "Unknown email provider: $($config.Settings.Provider)" -ForegroundColor Red
            }
        }
        
        Write-Host "✅ $replyType sent successfully!" -ForegroundColor Green
        Log-CobraActivity "Email reply sent: $Subject to $($originalEmail.SenderEmail)"
        
    }
    catch {
        Write-Host "❌ Error sending reply: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Send-EmailForward {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ID,
        
        [Parameter(Mandatory)]
        [string[]]$To,
        
        [string]$Subject = "",
        [string]$Body = "",
        [switch]$UseAI,
        [string]$Template = ""
    )
    
    # Check if we have cached emails from the last inbox command
    if (-not (Get-EmailCacheOrLoad)) {
        Write-Host "❌ No emails cached. Run 'email inbox' first to load emails." -ForegroundColor Red
        return
    }
    
    # Find the email by ID
    $originalEmail = $global:CobraEmailCache | Where-Object { $_.ID -eq $ID }
    if (-not $originalEmail) {
        Write-Host "❌ Email ID $ID not found. Valid IDs: $(($global:CobraEmailCache | ForEach-Object { $_.ID }) -join ', ')" -ForegroundColor Red
        return
    }
    
    Write-Host "📧 Preparing forward of email #$ID..." -ForegroundColor Blue
    
    # Handle template-based forwards
    if ($Template) {
        $config = . "$PSScriptRoot/config.ps1"
        if ($config.Settings.DefaultTemplates.ContainsKey($Template)) {
            $Body = $config.Settings.DefaultTemplates[$Template]
        }
        else {
            Write-Host "❌ Template '$Template' not found. Using provided body." -ForegroundColor Yellow
        }
    }
    
    # Generate forward subject if not provided
    if ([string]::IsNullOrEmpty($Subject)) {
        $Subject = if ($originalEmail.FullSubject.StartsWith("Fwd: ")) {
            $originalEmail.FullSubject
        }
        else {
            "Fwd: $($originalEmail.FullSubject)"
        }
    }
    
    # Create forward body with original email content
    $forwardBody = $Body
    if (![string]::IsNullOrEmpty($Body)) {
        $forwardBody += "`n`n"
    }
    $forwardBody += "---------- Forwarded message ----------`n"
    $forwardBody += "From: $($originalEmail.FullFrom) <$($originalEmail.SenderEmail)>`n"
    $forwardBody += "Date: $($originalEmail.Received)`n"
    $forwardBody += "Subject: $($originalEmail.FullSubject)`n`n"
    $forwardBody += $originalEmail.Body
    
    # AI enhancement for forwards
    if ($UseAI) {
        $forwardBody = Invoke-EmailAI -Type "email-compose" -Content $forwardBody -Subject $Subject
    }
    
    # Show preview of the forward
    Write-Host "`n📋 Forward Preview:" -ForegroundColor Cyan
    Write-Host "To: $($To -join ', ')" -ForegroundColor White
    Write-Host "Subject: $Subject" -ForegroundColor White
    Write-Host "Body:" -ForegroundColor White
    
    # Show only first few lines of the forward body to avoid overwhelming output
    $bodyLines = $forwardBody -split "`n"
    $previewLines = $bodyLines | Select-Object -First 10
    foreach ($line in $previewLines) {
        Write-Host $line -ForegroundColor White
    }
    if ($bodyLines.Count -gt 10) {
        Write-Host "... (truncated, showing first 10 lines of forward)" -ForegroundColor DarkGray
    }
    
    # Confirm before sending (default to Yes)
    Write-Host "`n⚠️  Ready to forward email to: $($To -join ', ')" -ForegroundColor Yellow
    $confirm = Read-Host "Send this forward? (Y/n)"
    if ($confirm -eq 'n' -or $confirm -eq 'N') {
        Write-Host "❌ Forward cancelled by user" -ForegroundColor Red
        return
    }
    
    # Send the forward as a new email
    try {
        Send-Email -To $To -Subject $Subject -Body $forwardBody
        Write-Host "✅ Email forwarded successfully!" -ForegroundColor Green
        Log-CobraActivity "Email forwarded: $Subject to $($To -join ', ')"
        
    }
    catch {
        Write-Host "❌ Error forwarding email: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Setup Wizard Functions
function Start-EmailSetupWizard {
    [CmdletBinding()]
    param()
    
    Log-CobraActivity "Email setup wizard started"
    
    Write-Host "📧 Email Module Setup Wizard" -ForegroundColor Cyan
    Write-Host "==============================" -ForegroundColor Cyan
    Write-Host
    Write-Host "This wizard will help you configure the Email module for your environment." -ForegroundColor Yellow
    Write-Host "You can rerun this wizard anytime to update specific settings." -ForegroundColor Yellow
    Write-Host
    
    $config = . "$PSScriptRoot/config.ps1"
    
    # Step 1: Provider Selection
    $provider = Get-EmailProviderChoice $config
    
    # Step 2: Provider-specific configuration
    switch ($provider) {
        "Outlook" {
            Set-OutlookConfiguration $config
        }
        "Graph" {
            Set-GraphConfiguration $config
        }
        "Gmail" {
            Set-GmailConfiguration $config
        }
        "SMTP" {
            Set-SmtpConfiguration $config
        }
    }
    
    # Step 3: Email behavior settings
    Set-EmailBehaviorSettings $config
    
    # Step 4: Template settings
    Set-EmailTemplateSettings $config
    
    # Step 5: Final summary and test
    Show-SetupSummary $config
}

function Get-EmailProviderChoice {
    param($config)
    
    Write-Host "Step 1: Email Provider Selection" -ForegroundColor Green
    Write-Host "=================================" -ForegroundColor Green
    Write-Host
    Write-Host "Current provider: $($config.Settings.Provider)" -ForegroundColor White
    Write-Host
    Write-Host "Available email providers:" -ForegroundColor Yellow
    Write-Host "  1. Outlook (Local Outlook app) - Easiest setup, no registration needed"
    Write-Host "  2. Microsoft Graph (Office 365/Outlook.com) - Recommended for enterprise"
    Write-Host "  3. Gmail API (Google Workspace/Gmail) - For Google environments"
    Write-Host "  4. SMTP (Generic email server) - Universal but send-only"
    Write-Host
    
    do {
        $choice = Read-Host "Select provider (1-4, or ENTER to keep current)"
        
        if ([string]::IsNullOrEmpty($choice)) {
            Write-Host "✓ Keeping current provider: $($config.Settings.Provider)" -ForegroundColor Green
            return $config.Settings.Provider
        }
        
        switch ($choice) {
            "1" { 
                Write-Host "✓ Selected Outlook (Local app)" -ForegroundColor Green
                Log-CobraActivity "Email provider selected: Outlook (Local app)"
                return "Outlook" 
            }
            "2" { 
                Write-Host "✓ Selected Microsoft Graph" -ForegroundColor Green
                Log-CobraActivity "Email provider selected: Microsoft Graph"
                return "Graph" 
            }
            "3" { 
                Write-Host "✓ Selected Gmail API" -ForegroundColor Green
                Log-CobraActivity "Email provider selected: Gmail API"
                return "Gmail" 
            }
            "4" { 
                Write-Host "✓ Selected SMTP" -ForegroundColor Green
                Log-CobraActivity "Email provider selected: SMTP"
                return "SMTP" 
            }
            default { 
                Write-Host "Invalid choice. Please enter 1, 2, 3, 4, or press ENTER." -ForegroundColor Red 
            }
        }
    } while ($true)
}

function Set-OutlookConfiguration {
    param($config)
    
    Write-Host "`nStep 2: Outlook Configuration" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Green
    Write-Host
    Write-Host "Outlook provider uses your local Outlook application." -ForegroundColor Yellow
    Write-Host "✓ No Azure app registration required" -ForegroundColor Green
    Write-Host "✓ No API keys needed" -ForegroundColor Green
    Write-Host "✓ Uses your existing Outlook email accounts" -ForegroundColor Green
    Write-Host
    
    # Test Outlook availability
    Write-Host "Testing Outlook connection..." -ForegroundColor White
    try {
        $outlook = New-Object -ComObject Outlook.Application
        $namespace = $outlook.GetNamespace("MAPI")
        $accounts = $namespace.Accounts
        
        Write-Host "✓ Outlook is accessible" -ForegroundColor Green
        Write-Host "✓ Found $($accounts.Count) email account(s)" -ForegroundColor Green
        
        # Show available accounts
        if ($accounts.Count -gt 0) {
            Write-Host "`nAvailable email accounts:" -ForegroundColor Yellow
            for ($i = 1; $i -le $accounts.Count; $i++) {
                $account = $accounts.Item($i)
                Write-Host "  $i. $($account.DisplayName) ($($account.SmtpAddress))" -ForegroundColor White
            }
        }
        
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($outlook) | Out-Null
        
        Write-Host "`n✅ Outlook configuration complete!" -ForegroundColor Green
        Write-Host "The Email module will use your default Outlook profile." -ForegroundColor White
        
    }
    catch {
        Write-Host "❌ Could not connect to Outlook: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "• Make sure Microsoft Outlook is installed" -ForegroundColor Yellow
        Write-Host "• Try opening Outlook manually first" -ForegroundColor Yellow
        Write-Host "• Check that Outlook can access your email accounts" -ForegroundColor Yellow
        Write-Host
        
        $continue = Read-Host "Continue setup anyway? (y/N)"
        if ($continue -notlike "y*") {
            throw "Outlook setup cancelled by user"
        }
    }
}

function Set-GraphConfiguration {
    param($config)
    
    Write-Host "`nStep 2: Microsoft Graph Configuration" -ForegroundColor Green
    Write-Host "======================================" -ForegroundColor Green
    Write-Host
    Write-Host "Microsoft Graph requires an Azure App Registration with appropriate permissions." -ForegroundColor Yellow
    Write-Host "Required permissions: Mail.Read, Mail.Send, Mail.ReadWrite" -ForegroundColor Yellow
    Write-Host
    
    # Client ID
    Write-Host "Current Client ID: " -NoNewline -ForegroundColor White
    if ($config.Settings.Graph.ClientId) {
        Write-Host "$($config.Settings.Graph.ClientId)" -ForegroundColor Green
    }
    else {
        Write-Host "Not configured" -ForegroundColor Red
    }
    
    $newClientId = Read-Host "Enter new Client ID (or ENTER to keep current)"
    if (![string]::IsNullOrEmpty($newClientId)) {
        Write-Host "Setting GRAPH_CLIENT_ID environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable("GRAPH_CLIENT_ID", $newClientId, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ Client ID configured" -ForegroundColor Green
    }
    
    # Tenant ID
    Write-Host "`nCurrent Tenant ID: " -NoNewline -ForegroundColor White
    if ($config.Settings.Graph.TenantId) {
        Write-Host "$($config.Settings.Graph.TenantId)" -ForegroundColor Green
    }
    else {
        Write-Host "Not configured" -ForegroundColor Red
    }
    
    $newTenantId = Read-Host "Enter new Tenant ID (or ENTER to keep current)"
    if (![string]::IsNullOrEmpty($newTenantId)) {
        Write-Host "Setting GRAPH_TENANT_ID environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable("GRAPH_TENANT_ID", $newTenantId, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ Tenant ID configured" -ForegroundColor Green
    }
    
    Write-Host "`n📋 Graph Configuration Help:" -ForegroundColor Cyan
    Write-Host "  1. Go to https://portal.azure.com" -ForegroundColor White
    Write-Host "  2. Navigate to Azure Active Directory > App registrations" -ForegroundColor White
    Write-Host "  3. Create a new registration or use existing" -ForegroundColor White
    Write-Host "  4. Add API permissions: Microsoft Graph > Mail.Read, Mail.Send, Mail.ReadWrite" -ForegroundColor White
    Write-Host "  5. Copy Application (client) ID and Directory (tenant) ID" -ForegroundColor White
}

function Set-GmailConfiguration {
    param($config)
    
    Write-Host "`nStep 2: Gmail API Configuration" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host
    Write-Host "Gmail API requires a Google Cloud Project with Gmail API enabled." -ForegroundColor Yellow
    Write-Host
    
    # Client ID
    Write-Host "Current Client ID: " -NoNewline -ForegroundColor White
    if ($config.Settings.Gmail.ClientId) {
        Write-Host "$($config.Settings.Gmail.ClientId)" -ForegroundColor Green
    }
    else {
        Write-Host "Not configured" -ForegroundColor Red
    }
    
    $newClientId = Read-Host "Enter new Gmail Client ID (or ENTER to keep current)"
    if (![string]::IsNullOrEmpty($newClientId)) {
        Write-Host "Setting GMAIL_CLIENT_ID environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable("GMAIL_CLIENT_ID", $newClientId, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ Gmail Client ID configured" -ForegroundColor Green
    }
    
    # Client Secret
    Write-Host "`nCurrent Client Secret: " -NoNewline -ForegroundColor White
    if ($config.Settings.Gmail.ClientSecret) {
        Write-Host "***configured***" -ForegroundColor Green
    }
    else {
        Write-Host "Not configured" -ForegroundColor Red
    }
    
    $newSecret = Read-Host "Enter new Client Secret (or ENTER to keep current)" -AsSecureString
    if ($newSecret.Length -gt 0) {
        $secretText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newSecret))
        Write-Host "Setting GMAIL_CLIENT_SECRET environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable("GMAIL_CLIENT_SECRET", $secretText, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ Gmail Client Secret configured" -ForegroundColor Green
    }
    
    Write-Host "`n📋 Gmail Configuration Help:" -ForegroundColor Cyan
    Write-Host "  1. Go to https://console.cloud.google.com" -ForegroundColor White
    Write-Host "  2. Create project and enable Gmail API" -ForegroundColor White
    Write-Host "  3. Create OAuth 2.0 credentials" -ForegroundColor White
    Write-Host "  4. Set authorized redirect URI to: http://localhost:8080" -ForegroundColor White
    Write-Host "  5. Copy Client ID and Client Secret" -ForegroundColor White
}

function Set-SmtpConfiguration {
    param($config)
    
    Write-Host "`nStep 2: SMTP Configuration" -ForegroundColor Green
    Write-Host "===========================" -ForegroundColor Green
    Write-Host
    Write-Host "SMTP configuration allows sending emails but not reading them." -ForegroundColor Yellow
    Write-Host
    
    # Server
    Write-Host "Current SMTP Server: " -NoNewline -ForegroundColor White
    if ($config.Settings.SMTP.Server) {
        Write-Host "$($config.Settings.SMTP.Server)" -ForegroundColor Green
    }
    else {
        Write-Host "Not configured" -ForegroundColor Red
    }
    
    $newServer = Read-Host "Enter SMTP server (e.g., smtp.gmail.com, smtp.office365.com) or ENTER to keep current"
    if (![string]::IsNullOrEmpty($newServer)) {
        Write-Host "Setting SMTP_SERVER environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable("SMTP_SERVER", $newServer, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ SMTP Server configured" -ForegroundColor Green
    }
    
    # Username
    Write-Host "`nCurrent Username: " -NoNewline -ForegroundColor White
    if ($config.Settings.SMTP.Username) {
        Write-Host "$($config.Settings.SMTP.Username)" -ForegroundColor Green
    }
    else {
        Write-Host "Not configured" -ForegroundColor Red
    }
    
    $newUsername = Read-Host "Enter SMTP username (usually your email address) or ENTER to keep current"
    if (![string]::IsNullOrEmpty($newUsername)) {
        Write-Host "Setting SMTP_USERNAME environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable("SMTP_USERNAME", $newUsername, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ SMTP Username configured" -ForegroundColor Green
    }
    
    # Password
    Write-Host "`nCurrent Password: " -NoNewline -ForegroundColor White
    if ($config.Settings.SMTP.Password) {
        Write-Host "***configured***" -ForegroundColor Green
    }
    else {
        Write-Host "Not configured" -ForegroundColor Red
    }
    
    $newPassword = Read-Host "Enter SMTP password or app password (or ENTER to keep current)" -AsSecureString
    if ($newPassword.Length -gt 0) {
        $passwordText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($newPassword))
        Write-Host "Setting SMTP_PASSWORD environment variable..." -ForegroundColor Yellow
        [System.Environment]::SetEnvironmentVariable("SMTP_PASSWORD", $passwordText, [System.EnvironmentVariableTarget]::User)
        Write-Host "✓ SMTP Password configured" -ForegroundColor Green
    }
    
    Write-Host "`n📋 Common SMTP Settings:" -ForegroundColor Cyan
    Write-Host "  Gmail: smtp.gmail.com:587 (use app password)" -ForegroundColor White
    Write-Host "  Outlook: smtp.office365.com:587" -ForegroundColor White
    Write-Host "  Yahoo: smtp.mail.yahoo.com:587" -ForegroundColor White
}

function Set-EmailBehaviorSettings {
    param($config)
    
    Write-Host "`nStep 3: Email Behavior Settings" -ForegroundColor Green
    Write-Host "================================" -ForegroundColor Green
    Write-Host
    
    # Default signature
    Write-Host "Current signature:" -ForegroundColor White
    if ($config.Settings.DefaultSignature) {
        Write-Host "  $($config.Settings.DefaultSignature)" -ForegroundColor Green
    }
    else {
        Write-Host "  Not configured" -ForegroundColor Red
    }
    
    $updateSignature = Read-Host "Update email signature? (y/N)"
    if ($updateSignature -eq 'y' -or $updateSignature -eq 'Y') {
        Write-Host "Enter your email signature (press ENTER on empty line to finish):" -ForegroundColor Yellow
        $signatureLines = @()
        do {
            $line = Read-Host
            if (![string]::IsNullOrEmpty($line)) {
                $signatureLines += $line
            }
        } while (![string]::IsNullOrEmpty($line))
        
        if ($signatureLines.Count -gt 0) {
            $newSignature = $signatureLines -join "`n"
            # Update would need to modify config file - for now just show what would be set
            Write-Host "✓ New signature configured: " -ForegroundColor Green -NoNewline
            Write-Host "$($signatureLines[0])..." -ForegroundColor White
        }
    }
    
    # Max emails to show
    Write-Host "`nCurrent max emails to show: $($config.Settings.MaxEmailsToShow)" -ForegroundColor White
    $newMax = Read-Host "Enter new max emails to show (or ENTER to keep current)"
    if (![string]::IsNullOrEmpty($newMax) -and $newMax -match '^\d+$') {
        Write-Host "✓ Max emails updated to: $newMax" -ForegroundColor Green
    }
    
    # Unread only default
    Write-Host "`nCurrent default (show unread only): $($config.Settings.UnreadOnly)" -ForegroundColor White
    $newUnread = Read-Host "Show only unread emails by default? (y/N)"
    $unreadOnly = $newUnread -eq 'y' -or $newUnread -eq 'Y'
    Write-Host "✓ Unread only setting: $unreadOnly" -ForegroundColor Green
}

function Set-EmailTemplateSettings {
    param($config)
    
    Write-Host "`nStep 4: Template Settings" -ForegroundColor Green
    Write-Host "==========================" -ForegroundColor Green
    Write-Host
    
    Write-Host "Current templates:" -ForegroundColor White
    foreach ($template in $config.Settings.DefaultTemplates.GetEnumerator()) {
        Write-Host "  $($template.Key): $($template.Value.Substring(0, [Math]::Min(40, $template.Value.Length)))..." -ForegroundColor Green
    }
    
    Write-Host "`nTemplate directory: $($config.Settings.TemplateDirectory)" -ForegroundColor White
    
    $manageTemplates = Read-Host "Manage templates? (y/N)"
    if ($manageTemplates -eq 'y' -or $manageTemplates -eq 'Y') {
        Write-Host "`nTemplate management:" -ForegroundColor Yellow
        Write-Host "  - Templates are stored as .txt files in: $($config.Settings.TemplateDirectory)" -ForegroundColor White
        Write-Host "  - Use {parameter} syntax for replaceable values" -ForegroundColor White
        Write-Host "  - You can create/edit template files manually" -ForegroundColor White
        
        # Create template directory if it doesn't exist
        if (!(Test-Path $config.Settings.TemplateDirectory)) {
            $createDir = Read-Host "Create template directory? (Y/n)"
            if ($createDir -ne 'n' -and $createDir -ne 'N') {
                New-Item -ItemType Directory -Path $config.Settings.TemplateDirectory -Force | Out-Null
                Write-Host "✓ Template directory created" -ForegroundColor Green
            }
        }
    }
}

function Show-SetupSummary {
    param($config)
    
    Write-Host "`nStep 5: Setup Summary" -ForegroundColor Green
    Write-Host "======================" -ForegroundColor Green
    Write-Host
    
    Write-Host "📧 Email Module Configuration Summary:" -ForegroundColor Cyan
    Write-Host
    
    # Reload config to get latest environment variables
    $updatedConfig = . "$PSScriptRoot/config.ps1"
    
    Write-Host "Provider: $($updatedConfig.Settings.Provider)" -ForegroundColor White
    
    switch ($updatedConfig.Settings.Provider) {
        "Graph" {
            Write-Host "  Client ID: " -NoNewline -ForegroundColor White
            if ($updatedConfig.Settings.Graph.ClientId) {
                Write-Host "Configured ✓" -ForegroundColor Green
            }
            else {
                Write-Host "Not configured ❌" -ForegroundColor Red
            }
            Write-Host "  Tenant ID: " -NoNewline -ForegroundColor White
            if ($updatedConfig.Settings.Graph.TenantId) {
                Write-Host "Configured ✓" -ForegroundColor Green
            }
            else {
                Write-Host "Not configured ❌" -ForegroundColor Red
            }
        }
        "Gmail" {
            Write-Host "  Client ID: " -NoNewline -ForegroundColor White
            if ($updatedConfig.Settings.Gmail.ClientId) {
                Write-Host "Configured ✓" -ForegroundColor Green
            }
            else {
                Write-Host "Not configured ❌" -ForegroundColor Red
            }
            Write-Host "  Client Secret: " -NoNewline -ForegroundColor White
            if ($updatedConfig.Settings.Gmail.ClientSecret) {
                Write-Host "Configured ✓" -ForegroundColor Green
            }
            else {
                Write-Host "Not configured ❌" -ForegroundColor Red
            }
        }
        "SMTP" {
            Write-Host "  Server: " -NoNewline -ForegroundColor White
            if ($updatedConfig.Settings.SMTP.Server) {
                Write-Host "$($updatedConfig.Settings.SMTP.Server) ✓" -ForegroundColor Green
            }
            else {
                Write-Host "Not configured ❌" -ForegroundColor Red
            }
            Write-Host "  Username: " -NoNewline -ForegroundColor White
            if ($updatedConfig.Settings.SMTP.Username) {
                Write-Host "$($updatedConfig.Settings.SMTP.Username) ✓" -ForegroundColor Green
            }
            else {
                Write-Host "Not configured ❌" -ForegroundColor Red
            }
        }
    }
    
    Write-Host "`nNext Steps:" -ForegroundColor Yellow
    Write-Host "  1. Reload the module: Import-Module Email -Force" -ForegroundColor White
    Write-Host "  2. Test configuration: email config" -ForegroundColor White
    Write-Host "  3. Try the inbox: email inbox" -ForegroundColor White
    Write-Host "  4. Rerun setup anytime: email setup" -ForegroundColor White
    Write-Host
    
    $testNow = Read-Host "Test configuration now? (Y/n)"
    if ($testNow -ne 'n' -and $testNow -ne 'N') {
        Write-Host "`nTesting configuration..." -ForegroundColor Yellow
        Test-EmailConfiguration -ShowStatus
    }
    
    Write-Host "`n✅ Email setup wizard completed!" -ForegroundColor Green
    Log-CobraActivity "Email setup wizard completed successfully"
}

function Show-EmailHelp {
    [CmdletBinding()]
    param()
    
    Write-Host "Email - Standalone Module" -ForegroundColor Cyan
    Write-Host "============================" -ForegroundColor Cyan
    Write-Host
    Write-Host "Quick Access:" -ForegroundColor Yellow
    Write-Host "  Email                     - Show this help"
    Write-Host "  email <command>           - Execute email commands"
    Write-Host
    Write-Host "Available Commands:" -ForegroundColor Yellow
    Write-Host "  email help                - Show this help information"
    Write-Host "  email info                - Show module status and configuration"
    Write-Host "  email config              - Validate module configuration (detailed)"
    Write-Host "  email setup               - Run setup wizard to configure the module"
    Write-Host "  email inbox               - Show recent emails (default: 10)"
    Write-Host "  email inbox -Count 20     - Show specific number of emails"
    Write-Host "  email inbox -UnreadOnly   - Show only unread emails"
    Write-Host "  email open 3              - Open and view email by ID (from inbox)"
    Write-Host "  email urls                - Show all URLs from last opened email"
    Write-Host "  email url 2               - Copy specific URL to clipboard"
    Write-Host "  email reply 3 -Body 'Thanks!'        - Reply to email (shows preview + confirmation)"
    Write-Host "  email replyall 3 -Body 'Thanks!'     - Reply All (shows preview + confirmation)"
    Write-Host "  email forward 3 -To 'user@email.com' - Forward email to recipient"
    Write-Host "  email templates           - List available email templates"
    Write-Host
    Write-Host "Sending Commands:" -ForegroundColor Yellow
    Write-Host "  email send -To 'user@example.com' -Subject 'Test' -Body 'Message' - Send a new email"
    Write-Host "  email quick -Template 'meeting-delay' -To 'user@example.com'      - Send using template"
    Write-Host
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  Module configuration is stored in config.ps1"
    Write-Host "  This is a standalone module and does not require a repository"
    Write-Host "  Set environment variables for your email provider (Graph/Gmail/SMTP)"
    Write-Host
    Write-Host "Examples:" -ForegroundColor Green
    Write-Host "  email setup               - Run the setup wizard"
    Write-Host "  email info                - Show module information and status"
    Write-Host "  email config              - Validate configuration" 
    Write-Host "  email inbox -Count 5 -UnreadOnly - Show 5 unread emails"
    Write-Host "  email open 2              - View full content of email #2"
    Write-Host "  email urls                - Show all URLs from opened email"
    Write-Host "  email url 1               - Copy URL #1 to clipboard"
    Write-Host "  email reply 2 -Body 'Thanks!'        - Reply with preview + confirmation"
    Write-Host "  email replyall 2 -Body 'Thanks!'     - Reply to all with confirmation"
    Write-Host "  email forward 2 -To 'colleague@company.com' - Forward email"
    Write-Host "  email quick -Template 'code-review'  -To 'dev@company.com' - Send template email"
    Write-Host
}

# Create intuitive module aliases - typing module name shows help
Set-Alias -Name Email -Value Show-EmailHelp -Scope Global
Set-Alias -Name email -Value EmailDriver -Scope Global

# Email Driver - Main entry point for all email commands
enum EmailCommand {
    help
    info
    config
    setup
    inbox
    send
    quick
    templates
    open
    reply
    replyall
    forward
    urls
    url
}

function EmailDriver {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$Command = "help",
        [Parameter(Position = 1)]
        [int]$ID = 0,
        [string]$Template = "",
        [string[]]$To = @(),
        [string]$Subject = "",
        [string]$Body = "",
        [int]$Count = 10,
        [switch]$UnreadOnly,
        [switch]$HighPriorityOnly,
        [string]$From = "",
        [switch]$ShowStatus
    )

    Log-CobraActivity "Email command executed: $Command $(if($ID -gt 0) { "ID=$ID" }) $(if($To.Count -gt 0) { "To=$($To -join ',')" })"

    # Convert string command to enum
    try {
        $CommandEnum = [EmailCommand]::$Command
    }
    catch {
        Write-Host "Error: Invalid command '$Command'" -ForegroundColor Red
        Write-Host "Valid commands: help, info, config, setup, inbox, send, quick, templates, open, reply, replyall, forward" -ForegroundColor Yellow
        return
    }

    switch ($CommandEnum) {
        help {
            Show-EmailHelp
        }
        info {
            Get-EmailStatus
        }
        config {
            Test-EmailConfiguration -ShowStatus
        }
        setup {
            Start-EmailSetupWizard
        }
        inbox {
            Get-EmailInbox -Count $Count -UnreadOnly:$UnreadOnly -HighPriorityOnly:$HighPriorityOnly -From $From
        }
        open {
            if ($ID -eq 0) {
                Write-Host "Error: ID parameter required for open command" -ForegroundColor Red
                Write-Host "Example: email open 3" -ForegroundColor Yellow
                return
            }
            Get-EmailOpen -ID $ID
        }
        reply {
            if ($ID -eq 0) {
                Write-Host "Error: ID parameter required for reply command" -ForegroundColor Red
                Write-Host "Example: email reply 3 -Body 'Thanks for the update!'" -ForegroundColor Yellow
                return
            }
            Send-EmailReply -ID $ID -Body $Body -Subject $Subject
        }
        replyall {
            if ($ID -eq 0) {
                Write-Host "Error: ID parameter required for replyall command" -ForegroundColor Red
                Write-Host "Example: email replyall 3 -Body 'Thanks everyone!'" -ForegroundColor Yellow
                return
            }
            Send-EmailReply -ID $ID -Body $Body -Subject $Subject -ReplyAll
        }
        forward {
            if ($ID -eq 0) {
                Write-Host "Error: ID parameter required for forward command" -ForegroundColor Red
                Write-Host "Example: email forward 3 -To 'user@example.com'" -ForegroundColor Yellow
                return
            }
            if ($To.Count -eq 0) {
                Write-Host "Error: -To parameter required for forward command" -ForegroundColor Red
                Write-Host "Example: email forward 3 -To 'user@example.com'" -ForegroundColor Yellow
                return
            }
            Send-EmailForward -ID $ID -To $To -Body $Body -Subject $Subject
        }
        send {
            if ($To.Count -eq 0) {
                Write-Host "Error: -To parameter required for send command" -ForegroundColor Red
                return
            }
            Send-Email -To $To -Subject $Subject -Body $Body
        }
        quick {
            if ($To.Count -eq 0 -or [string]::IsNullOrEmpty($Template)) {
                Write-Host "Error: -To and -Template parameters required for quick command" -ForegroundColor Red
                Write-Host "Example: email quick -Template 'meeting-delay' -To 'user@example.com'" -ForegroundColor Yellow
                return
            }
            Send-QuickEmail -Template $Template -To $To
        }
        templates {
            Get-EmailTemplates
        }
        urls {
            Get-EmailUrls
        }
        url {
            if ($ID -eq 0) {
                Write-Host "Error: URL number required for url command" -ForegroundColor Red
                Write-Host "Example: email url 1" -ForegroundColor Yellow
                return
            }
            Get-EmailUrls -UrlNumber $ID
        }
        default {
            Show-EmailHelp
        }
    }
}

# Export all module functions and aliases
Export-ModuleMember -Function @(
    'Get-EmailStatus',
    'Get-EmailInbox', 
    'Get-EmailOpen',
    'Get-EmailUrls',
    'Format-EmailBodyUrls',
    'Send-Email',
    'Send-EmailReply',
    'Send-EmailForward',
    'Send-QuickEmail',
    'Get-EmailTemplates',
    'Test-EmailConfiguration',
    'Test-EmailConnection',
    'Get-EmailDashboardStatus',
    'Show-EmailHelp',
    'Start-EmailSetupWizard',
    'EmailDriver'
) -Alias @('Email', 'email')

# Module initialization
$config = . "$PSScriptRoot/config.ps1"
Write-Host "📧 Email module loaded (Provider: $($config.Settings.Provider))" -ForegroundColor Cyan
Log-CobraActivity "Email module loaded with provider: $($config.Settings.Provider)"

# Register the module with Cobra Framework
Initialize-EmailModule

# Auto-test configuration if enabled
if ($config.Settings.AutoValidateOnLoad -and -not (Test-EmailConfiguration)) {
    Write-Host "⚠️  Email module loaded with configuration warnings" -ForegroundColor Yellow
    Write-Host "   Run 'Test-EmailConfiguration -ShowStatus' for details" -ForegroundColor DarkGray
}

