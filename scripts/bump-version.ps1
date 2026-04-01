param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [switch]$Tag,
    [switch]$PushTag
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if ($Version.StartsWith("v")) {
    $Version = $Version.Substring(1)
}

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must be semantic version in format X.Y.Z"
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $repoRoot

function Replace-Regex {
    param(
        [string]$Path,
        [string]$Pattern,
        [string]$Replacement,
        [string]$Label
    )

    $fullPath = Join-Path $repoRoot $Path
    if (-not (Test-Path $fullPath)) {
        throw "Missing file: $Path"
    }

    $content = Get-Content -Path $fullPath -Raw
    $updated = [regex]::Replace($content, $Pattern, $Replacement)

    if ($updated -eq $content) {
        Write-Host "No change for $Label -> $Path"
        return
    }

    Set-Content -Path $fullPath -Value $updated
    Write-Host "Updated $Label -> $Path"
}

$versionFilePath = Join-Path $repoRoot "VERSION"
$existingVersion = ""
if (Test-Path $versionFilePath) {
    $existingVersion = (Get-Content -Path $versionFilePath -Raw).Trim()
}
if ($existingVersion -eq $Version) {
    Write-Host "No change for VERSION file"
} else {
    Set-Content -Path $versionFilePath -Value $Version
    Write-Host "Updated VERSION file"
}

Replace-Regex -Path "SlapMac-Extension/manifest.json" -Pattern '"version"\s*:\s*"[^"]+"' -Replacement ('"version": "' + $Version + '"') -Label "Extension version"
Replace-Regex -Path "SlapMac-Android/app/build.gradle.kts" -Pattern 'versionName\s*=\s*"[^"]+"' -Replacement ('versionName = "' + $Version + '"') -Label "Android versionName"
Replace-Regex -Path "SlapMac-Windows/SlapMac.csproj" -Pattern '<Version>[^<]+</Version>' -Replacement ('<Version>' + $Version + '</Version>') -Label "Windows Version"
Replace-Regex -Path "SlapMac-iOS/project.yml" -Pattern 'MARKETING_VERSION:\s*"[^"]+"' -Replacement ('MARKETING_VERSION: "' + $Version + '"') -Label "iOS MARKETING_VERSION"
Replace-Regex -Path "SlapMac/SlapMac.xcodeproj/project.pbxproj" -Pattern 'MARKETING_VERSION = [^;]+;' -Replacement ('MARKETING_VERSION = ' + $Version + ';') -Label "macOS MARKETING_VERSION"

$syncScriptPath = Join-Path $repoRoot "scripts/sync-i18n.py"
if (Test-Path $syncScriptPath) {
    & python $syncScriptPath
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to sync i18n resources"
    }
} else {
    Write-Host "Skipping i18n sync (scripts/sync-i18n.py not found)"
}

Write-Host "\nDone. Version synced to $Version"
Write-Host "Next steps:"
Write-Host "  git add -A"
Write-Host "  git commit -m \"chore: bump version to v$Version\""
Write-Host "  git tag v$Version"
Write-Host "  git push origin main"
Write-Host "  git push origin v$Version"

if ($PushTag -and -not $Tag) {
    throw "-PushTag requires -Tag"
}

if ($Tag) {
    & git tag ("v" + $Version)
    Write-Host "Created tag v$Version"

    if ($PushTag) {
        & git push origin ("v" + $Version)
        Write-Host "Pushed tag v$Version"
    }
}
