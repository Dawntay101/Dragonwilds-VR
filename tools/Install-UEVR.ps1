<#
.SYNOPSIS
  Downloads and extracts UEVR (the Unreal Engine VR injector) into ./uevr,
  verifying the published sha256 checksum first.

.PARAMETER Nightly
  Download the latest nightly dev build from praydog/UEVR-nightly instead
  of a numbered stable release from praydog/UEVR. Requires the `gh` CLI
  to be installed and authenticated (nightly release assets are fetched
  via `gh release download`). Dragonwilds needed a nightly build - see
  README.md for why.

.NOTES
  UEVR's own injector GUI (UEVRInjector.exe) requires the .NET 6.0 Desktop
  Runtime to be installed system-wide. This script does not install that -
  see README.md for how to check/install it.
#>

param(
    [string]$Tag = "1.05",
    [switch]$Nightly,
    [string]$DestDir = (Join-Path $PSScriptRoot "..\uevr")
)

$ErrorActionPreference = "Stop"

$work = Join-Path $env:TEMP "uevr_install"
New-Item -ItemType Directory -Force -Path $work | Out-Null
$zipPath = Join-Path $work "uevr.zip"
$shaPath = Join-Path $work "uevr.zip.sha256"
Remove-Item -Force $zipPath, $shaPath -ErrorAction SilentlyContinue

if ($Nightly) {
    Write-Host "Fetching latest UEVR nightly release info ..."
    $release = gh api repos/praydog/UEVR-nightly/releases/latest | ConvertFrom-Json
    Write-Host "Downloading nightly $($release.tag_name) ..."
    Push-Location $work
    try {
        gh release download $release.tag_name --repo praydog/UEVR-nightly --clobber
    } finally {
        Pop-Location
    }
} else {
    Write-Host "Downloading UEVR $Tag ..."
    Invoke-WebRequest -Uri "https://github.com/praydog/UEVR/releases/download/$Tag/UEVR.zip" -OutFile $zipPath
    Invoke-WebRequest -Uri "https://github.com/praydog/UEVR/releases/download/$Tag/UEVR.zip.sha256" -OutFile $shaPath
}

# The stable-release .sha256 file is UTF-16 encoded; the nightly one is
# plain ASCII. Read robustly and compare case-insensitively either way.
$expected = (Get-Content -Path $shaPath -Raw -Encoding Unicode).Trim().ToLower() -replace '[^0-9a-f]', ''
if ($expected.Length -ne 64) {
    $expected = ((Get-Content -Path $shaPath -Raw).Trim().ToLower() -replace '[^0-9a-f]', '')
}

$actual = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLower()

if ($actual -ne $expected) {
    throw "Checksum mismatch for uevr.zip! expected=$expected actual=$actual - aborting, do not use this download."
}
Write-Host "Checksum verified: $actual"

New-Item -ItemType Directory -Force -Path $DestDir | Out-Null
# Extract over the existing folder rather than deleting it first (avoids
# fighting path-protection on ./uevr); harmless leftover files from a
# previous build may remain but nothing loads them by folder scan.
Expand-Archive -Path $zipPath -DestinationPath $DestDir -Force

Write-Host "UEVR extracted to $DestDir"
Write-Host "Injector: $DestDir\UEVRInjector.exe"
