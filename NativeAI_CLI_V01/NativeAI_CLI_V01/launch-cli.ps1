$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Here
$Host.UI.RawUI.WindowTitle = "NativeAI-CLI-0.2.9"
Write-Host "Native AI CLI 0.2.9" -ForegroundColor Cyan
Write-Host "demo backend | UART chat LOCKED | BIT=NO PROGRAM=NO" -ForegroundColor Yellow
Write-Host "COM12 present (FTDI 210319BE776EB). Type: chiller | /status | /help | /exit" -ForegroundColor DarkGray
& (Join-Path $Here "native-ai.ps1") --backend demo --trace full
if ($LASTEXITCODE) { Write-Host "CLI exit $LASTEXITCODE" -ForegroundColor Red }
Write-Host "Press Enter to close..."
[void][Console]::ReadLine()
