[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SteamCmd,
    [Parameter(Mandatory)][string]$SteamLogin,
    [Parameter(Mandatory)][string]$PythonExe,
    [Parameter(Mandatory)][string]$ArtifactDirectory
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
if (-not (Test-Path -LiteralPath $SteamCmd -PathType Leaf)) { throw 'Verified SteamCMD executable is required.' }
$freshness = Join-Path $env:USERPROFILE '.codex/b47anced-team/tools/Test-PZRepositoryFreshness.ps1'
$fresh = (& $freshness -Repository $root | Out-String) | ConvertFrom-Json
if ($fresh.status -ne 'PASS' -or $fresh.ahead -ne 0 -or $fresh.behind -ne 0) { throw 'Fresh source/upstream verification failed.' }
& $PythonExe (Join-Path $root 'scripts/check_versions.py') --root $root --release
if ($LASTEXITCODE -ne 0) { throw 'Artifact version check failed.' }
& $PythonExe (Join-Path $root 'scripts/workshop_package.py') --verify $ArtifactDirectory
if ($LASTEXITCODE -ne 0) { throw 'Package/provenance/integrity check failed.' }
$vdf = Join-Path $ArtifactDirectory 'workshop.vdf'
$output = & $SteamCmd +login $SteamLogin +workshop_build_item $vdf +quit 2>&1
$code = $LASTEXITCODE
$safeOutput = [regex]::Replace(($output | Out-String),'(?i)' + [regex]::Escape($SteamLogin),'<cached-account>')
Write-Output $safeOutput
if ([IO.File]::ReadAllText($vdf) -notmatch '"publishedfileid"\s+"3788591331"') { throw 'Unexpected Workshop item ID after upload.' }
if ($code -ne 0 -or $safeOutput -notmatch 'Success\. Uploaded item to Steam Workshop \(PublishedFileID 3788591331\)|Committing update\.\.\.Success') {
    throw 'SteamCMD did not confirm successful upload of the selected existing item.'
}
Write-Output 'Confirmed Workshop upload for existing item 3788591331. Steam desktop was not restarted.'
