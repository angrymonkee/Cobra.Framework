$global:templatesManagementScriptLoaded = $true

# Dependencies:
# Load the core script if it hasn't been loaded yet
if (-not ($global:coreScriptLoaded)) {
    . "$($global:CobraConfig.CobraRoot)/Core.ps1"
}

Log-CobraActivity "Loading templates management scripts..."

# Initialize template directories on startup
function Initialize-TemplateDirectories {
    [CmdletBinding()]
    param()

    $templatePath = Join-Path $PSScriptRoot "Templates"
    
    $templatePaths = @(
        "$($templatePath)\module-templates"
        "$($templatePath)\function-snippets"
        "$($templatePath)\code-snippets"
        "$($templatePath)\personal"
        "$($templatePath)\team"
    )
    
    foreach ($path in $templatePaths) {
        if (-not (Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "Created template directory: $path" -ForegroundColor Green
        }
    }
}

# Core Template Management Functions
function Get-CobraTemplates {
    [CmdletBinding()]
    param(
        [string]$Category = "all",
        [string]$SearchTerm = "",
        [switch]$TeamOnly,
        [switch]$PersonalOnly
    )

    $templatePath = Join-Path $PSScriptRoot "Templates"
    $templates = @()
    
    if ($Category -eq "all" -or $Category -eq "module") {
        $moduleTemplates = Get-ChildItem "$templatePath\module-templates\*.json" -ErrorAction SilentlyContinue
        foreach ($template in $moduleTemplates) {
            try {
                $metadata = Get-Content $template.FullName | ConvertFrom-Json
                $templates += [PSCustomObject]@{
                    Name        = $template.BaseName
                    Type        = "module"
                    Description = $metadata.Description
                    Path        = $template.FullName
                    Author      = $metadata.Author
                    Created     = $template.CreationTime
                }
            }
            catch {
                # Handle malformed JSON gracefully
                $templates += [PSCustomObject]@{
                    Name        = $template.BaseName
                    Type        = "module"
                    Description = "Module template (unable to read metadata)"
                    Path        = $template.FullName
                    Author      = "Unknown"
                    Created     = $template.CreationTime
                }
            }
        }
    }
    
    if ($Category -eq "all" -or $Category -eq "function") {
        $functionTemplates = Get-ChildItem "$templatePath\function-snippets\*.ps1" -ErrorAction SilentlyContinue
        foreach ($template in $functionTemplates) {
            $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
            $description = if ($content -and $content -match "# Description: (.+)") { $matches[1] } else { "Function template" }
            $author = if ($content -and $content -match "# Author: (.+)") { $matches[1] } else { "Unknown" }
            
            $templates += [PSCustomObject]@{
                Name        = $template.BaseName
                Type        = "function"
                Description = $description
                Path        = $template.FullName
                Author      = $author
                Created     = $template.CreationTime
            }
        }
    }
    
    if ($Category -eq "all" -or $Category -eq "snippet") {
        $snippetTemplates = Get-ChildItem "$templatePath\code-snippets\*.ps1" -ErrorAction SilentlyContinue
        foreach ($template in $snippetTemplates) {
            $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
            $description = if ($content -and $content -match "# Description: (.+)") { $matches[1] } else { "Code snippet" }
            $author = if ($content -and $content -match "# Author: (.+)") { $matches[1] } else { "Unknown" }
            
            $templates += [PSCustomObject]@{
                Name        = $template.BaseName
                Type        = "snippet"
                Description = $description
                Path        = $template.FullName
                Author      = $author
                Created     = $template.CreationTime
            }
        }
    }
    
    # Apply search filter
    if ($SearchTerm) {
        $templates = $templates | Where-Object { 
            $_.Name -like "*$SearchTerm*" -or $_.Description -like "*$SearchTerm*" 
        }
    }
    
    return $templates | Sort-Object Type, Name
}

function New-CobraModuleFromTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,
        
        [Parameter(Mandatory)]
        [string]$ModuleName,
        
        [hashtable]$Parameters = @{}
    )
    
    $templatePath = Join-Path $PSScriptRoot "Templates"
    $templateFilePath = "$templatePath\module-templates\$TemplateName.json"

    if (-not (Test-Path $templateFilePath)) {
        Write-Host "Template '$TemplateName' not found!" -ForegroundColor Red
        Write-Host "Available templates:" -ForegroundColor Yellow
        $availableTemplates = Get-CobraTemplates -Category "module"
        if ($availableTemplates) {
            $availableTemplates | Format-Table Name, Description -AutoSize
        }
        return
    }
    
    try {
        $template = Get-Content $templateFilePath | ConvertFrom-Json
        $targetPath = "$($global:CobraConfig.CobraRoot)\Modules\$ModuleName"
        
        # Create module directory
        if (Test-Path $targetPath) {
            Write-Host "Module '$ModuleName' already exists!" -ForegroundColor Red
            return
        }
        
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
        
        # Process template files
        foreach ($file in $template.Files) {
            $content = $file.Content
            
            # Replace placeholders
            $content = $content -replace '\{ModuleName\}', $ModuleName
            $content = $content -replace '\{ModuleNameLower\}', $ModuleName.ToLower()
            $content = $content -replace '\{Date\}', (Get-Date).ToString('yyyy-MM-dd')
            $content = $content -replace '\{Author\}', $env:USERNAME
            
            # Replace custom parameters
            foreach ($param in $Parameters.GetEnumerator()) {
                $content = $content -replace "\{$($param.Key)\}", $param.Value
            }
            
            # Write file
            $filePath = "$targetPath\$($file.Name -replace '\{ModuleName\}', $ModuleName)"
            $content | Out-File -FilePath $filePath -Encoding UTF8
        }
        
        Write-Host "✓ Created module '$ModuleName' from template '$TemplateName'" -ForegroundColor Green
        Write-Host "✓ Module location: $targetPath" -ForegroundColor Green
        
        # Register the new module if it has a config
        $configPath = "$targetPath\config.ps1"
        if (Test-Path $configPath) {
            try {
                $config = . $configPath
                
                # Check if this is a standalone module
                if ($config.ContainsKey('ModuleType') -and $config.ModuleType -eq 'Standalone') {
                    Register-CobraStandaloneModule -Name $ModuleName -Description $config.Description -Config $config
                    Write-Host "✓ Standalone module registered in Cobra Framework" -ForegroundColor Green
                }
                else {
                    # Traditional repository-based module
                    Register-CobraRepository -Name $ModuleName -Description $config.Description -Config $config
                    Write-Host "✓ Repository module registered in Cobra Framework" -ForegroundColor Green
                }
            }
            catch {
                Write-Host "⚠ Module created but registration failed: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        Log-CobraActivity "Created module '$ModuleName' from template '$TemplateName'"
        
    }
    catch {
        Write-Host "Error creating module: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error creating module '$ModuleName': $($_.Exception.Message)"
    }
}

function Copy-CobraSnippet {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SnippetName,
        
        [hashtable]$Parameters = @{}
    )
    
    $templatePath = Join-Path $PSScriptRoot "Templates"

    $snippetPath = "$($templatePath)\code-snippets\$SnippetName.ps1"

    if (-not (Test-Path $snippetPath)) {
        # Try function snippets
        $snippetPath = "$($templatePath)\function-snippets\$SnippetName.ps1"
    }
    
    if (-not (Test-Path $snippetPath)) {
        Write-Host "Snippet '$SnippetName' not found!" -ForegroundColor Red
        Write-Host "Available snippets:" -ForegroundColor Yellow
        $availableSnippets = Get-CobraTemplates -Category "snippet"
        if ($availableSnippets) {
            $availableSnippets | Format-Table Name, Description -AutoSize
        }
        return
    }
    
    try {
        $content = Get-Content $snippetPath -Raw
        
        # Replace common placeholders
        $content = $content -replace '\{FunctionName\}', ($Parameters['FunctionName'] ?? 'YourFunction')
        $content = $content -replace '\{ModuleName\}', ($Parameters['ModuleName'] ?? 'YourModule')
        $content = $content -replace '\{Date\}', (Get-Date).ToString('yyyy-MM-dd')
        $content = $content -replace '\{Author\}', $env:USERNAME
        
        # Replace custom parameters
        foreach ($param in $Parameters.GetEnumerator()) {
            $content = $content -replace "\{$($param.Key)\}", $param.Value
        }
        
        # Copy to clipboard
        $content | Set-Clipboard
        Write-Host "✓ Snippet '$SnippetName' copied to clipboard" -ForegroundColor Green
        
        Log-CobraActivity "Used snippet '$SnippetName'"
        
    }
    catch {
        Write-Host "Error copying snippet: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error copying snippet '$SnippetName': $($_.Exception.Message)"
    }
}

