param(
  [switch]$SkipBuild,
  [string]$Flutter = "C:\flutter\bin\flutter.bat"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath = Join-Path $projectRoot "debug_log_$timestamp.txt"
$exePath = Join-Path $projectRoot "build\windows\x64\runner\Release\local_ai_chat.exe"

function Write-LogLine {
  param(
    [string]$Line,
    [ConsoleColor]$Color = [ConsoleColor]::Gray
  )

  if ($null -eq $Line) { return }
  Write-Host $Line -ForegroundColor $Color
  Add-Content -LiteralPath $logPath -Value $Line -Encoding UTF8
}

function Write-LogHeader {
  param([string]$Text)
  Write-LogLine ""
  Write-LogLine "============================================================" Cyan
  Write-LogLine $Text Cyan
  Write-LogLine "============================================================" Cyan
}

"" | Set-Content -LiteralPath $logPath -Encoding UTF8
Write-LogHeader "Local AI Chat debug run $timestamp"
Write-LogLine "Project: $projectRoot"
Write-LogLine "Log: $logPath"

if (-not $SkipBuild) {
  Write-LogHeader "Building Windows release"
  & $Flutter build windows --release 2>&1 | ForEach-Object {
    Write-LogLine $_
  }

  if ($LASTEXITCODE -ne 0) {
    Write-LogLine "[CRASH DETECTED] Build failed with exit code: $LASTEXITCODE" Red
    exit $LASTEXITCODE
  }
} else {
  Write-LogHeader "Skipping build"
}

if (-not (Test-Path -LiteralPath $exePath)) {
  Write-LogLine "[CRASH DETECTED] Built executable not found: $exePath" Red
  exit 1
}

Write-LogHeader "Starting app"
Write-LogLine "Executable: $exePath"

$psi = [System.Diagnostics.ProcessStartInfo]::new()
$psi.FileName = $exePath
$psi.WorkingDirectory = Split-Path -Parent $exePath
$psi.UseShellExecute = $false
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.CreateNoWindow = $true

$process = [System.Diagnostics.Process]::new()
$process.StartInfo = $psi

try {
  [void]$process.Start()
  Write-LogLine "Process started. PID: $($process.Id)"

  $stdoutTask = $process.StandardOutput.ReadLineAsync()
  $stderrTask = $process.StandardError.ReadLineAsync()

  while (-not $process.HasExited -or $stdoutTask -ne $null -or $stderrTask -ne $null) {
    if ($stdoutTask -ne $null -and $stdoutTask.IsCompleted) {
      $line = $stdoutTask.Result
      if ($null -eq $line) {
        $stdoutTask = $null
      } else {
        Write-LogLine "[stdout] $line" Gray
        $stdoutTask = $process.StandardOutput.ReadLineAsync()
      }
    }

    if ($stderrTask -ne $null -and $stderrTask.IsCompleted) {
      $line = $stderrTask.Result
      if ($null -eq $line) {
        $stderrTask = $null
      } else {
        Write-LogLine "[stderr] $line" Yellow
        $stderrTask = $process.StandardError.ReadLineAsync()
      }
    }

    if ($stdoutTask -ne $null -or $stderrTask -ne $null) {
      Start-Sleep -Milliseconds 25
    }
  }

  $process.WaitForExit()

  $exitCode = $process.ExitCode
  if ($exitCode -ne 0) {
    Write-Host ""
    Write-Host "[CRASH DETECTED] Exit code: $exitCode" -ForegroundColor Red
    Add-Content -LiteralPath $logPath -Value "[CRASH DETECTED] Exit code: $exitCode" -Encoding UTF8
    Write-Host "Last 50 log lines:" -ForegroundColor Red
    Get-Content -LiteralPath $logPath -Tail 50 | ForEach-Object {
      Write-Host $_ -ForegroundColor Red
    }
    exit $exitCode
  }

  Write-LogLine "[OK] APP exited normally" Green
} finally {
  $process.Dispose()
}
