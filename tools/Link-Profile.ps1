<#
.SYNOPSIS
  Creates a directory junction from UEVR's per-game profile folder
  (%APPDATA%\UnrealVRMod\RSDragonwilds-Win64-Shipping) to this repo's
  ./profile folder, so anything UEVR saves at runtime (config.txt,
  cameras.txt, cvars_*.txt, uobjecthook/) lands directly in version control
  instead of being hidden away in %APPDATA%.

.NOTES
  Safe to re-run. Does nothing if the junction already exists and already
  points at ./profile. Requires no admin rights (junctions, unlike
  symlinks, don't need elevation on NTFS).
#>

param(
    [string]$GameExeBaseName = "RSDragonwilds-Win64-Shipping",
    [string]$ProfileSourceDir = (Join-Path $PSScriptRoot "..\profile")
)

$ErrorActionPreference = "Stop"

$target = Resolve-Path $ProfileSourceDir
$linkParent = Join-Path $env:APPDATA "UnrealVRMod"
$link = Join-Path $linkParent $GameExeBaseName

New-Item -ItemType Directory -Force -Path $linkParent | Out-Null

if (Test-Path $link) {
    $item = Get-Item $link -Force
    if ($item.LinkType -eq "Junction" -and $item.Target -eq $target.Path) {
        Write-Host "Already linked: $link -> $target"
        return
    }
    throw "$link already exists and is not our junction. Back it up / remove it manually, then re-run this script."
}

New-Item -ItemType Junction -Path $link -Target $target | Out-Null
Write-Host "Linked $link -> $target"