function Save-CobraTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [ValidateSet("module", "function", "snippet")]
        [string]$Type,
        
        [string]$SourcePath,
        [string]$Description = "",
        [string]$FunctionName,
        [switch]$Personal,
        [switch]$Overwrite
    )
    
    $templatePath = Join-Path $PSScriptRoot "Templates"
    $templateLocation = if ($Personal) {
        "$($templatePath)\personal"
    }
    else {
        "$($templatePath)\shared"
    }
    
    switch ($Type) {
        "module" {
            if (-not $SourcePath -or -not (Test-Path $SourcePath)) {
                Write-Host "Source path required for module template!" -ForegroundColor Red
                return
            }
            
            $targetPath = "$templateLocation\module-templates\$Name.json"
            Save-ModuleTemplate -SourcePath $SourcePath -TargetPath $targetPath -Description $Description -Overwrite:$Overwrite
        }
        
        "function" {
            if (-not $SourcePath -or -not $FunctionName) {
                Write-Host "Source path and function name required for function template!" -ForegroundColor Red
                return
            }
            
            $targetPath = "$templateLocation\function-snippets\$Name.ps1"
            Save-FunctionTemplate -SourcePath $SourcePath -FunctionName $FunctionName -TargetPath $targetPath -Description $Description -Overwrite:$Overwrite
        }
        
        "snippet" {
            if (-not $SourcePath) {
                Write-Host "Source path required for snippet template!" -ForegroundColor Red
                return
            }
            
            $targetPath = "$templateLocation\code-snippets\$Name.ps1"
            Save-SnippetTemplate -SourcePath $SourcePath -TargetPath $targetPath -Description $Description -Overwrite:$Overwrite
        }
    }
}

