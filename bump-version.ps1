param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [switch]$Tag,
    [switch]$PushTag
)

& "$PSScriptRoot\scripts\bump-version.ps1" -Version $Version -Tag:$Tag -PushTag:$PushTag
