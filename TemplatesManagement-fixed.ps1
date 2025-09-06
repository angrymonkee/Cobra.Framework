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
        [switch]$PersonalOnly,
        [switch]$IncludeModuleTemplates
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
    
    # Step 3: Include module templates when requested or when Category is "all"
    if ($IncludeModuleTemplates -or $Category -eq "all") {
        $moduleTemplates = Get-ModuleTemplates
        $templates += $moduleTemplates
    }
    
    # Apply search filter
    if ($SearchTerm) {
        $templates = $templates | Where-Object { 
            $_.Name -like "*$SearchTerm*" -or $_.Description -like "*$SearchTerm*" 
        }
    }
    
    return $templates | Sort-Object Type, Name
}

# Step 1: Add Get-ModuleTemplates Function
function Get-ModuleTemplates {
    [CmdletBinding()]
    param()
    
    $moduleTemplates = @()
    $modulesPath = Join-Path $PSScriptRoot "Modules"
    
    if (Test-Path $modulesPath) {
        try {
            $modules = Get-ChildItem -Path $modulesPath -Directory -ErrorAction SilentlyContinue
            
            foreach ($module in $modules) {
                $templatePath = Join-Path $module.FullName "templates"
                
                if (Test-Path $templatePath) {
                    # Scan for different template types
                    $moduleTemplates += Get-ModuleTemplatesByType -ModuleName $module.Name -TemplatePath $templatePath
                }
            }
        }
        catch {
            Write-Verbose "Error scanning module directories: $($_.Exception.Message)"
        }
    }
    
    return $moduleTemplates
}