function Get-CobraTemplateRegistry {
    [CmdletBinding()]
    param(
        [string]$SearchTerm = ""
    )
    
    if (-not $global:CobraConfig.TemplateRegistryLocation) {
        Write-Host "TemplateRegistryLocation is not configured." -ForegroundColor Red
        return @()
    }
    
    $registryLocation = $global:CobraConfig.TemplateRegistryLocation
    
    if (-not (Test-Path $registryLocation)) {
        Write-Host "Template registry not accessible: $registryLocation" -ForegroundColor Red
        return @()
    }
    
    $templates = @()
    
    # Get module templates
    $moduleTemplates = Get-ChildItem "$registryLocation\module-templates\*.json" -ErrorAction SilentlyContinue
    foreach ($template in $moduleTemplates) {
        try {
            $metadata = Get-Content $template.FullName | ConvertFrom-Json
            $templates += [PSCustomObject]@{
                Name        = $template.BaseName
                Type        = "module"
                Description = $metadata.Description
                Author      = $metadata.Author
                Created     = $metadata.Created
                Modified    = $template.LastWriteTime
            }
        }
        catch {
            $templates += [PSCustomObject]@{
                Name        = $template.BaseName
                Type        = "module"
                Description = "Module template"
                Author      = "Unknown"
                Created     = $template.CreationTime
                Modified    = $template.LastWriteTime
            }
        }
    }
    
    # Get function templates
    $functionTemplates = Get-ChildItem "$registryLocation\function-snippets\*.ps1" -ErrorAction SilentlyContinue
    foreach ($template in $functionTemplates) {
        $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
        $description = if ($content -and $content -match "# Description: (.+)") { $matches[1] } else { "Function template" }
        $author = if ($content -and $content -match "# Author: (.+)") { $matches[1] } else { "Unknown" }
        $created = if ($content -and $content -match "# Created: (.+)") { $matches[1] } else { $template.CreationTime }
        
        $templates += [PSCustomObject]@{
            Name        = $template.BaseName
            Type        = "function"
            Description = $description
            Author      = $author
            Created     = $created
            Modified    = $template.LastWriteTime
        }
    }
    
    # Get snippet templates
    $snippetTemplates = Get-ChildItem "$registryLocation\code-snippets\*.ps1" -ErrorAction SilentlyContinue
    foreach ($template in $snippetTemplates) {
        $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
        $description = if ($content -and $content -match "# Description: (.+)") { $matches[1] } else { "Code snippet" }
        $author = if ($content -and $content -match "# Author: (.+)") { $matches[1] } else { "Unknown" }
        $created = if ($content -and $content -match "# Created: (.+)") { $matches[1] } else { $template.CreationTime }
        
        $templates += [PSCustomObject]@{
            Name        = $template.BaseName
            Type        = "snippet"
            Description = $description
            Author      = $author
            Created     = $created
            Modified    = $template.LastWriteTime
        }
    }
    
    # Apply search filter
    if ($SearchTerm) {
        $templates = $templates | Where-Object { 
            $_.Name -like "*$SearchTerm*" -or $_.Description -like "*$SearchTerm*" 
        }
    }
    
    return $templates | Sort-Object Type, Name
}

