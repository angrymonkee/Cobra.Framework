function Invoke-CobraModuleValidation {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Path
    )

    write-host "Validating code in $Path"
    write-host "Using settings file $settingPath"

    $scriptAnalyzerModule = Get-Module -ListAvailable -Name 'PSScriptAnalyzer' | Select-Object -First 1
    if ($null -eq $scriptAnalyzerModule) {
        Install-Module -Name 'PSScriptAnalyzer' -Scope CurrentUser -Force -AllowClobber
        Import-Module -Name 'PSScriptAnalyzer' -Force
    }
    else {
        Import-Module -Name 'PSScriptAnalyzer' -Force
    }

    $settingPath = "" #TODO: Add setting path
    if ($settingPath -ne "" -and $settingPath -ne $null) {
        $settings = Get-Content -Path $settingPath -Raw
        $settings = ConvertFrom-Json -InputObject $settings
        $settings = $settings | ConvertTo-Hashtable
    }
    else {
        $settings = @{}
    }

    $results = Invoke-ScriptAnalyzer -Path $Path -Settings $settings
    $results
}

Export-ModuleMember -Function Invoke-ScriptAnalyzer2