# Description: PowerShell function parameter validation snippet
# Author: Cobra Framework
# Created: 2025-08-07 00:00:00
# Type: Code Snippet

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "Provide the {ParameterName}")]
    [ValidateNotNullOrEmpty()]
    [string]${ParameterName},
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Option1", "Option2", "Option3")]
    [string]$OptionalParameter = "Option1"
)