function Start-CobraTemplateWizard {
    [CmdletBinding()]
    param(
        [ValidateSet("module", "function", "snippet")]
        [string]$Type = "module"
    )
    
    Write-Host "COBRA TEMPLATE WIZARD" -ForegroundColor Cyan
    Write-Host "====================" -ForegroundColor Cyan
    Write-Host
    
    switch ($Type) {
        "module" {
            Start-ModuleWizard
        }
        "function" {
            Write-Host "Function template wizard not implemented yet." -ForegroundColor Yellow
        }
        "snippet" {
            Write-Host "Snippet template wizard not implemented yet." -ForegroundColor Yellow
        }
    }
}

function Start-ModuleWizard {
    Write-Host "Creating new module from template..." -ForegroundColor Green
    Write-Host
    
    # Get available templates
    $templates = Get-CobraTemplates -Category module
    
    if ($templates.Count -eq 0) {
        Write-Host "No module templates available!" -ForegroundColor Red
        return
    }
    
    # Display template options
    Write-Host "Available Module Templates:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $templates.Count; $i++) {
        Write-Host "[$($i + 1)] $($templates[$i].Name) - $($templates[$i].Description)" -ForegroundColor White
    }
    Write-Host
    
    # Get user selection
    do {
        $selection = Read-Host "Select template [1-$($templates.Count)]"
    } while (-not ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $templates.Count))
    
    $selectedTemplate = $templates[[int]$selection - 1]
    
    # Get module name
    do {
        $moduleName = Read-Host "Module name"
    } while ([string]::IsNullOrWhiteSpace($moduleName))
    
    # Get optional parameters
    $parameters = @{}
    
    Write-Host
    Write-Host "Optional parameters (press Enter to skip):" -ForegroundColor Yellow
    
    $repo = Read-Host "Repository path"
    if (-not [string]::IsNullOrWhiteSpace($repo)) { $parameters['RepositoryPath'] = $repo }
    
    $description = Read-Host "Description"
    if (-not [string]::IsNullOrWhiteSpace($description)) { $parameters['Description'] = $description }
    
    # Create module
    Write-Host
    Write-Host "Creating module '$moduleName' from template '$($selectedTemplate.Name)'..." -ForegroundColor Green
    
    New-CobraModuleFromTemplate -TemplateName $selectedTemplate.Name -ModuleName $moduleName -Parameters $parameters
}

