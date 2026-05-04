param(
  [string]$Flutter = "C:\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$root = Resolve-Path (Join-Path $PSScriptRoot "..")
Set-Location $root

Write-Host "[secure-vector-store] Adding dependencies..." -ForegroundColor Cyan
& $Flutter pub add "flutter_secure_storage:^9.2.2" "encrypt:^5.0.3"
if ($LASTEXITCODE -ne 0) {
  throw "flutter pub add failed with exit code $LASTEXITCODE"
}

Write-Host "[secure-vector-store] Running flutter pub get..." -ForegroundColor Cyan
& $Flutter pub get
if ($LASTEXITCODE -ne 0) {
  throw "flutter pub get failed with exit code $LASTEXITCODE"
}

Write-Host "[secure-vector-store] Done." -ForegroundColor Green
