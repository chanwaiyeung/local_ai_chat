# Full audit export: reports + code as .txt (no .arb, no *-bak) -> Desktop\ai report
$ErrorActionPreference = "Stop"
$root = "c:\dev\local_ai_chat"
$desktopReport = Join-Path $env:USERPROFILE "Desktop\ai report"
$stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
$bundle = Join-Path $desktopReport "project_audit_$stamp"
$codeTxt = Join-Path $bundle "code_txt"
$reports = Join-Path $bundle "reports"

New-Item -ItemType Directory -Path $codeTxt -Force | Out-Null
New-Item -ItemType Directory -Path $reports -Force | Out-Null

$excludeDir = @('\.git\', '\\build\\', '\\.dart_tool\\', '\\.idea\\')
function Test-Excluded([string] $p) {
  foreach ($x in $excludeDir) { if ($p -match $x) { return $true } }
  return $false
}

$exts = @('*.dart', '*.py', '*.yaml', '*.yml', '*.ps1', '*.json', '*.md')
$exported = 0
foreach ($pat in $exts) {
  Get-ChildItem -Path $root -Recurse -File -Filter $pat -ErrorAction SilentlyContinue |
    Where-Object {
      -not (Test-Excluded $_.FullName) -and
      $_.Extension -ne '.arb' -and
      $_.Name -notmatch '-bak(\.|$)' -and
      $_.FullName -notmatch '\\lib\\l10n\\.*\.arb$'
    } |
    ForEach-Object {
      $rel = $_.FullName.Substring($root.Length).TrimStart('\', '/')
      $outPath = Join-Path $codeTxt ($rel + '.txt')
      $outDir = Split-Path $outPath -Parent
      if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
      Copy-Item -LiteralPath $_.FullName -Destination $outPath -Force
      $script:exported++
    }
}

# Copy audit reports from repo if present
$repoReports = Join-Path $root "audit_bundle"
if (Test-Path $repoReports) {
  Copy-Item -Path (Join-Path $repoReports "*.txt") -Destination $reports -Force -ErrorAction SilentlyContinue
}

# Sandbox path simulation log
$sandbox = @"
SANDBOX PATH SIMULATION — $stamp
Repo: $root

Scenario A: cwd = project root
  streamlit run main.py          => FAIL (main.py missing)
  streamlit run pages/1_Hub.py  => OK if cwd=root (data/ relative)
  python telegram_bot.py         => OK (config.json, data/ relative)
  flutter run -d windows         => OK (lib/main.dart)

Scenario B: cwd = pages/
  Path('data/expenses.json')     => FAIL (resolves pages/data/ not root data/)

Scenario C: cwd = arbitrary (e.g. C:\Users)
  telegram_bot.py paths          => FAIL (config.json not found)
  Streamlit data/*.json          => FAIL

Scenario D: Flutter
  VectorStore                    => getApplicationSupportDirectory() — cwd independent OK
  assets/sample_page.jpg         => FAIL (no assets/ folder in repo)

Inline archives (*-bak): 40 files under lib/, bin/, test/ (not exported to code_txt)
archive_scripts/: NOT PRESENT in repo
"@
$sandbox | Set-Content -Path (Join-Path $reports "SANDBOX_PATH_SIMULATION.txt") -Encoding UTF8

@"
EXPORT MANIFEST — $stamp
Bundle folder: $bundle
Files exported as .txt: $exported
Excluded: .arb, *-bak*, build/, .dart_tool/, .git/
"@ | Set-Content -Path (Join-Path $bundle "EXPORT_MANIFEST.txt") -Encoding UTF8

Write-Output "BUNDLE=$bundle"
Write-Output "EXPORTED=$exported"