# Step 2: Add Get-ModuleTemplatesByType Function  
function Get-ModuleTemplatesByType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        
        [Parameter(Mandatory)]
        [string]$TemplatePath
    )
    
    $templates = @()
    
    try {
        # Function templates (*.ps1)
        $functionTemplates = Get-ChildItem "$TemplatePath\*.ps1" -ErrorAction SilentlyContinue
        foreach ($template in $functionTemplates) {
            $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
            $description = if ($content -and $content -match "# Description: (.+)") { $matches[1] } else { "Module function template" }
            $author = if ($content -and $content -match "# Author: (.+)") { $matches[1] } else { "Module: $ModuleName" }
            
            $templates += [PSCustomObject]@{
                Name        = "$ModuleName.$($template.BaseName)"
                Type        = "module-function"
                Description = $description
                Path        = $template.FullName
                Author      = $author
                Module      = $ModuleName
                Created     = $template.CreationTime
            }
        }
        
        # Text templates (*.txt, *.md)
        $textTemplates = Get-ChildItem "$TemplatePath\*" -Include "*.txt", "*.md" -ErrorAction SilentlyContinue
        foreach ($template in $textTemplates) {
            $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
            $description = if ($content -and $content -match "# Description: (.+)") { $matches[1] } else { "Module text template" }
            
            $templates += [PSCustomObject]@{
                Name        = "$ModuleName.$($template.BaseName)"
                Type        = "module-text"
                Description = $description
                Path        = $template.FullName
                Author      = "Module: $ModuleName"
                Module      = $ModuleName
                Created     = $template.CreationTime
            }
        }
        
        # JSON templates (*.json)
        $jsonTemplates = Get-ChildItem "$TemplatePath\*.json" -ErrorAction SilentlyContinue
        foreach ($template in $jsonTemplates) {
            try {
                $content = Get-Content $template.FullName -Raw -ErrorAction SilentlyContinue
                if ($content) {
                    $metadata = $content | ConvertFrom-Json -ErrorAction Stop
                    $description = if ($metadata.Description) { $metadata.Description } else { "Module JSON template" }
                    $author = if ($metadata.Author) { $metadata.Author } else { "Module: $ModuleName" }
                }
                else {
                    $description = "Module JSON template"
                    $author = "Module: $ModuleName"
                }
                
                $templates += [PSCustomObject]@{
                    Name        = "$ModuleName.$($template.BaseName)"
                    Type        = "module-json"
                    Description = $description
                    Path        = $template.FullName
                    Author      = $author
                    Module      = $ModuleName
                    Created     = $template.CreationTime
                }
            }
            catch {
                $templates += [PSCustomObject]@{
                    Name        = "$ModuleName.$($template.BaseName)"
                    Type        = "module-json"
                    Description = "Module JSON template"
                    Path        = $template.FullName
                    Author      = "Module: $ModuleName"
                    Module      = $ModuleName
                    Created     = $template.CreationTime
                }
            }
        }
    }
    catch {
        Write-Verbose "Error processing templates for module '$ModuleName': $($_.Exception.Message)"
    }
    
    return $templates
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
        
        Write-Host "[OK] Created module '$ModuleName' from template '$TemplateName'" -ForegroundColor Green
        Write-Host "[OK] Module location: $targetPath" -ForegroundColor Green
        
        # Register the new module if it has a config
        $configPath = "$targetPath\config.ps1"
        if (Test-Path $configPath) {
            try {
                $config = . $configPath
                
                # Check if this is a standalone module
                if ($config.ContainsKey('ModuleType') -and $config.ModuleType -eq 'Standalone') {
                    Register-CobraStandaloneModule -Name $ModuleName -Description $config.Description -Config $config
                    Write-Host "[OK] Standalone module registered in Cobra Framework" -ForegroundColor Green
                }
                else {
                    # Traditional repository-based module
                    Register-CobraRepository -Name $ModuleName -Description $config.Description -Config $config
                    Write-Host "[OK] Repository module registered in Cobra Framework" -ForegroundColor Green
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

# Step 4: Add Copy-ModuleTemplate Function
function Copy-ModuleTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,
        
        [Parameter(Mandatory)]
        [string]$TemplateName,
        
        [string]$DestinationPath = ".",
        
        [hashtable]$Parameters = @{}
    )
    
    $modulePath = Join-Path $PSScriptRoot "Modules\$ModuleName"
    
    if (-not (Test-Path $modulePath)) {
        Write-Host "Module '$ModuleName' not found!" -ForegroundColor Red
        return $false
    }
    
    $templatePath = Join-Path $modulePath "templates\$TemplateName"
    
    # Look for template files with various extensions
    $possibleExtensions = @(".ps1", ".txt", ".json", ".md")
    $templateFile = $null
    
    foreach ($ext in $possibleExtensions) {
        $testPath = "$templatePath$ext"
        if (Test-Path $testPath) {
            $templateFile = $testPath
            break
        }
    }
    
    if (-not $templateFile) {
        Write-Host "Template '$TemplateName' not found in module '$ModuleName'" -ForegroundColor Red
        Write-Host "Available templates in '$ModuleName':" -ForegroundColor Yellow
        
        $moduleTemplatesPath = Join-Path $modulePath "templates"
        if (Test-Path $moduleTemplatesPath) {
            $availableTemplates = Get-ChildItem $moduleTemplatesPath -File | Select-Object -ExpandProperty BaseName
            if ($availableTemplates) {
                $availableTemplates | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
            }
            else {
                Write-Host "  No templates found" -ForegroundColor Gray
            }
        }
        return $false
    }
    
    try {
        # Read template content
        $content = Get-Content $templateFile -Raw
        
        # Replace standard parameters
        $content = $content -replace '\{ModuleName\}', $ModuleName
        $content = $content -replace '\{Date\}', (Get-Date).ToString('yyyy-MM-dd')
        $content = $content -replace '\{Author\}', $env:USERNAME
        
        # Replace custom parameters
        foreach ($param in $Parameters.GetEnumerator()) {
            $placeholder = "{$($param.Key)}"
            $content = $content -replace [regex]::Escape($placeholder), $param.Value
        }
        
        # Create output file with same extension as template
        $templateExtension = [System.IO.Path]::GetExtension($templateFile)
        $outputFileName = "$TemplateName$templateExtension"
        $outputFile = Join-Path $DestinationPath $outputFileName
        
        # Ensure destination directory exists
        $destinationDir = Split-Path $outputFile -Parent
        if (-not (Test-Path $destinationDir)) {
            New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
        }
        
        # Write processed content to output file
        $content | Out-File -FilePath $outputFile -Encoding UTF8
        
        Write-Host "[OK] Template copied to: $outputFile" -ForegroundColor Green
        Log-CobraActivity "Module template copied: $ModuleName.$TemplateName -> $outputFile"
        
        return $true
    }
    catch {
        Write-Host "Error copying template: $($_.Exception.Message)" -ForegroundColor Red
        Log-CobraActivity "Error copying module template '$ModuleName.$TemplateName': $($_.Exception.Message)"
        return $false
    }
}

# Step 5: Add Copy-CobraTemplate Function (enhanced to handle module templates)
function Copy-CobraTemplate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TemplateName,
        
        [string]$DestinationPath = ".",
        
        [hashtable]$Parameters = @{}
    )
    
    # Check if it's a module template (contains exactly one dot)
    if ($TemplateName -like "*.*" -and ($TemplateName.Split('.').Count -eq 2)) {
        $parts = $TemplateName -split '\.'
        $moduleName = $parts[0]
        $templateName = $parts[1]
        
        # Validate module exists
        $modulePath = Join-Path $PSScriptRoot "Modules\$moduleName"
        if (-not (Test-Path $modulePath)) {
            Write-Host "Module '$moduleName' not found!" -ForegroundColor Red
            Write-Host "Available modules with templates:" -ForegroundColor Yellow
            
            $moduleTemplates = Get-ModuleTemplates
            if ($moduleTemplates) {
                $moduleTemplates | Group-Object Module | ForEach-Object { 
                    Write-Host "  - $($_.Name)" -ForegroundColor Gray 
                }
            }
            else {
                Write-Host "  No modules with templates found" -ForegroundColor Gray
            }
            return $false
        }
        
        # Copy module template
        return Copy-ModuleTemplate -ModuleName $moduleName -TemplateName $templateName -DestinationPath $DestinationPath -Parameters $Parameters
    }
    else {
        # Handle regular templates (existing functionality)
        # Check if it's a snippet-style template first
        $templatePath = Join-Path $PSScriptRoot "Templates"
        
        # Try code snippets first
        $snippetPath = "$templatePath\code-snippets\$TemplateName.ps1"
        if (-not (Test-Path $snippetPath)) {
            # Try function snippets
            $snippetPath = "$templatePath\function-snippets\$TemplateName.ps1"
        }
        
        if (Test-Path $snippetPath) {
            # Use existing snippet copying logic but write to file instead of clipboard
            try {
                $content = Get-Content $snippetPath -Raw
                
                # Replace common placeholders
                $functionName = if ($Parameters['FunctionName']) { $Parameters['FunctionName'] } else { 'YourFunction' }
                $moduleName = if ($Parameters['ModuleName']) { $Parameters['ModuleName'] } else { 'YourModule' }
                
                $content = $content -replace '\{FunctionName\}', $functionName
                $content = $content -replace '\{ModuleName\}', $moduleName
                $content = $content -replace '\{Date\}', (Get-Date).ToString('yyyy-MM-dd')
                $content = $content -replace '\{Author\}', $env:USERNAME
                
                # Replace custom parameters
                foreach ($param in $Parameters.GetEnumerator()) {
                    $placeholder = "{$($param.Key)}"
                    $content = $content -replace [regex]::Escape($placeholder), $param.Value
                }
                
                # Write to file instead of clipboard
                $outputFile = Join-Path $DestinationPath "$TemplateName.ps1"
                
                # Ensure destination directory exists
                $destinationDir = Split-Path $outputFile -Parent
                if (-not (Test-Path $destinationDir)) {
                    New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
                }
                
                $content | Out-File -FilePath $outputFile -Encoding UTF8
                Write-Host "[OK] Template '$TemplateName' copied to: $outputFile" -ForegroundColor Green
                
                Log-CobraActivity "Template copied: $TemplateName -> $outputFile"
                return $true
            }
            catch {
                Write-Host "Error copying template: $($_.Exception.Message)" -ForegroundColor Red
                Log-CobraActivity "Error copying template '$TemplateName': $($_.Exception.Message)"
                return $false
            }
        }
        else {
            Write-Host "Template '$TemplateName' not found!" -ForegroundColor Red
            Write-Host "Available templates:" -ForegroundColor Yellow
            
            $availableTemplates = Get-CobraTemplates
            if ($availableTemplates) {
                $availableTemplates | Format-Table Name, Type, Description -AutoSize
            }
            else {
                Write-Host "  No templates found" -ForegroundColor Gray
            }
            return $false
        }
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
        $functionName = if ($Parameters['FunctionName']) { $Parameters['FunctionName'] } else { 'YourFunction' }
        $moduleName = if ($Parameters['ModuleName']) { $Parameters['ModuleName'] } else { 'YourModule' }
        
        $content = $content -replace '\{FunctionName\}', $functionName
        $content = $content -replace '\{ModuleName\}', $moduleName
        $content = $content -replace '\{Date\}', (Get-Date).ToString('yyyy-MM-dd')
        $content = $content -replace '\{Author\}', $env:USERNAME
        
        # Replace custom parameters
        foreach ($param in $Parameters.GetEnumerator()) {
            $placeholder = "{$($param.Key)}"
            $content = $content -replace [regex]::Escape($placeholder), $param.Value
        }
        
        # Copy to clipboard
        $content | Set-Clipboard
        Write-Host "[OK] Snippet '$SnippetName' copied to clipboard" -ForegroundColor Green
        
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
        Write-Host "[OK] Template '$Name' published to team registry" -ForegroundColor Green
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
        Write-Host "[OK] Template '$Name' imported from registry" -ForegroundColor Green
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
        Write-Host "[OK] Module template saved: $TargetPath" -ForegroundColor Green
        
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
            Write-Host "[OK] Function template saved: $TargetPath" -ForegroundColor Green
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
        Write-Host "[OK] Snippet template saved: $TargetPath" -ForegroundColor Green
        
    }
    catch {
        Write-Host "Error saving snippet template: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Initialize template directories when this script is loaded
Initialize-TemplateDirectories

Log-CobraActivity "Templates Management loaded successfully."