function Publish-CobraTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [ValidateSet("module", "function", "snippet")]
        [string]$Type = "module"
    )
    
    $templatePath = Join-Path $PSScriptRoot "Templates"

    if (-not $templatePath -or -not $global:CobraConfig.TemplateRegistryLocation) {
        Write-Host "Template locations are not configured." -ForegroundColor Red
        return
    }
    
    $localPath = switch ($Type) {
        "module" { "$($templatePath)\module-templates\$Name.json" }
        "function" { "$($templatePath)\function-snippets\$Name.ps1" }
        "snippet" { "$($templatePath)\code-snippets\$Name.ps1" }
    }
    
    $registryPath = switch ($Type) {
        "module" { "$($global:CobraConfig.TemplateRegistryLocation)\module-templates\$Name.json" }
        "function" { "$($global:CobraConfig.TemplateRegistryLocation)\function-snippets\$Name.ps1" }
        "snippet" { "$($global:CobraConfig.TemplateRegistryLocation)\code-snippets\$Name.ps1" }
    }
    
    if (-not (Test-Path $localPath)) {
        Write-Host "Template '$Name' not found locally!" -ForegroundColor Red
        return
    }
    
    try {
        # Ensure registry directory exists
        $registryDir = Split-Path $registryPath -Parent
        if (-not (Test-Path $registryDir)) {
            New-Item -ItemType Directory -Path $registryDir -Force | Out-Null
        }
        
        Copy-Item $localPath $registryPath -Force
        Write-Host "✓ Template '$Name' published to team registry" -ForegroundColor Green
        Log-CobraActivity "Published template '$Name' to registry"
        
    }
    catch {
        Write-Host "Error publishing template: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error publishing template '$Name': $($_.Exception.Message)"
    }
}

function Import-CobraTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [ValidateSet("module", "function", "snippet")]
        [string]$Type = "module",
        
        [switch]$Overwrite
    )
    
    $templatePath = Join-Path $PSScriptRoot "Templates"
    if (-not $templatePath -or -not $global:CobraConfig.TemplateRegistryLocation) {
        Write-Host "Template locations are not configured." -ForegroundColor Red
        return
    }
    
    $registryPath = switch ($Type) {
        "module" { "$($global:CobraConfig.TemplateRegistryLocation)\module-templates\$Name.json" }
        "function" { "$($global:CobraConfig.TemplateRegistryLocation)\function-snippets\$Name.ps1" }
        "snippet" { "$($global:CobraConfig.TemplateRegistryLocation)\code-snippets\$Name.ps1" }
    }
    
    $localPath = switch ($Type) {
        "module" { "$($templatePath)\module-templates\$Name.json" }
        "function" { "$($templatePath)\function-snippets\$Name.ps1" }
        "snippet" { "$($templatePath)\code-snippets\$Name.ps1" }
    }
    
    if (-not (Test-Path $registryPath)) {
        Write-Host "Template '$Name' not found in registry!" -ForegroundColor Red
        return
    }
    
    if ((Test-Path $localPath) -and -not $Overwrite) {
        Write-Host "Template '$Name' already exists locally! Use -Overwrite to replace." -ForegroundColor Yellow
        return
    }
    
    try {
        # Ensure local directory exists
        $localDir = Split-Path $localPath -Parent
        if (-not (Test-Path $localDir)) {
            New-Item -ItemType Directory -Path $localDir -Force | Out-Null
        }
        
        Copy-Item $registryPath $localPath -Force
        Write-Host "✓ Template '$Name' imported from registry" -ForegroundColor Green
        Log-CobraActivity "Imported template '$Name' from registry"
        
    }
    catch {
        Write-Host "Error importing template: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error importing template '$Name': $($_.Exception.Message)"
    }
}

