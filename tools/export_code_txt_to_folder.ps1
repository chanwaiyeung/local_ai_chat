# Export Dart/YAML sources as .txt (exclude .arb) for offline review / AI handoff.
# Usage (PowerShell):
#   .\tools\export_code_txt_to_folder.ps1 -Destination "C:\Users\Albert Chan\Desktop\ai report\code_txt_export"

param(
  [Parameter(Mandatory = $true)]
  [string] $Destination,

  [string] $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
$excludeDir = @("\.git\", "\\build\\", "\\.dart_tool\\", "\\.idea\\")

function Test-Excluded([string] $fullPath) {
  foreach ($p in $excludeDir) {
    if ($fullPath -match $p) { return $true }
  }
  return $false
}

if (-not (Test-Path $Destination)) {
  New-Item -ItemType Directory -Path $Destination -Force | Out-Null
}

$patterns = @("*.dart", "*.yaml", "*.yml")
foreach ($pat in $patterns) {
  Get-ChildItem -Path $ProjectRoot -Recurse -File -Filter $pat |
    Where-Object {
      -not (Test-Excluded $_.FullName) -and
      $_.Extension -ne ".arb" -and
      ($_.FullName -notmatch "\\lib\\l10n\\.*\.arb$")
    } |
    ForEach-Object {
      $rel = $_.FullName.Substring($ProjectRoot.Length).TrimStart("\", "/")
      $outPath = Join-Path $Destination ($rel + ".txt")
      $outDir = Split-Path $outPath -Parent
      if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Path $outDir -Force | Out-Null
      }
      Copy-Item -LiteralPath $_.FullName -Destination $outPath -Force
    }
}

Write-Host "Exported to: $Destination"
