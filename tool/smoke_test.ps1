# tool/smoke_test.ps1
#
# Local AI Server E2E smoke test.
# If a server is not already listening on localhost:8080, this script starts
# `dart run bin/server.dart`, waits for /health, probes /docs and /query, then
# stops only the server process it started.

$ErrorActionPreference = 'Stop'

$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $root

$flutterHome = if ($env:FLUTTER_HOME) {
  $env:FLUTTER_HOME
} else {
  Join-Path $HOME 'flutter'
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  $flutterBin = Join-Path $flutterHome 'bin'
  if (Test-Path $flutterBin) {
    $env:Path = $flutterBin + [IO.Path]::PathSeparator + $env:Path
  }
}

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
  $flutterBin = Join-Path $flutterHome 'bin'
  if (Test-Path $flutterBin) {
    $env:Path = $flutterBin + [IO.Path]::PathSeparator + $env:Path
  }
}

$ollamaPath = 'C:\Program Files\Ollama'
if ((Test-Path $ollamaPath) -and -not (Get-Command ollama -ErrorAction SilentlyContinue)) {
  $env:Path += [IO.Path]::PathSeparator + $ollamaPath
}

function Test-Health {
  try {
    Invoke-RestMethod -Uri 'http://127.0.0.1:8080/health' -Method Get -TimeoutSec 2
  } catch {
    $null
  }
}

function Wait-Health {
  param([int] $Seconds = 45)

  Write-Host 'Waiting 5 seconds for server to initialize...' -ForegroundColor Yellow
  Start-Sleep -Seconds 5

  $attempts = 0
  $maxAttempts = 3
  $health = $null

  do {
    $attempts++
    if ($attempts -gt 1) {
      Write-Host "Retry attempt $attempts of $maxAttempts to connect to /health..." -ForegroundColor Yellow
    }
    
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
      $health = Test-Health
      if ($health) {
        return $health
      }
      Start-Sleep -Seconds 1
    }
  } until ($health -or ($attempts -ge $maxAttempts))

  if (-not $health) {
    throw "Local AI Server did not become healthy on http://127.0.0.1:8080/health after $maxAttempts attempts."
  }
  return $health
}

if (-not $env:OLLAMA_MODEL) {
  $env:OLLAMA_MODEL = 'qwen2.5:7b'
}
if (-not $env:EMBED_MODEL) {
  $env:EMBED_MODEL = 'bge-m3:latest'
}

Write-Host 'Starting Local AI Server E2E smoke test...' -ForegroundColor Cyan

$startedServer = $false
$serverProcess = $null
$serverOut = Join-Path $root 'build\smoke_server_stdout.log'
$serverErr = Join-Path $root 'build\smoke_server_stderr.log'
New-Item -ItemType Directory -Force -Path (Join-Path $root 'build') | Out-Null
Remove-Item -LiteralPath $serverOut,$serverErr -ErrorAction SilentlyContinue

try {
  $health = Test-Health
  if (-not $health) {
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
      throw 'dart is not on PATH. Install Flutter or run tool\install_flutter.cmd first.'
    }

    Write-Host 'No server detected on :8080; starting dart run bin/server.dart...' -ForegroundColor Yellow
    $serverProcess = Start-Process `
      -FilePath 'dart' `
      -ArgumentList @('run', 'bin/server.dart') `
      -WorkingDirectory $root `
      -RedirectStandardOutput $serverOut `
      -RedirectStandardError $serverErr `
      -WindowStyle Hidden `
      -PassThru
    $startedServer = $true
    $health = Wait-Health
  }

  Write-Host "PASS /health: $($health.status)" -ForegroundColor Green

  $docs = Invoke-RestMethod -Uri 'http://127.0.0.1:8080/docs' -Method Get -TimeoutSec 10
  Write-Host "PASS /docs: $($docs.docs.Count) docs" -ForegroundColor Green

  $body = @{ query = 'What is DOSBox?' } | ConvertTo-Json
  $query = Invoke-RestMethod `
    -Uri 'http://127.0.0.1:8080/query' `
    -Method Post `
    -Body $body `
    -ContentType 'application/json' `
    -TimeoutSec 120
  $answer = [string] $query.answer
  $preview = $answer.Substring(0, [Math]::Min(100, $answer.Length))
  Write-Host "PASS /query: $preview..." -ForegroundColor Green

  Write-Host ''
  Write-Host 'E2E smoke test completed.' -ForegroundColor Green
} finally {
  if ($startedServer -and $serverProcess -and -not $serverProcess.HasExited) {
    Stop-Process -Id $serverProcess.Id -Force
  }
}