# Helper functions for template creation
function Save-ModuleTemplate {
    [CmdletBinding()]
    param(
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$Description,
        [bool]$Overwrite
    )
    
    if ((Test-Path $TargetPath) -and -not $Overwrite) {
        Write-Host "Template already exists! Use -Overwrite to replace." -ForegroundColor Yellow
        return
    }
    
    try {
        $files = Get-ChildItem $SourcePath -Recurse -File | Where-Object { $_.Extension -in @('.ps1', '.psm1', '.json', '.md') }
        $templateFiles = @()
        
        foreach ($file in $files) {
            $relativePath = $file.FullName.Substring($SourcePath.Length).TrimStart('\')
            $content = Get-Content $file.FullName -Raw
            
            # Replace specific values with placeholders
            $content = $content -replace [regex]::Escape((Split-Path $SourcePath -Leaf)), '{ModuleName}'
            
            $templateFiles += @{
                Name    = $relativePath
                Content = $content
            }
        }
        
        $template = @{
            Name        = Split-Path $TargetPath -LeafBase
            Description = $Description
            Author      = $env:USERNAME
            Created     = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
            Files       = $templateFiles
        }
        
        $template | ConvertTo-Json -Depth 10 | Out-File -FilePath $TargetPath -Encoding UTF8
        Write-Host "✓ Module template saved: $TargetPath" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Error saving module template: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Save-FunctionTemplate {
    [CmdletBinding()]
    param(
        [string]$SourcePath,
        [string]$FunctionName,
        [string]$TargetPath,
        [string]$Description,
        [bool]$Overwrite
    )
    
    if ((Test-Path $TargetPath) -and -not $Overwrite) {
        Write-Host "Template already exists! Use -Overwrite to replace." -ForegroundColor Yellow
        return
    }
    
    try {
        $content = Get-Content $SourcePath -Raw
        $functionPattern = "function\s+$([regex]::Escape($FunctionName))\s*\{.*?\n\}"
        
        if ($content -match $functionPattern) {
            $functionCode = $matches[0]
            
            # Create template with metadata
            $template = @"
# Description: $Description
# Author: $env:USERNAME
# Created: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
# Type: Function Template

$functionCode
"@
            
            $template | Out-File -FilePath $TargetPath -Encoding UTF8
            Write-Host "✓ Function template saved: $TargetPath" -ForegroundColor Green
        }
        else {
            Write-Host "Function '$FunctionName' not found in source file!" -ForegroundColor Red
        }
        
    }
    catch {
        Write-Host "Error saving function template: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Save-SnippetTemplate {
    [CmdletBinding()]
    param(
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$Description,
        [bool]$Overwrite
    )
    
    if ((Test-Path $TargetPath) -and -not $Overwrite) {
        Write-Host "Template already exists! Use -Overwrite to replace." -ForegroundColor Yellow
        return
    }
    
    try {
        $content = Get-Content $SourcePath -Raw
        
        # Add metadata header
        $template = @"
# Description: $Description
# Author: $env:USERNAME
# Created: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))
# Type: Code Snippet

$content
"@
        
        $template | Out-File -FilePath $TargetPath -Encoding UTF8
        Write-Host "✓ Snippet template saved: $TargetPath" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Error saving snippet template: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Initialize template directories when this script is loaded
Initialize-TemplateDirectories

Log-CobraActivity "Templates Management loaded successfully."
