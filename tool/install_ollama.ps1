# tool/install_ollama.ps1
#
# Idempotent Ollama installer for Windows.
# 1. Installs Ollama (winget if available, else direct .exe).
# 2. Adds it to PATH for the current process.
# 3. Starts the daemon in background if it's not already running.
# 4. Pulls the model named in $env:OLLAMA_MODEL (default: llama3.1:8b).
#
# After this runs, tool\smoke_test.ps1 should pass /query.
#
# Env vars:
#   OLLAMA_MODEL   model tag to pull (default: llama3.1:8b)
#                  Lighter alternatives: llama3.2:3b (~1.9 GB) or qwen2.5:3b
#
# Disk note: llama3.1:8b is ~4.7 GB. If the AI's machine is tight on disk,
# set $env:OLLAMA_MODEL = 'llama3.2:3b' before running, AND set the same
# variable before running tool\smoke_test.ps1 so bin/server.dart picks it up.

$ErrorActionPreference = 'Stop'

$model = if ($env:OLLAMA_MODEL) { $env:OLLAMA_MODEL } else { 'llama3.1:8b' }

function Add-OllamaToPath {
  $candidates = @(
    "$env:LOCALAPPDATA\Programs\Ollama",
    'C:\Program Files\Ollama'
  )
  foreach ($p in $candidates) {
    if ((Test-Path $p) -and ($env:Path -notlike "*$p*")) {
      $env:Path = $env:Path + [IO.Path]::PathSeparator + $p
    }
  }
}

function Install-Ollama {
  Write-Host '==> Installing Ollama (~600 MB download, ~2 min)' -ForegroundColor Cyan

  if (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host '   (using winget)'
    & winget install --id=Ollama.Ollama --silent `
      --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
      throw "winget install failed (exit $LASTEXITCODE)"
    }
  } else {
    Write-Host '   (winget unavailable; downloading installer)'
    $installer = Join-Path $env:TEMP 'OllamaSetup.exe'
    Invoke-WebRequest `
      -Uri 'https://ollama.com/download/OllamaSetup.exe' `
      -OutFile $installer
    Start-Process -FilePath $installer -ArgumentList '/S' -Wait
    Remove-Item $installer -ErrorAction SilentlyContinue
  }

  Add-OllamaToPath
}

function Start-OllamaDaemon {
  try {
    Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' `
      -Method Get -TimeoutSec 2 | Out-Null
    return $true
  } catch {
    # Not running yet.
  }

  Write-Host '==> Starting ollama serve in background'
  Start-Process ollama -ArgumentList 'serve' -WindowStyle Hidden | Out-Null

  # Cold start of the Windows tray service can take 30-60s. Be patient.
  $deadlineSec = 90
  for ($i = 0; $i -lt $deadlineSec; $i++) {
    Start-Sleep -Seconds 1
    try {
      Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' `
        -Method Get -TimeoutSec 2 | Out-Null
      Write-Host "   (daemon ready after $i s)"
      return $true
    } catch {
      # Keep waiting.
    }
  }

  # Last-resort fallback: `ollama list` itself wakes the service on Windows.
  Write-Host '   /api/tags still not answering; trying `ollama list` to wake it'
  & ollama list *> $null
  try {
    Invoke-RestMethod -Uri 'http://localhost:11434/api/tags' `
      -Method Get -TimeoutSec 5 | Out-Null
    return $true
  } catch {
    return $false
  }
}

# --- Main ---

Add-OllamaToPath

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
  Install-Ollama
}

if (-not (Get-Command ollama -ErrorAction SilentlyContinue)) {
  Write-Error @'
Ollama installed but not on PATH. The Windows installer normally appends
Ollama to PATH for new shells; you may need to open a new terminal.
'@
  exit 1
}

Write-Host '==> ollama --version'
& ollama --version

if (-not (Start-OllamaDaemon)) {
  Write-Error 'Ollama daemon did not respond on http://localhost:11434 after 20s.'
  exit 1
}

Write-Host ''
Write-Host "==> Pulling model: $model"
Write-Host '   (first time may take 5-10 minutes depending on bandwidth)'
& ollama pull $model
if ($LASTEXITCODE -ne 0) {
  throw "ollama pull $model failed (exit $LASTEXITCODE)"
}

Write-Host ''
Write-Host 'Ollama is ready.' -ForegroundColor Green
Write-Host ''
Write-Host 'If you used a non-default model, also set it before smoke_test:'
Write-Host "  `$env:OLLAMA_MODEL = '$model'"
Write-Host '  powershell -ExecutionPolicy Bypass -File tool\smoke_test.ps1'
