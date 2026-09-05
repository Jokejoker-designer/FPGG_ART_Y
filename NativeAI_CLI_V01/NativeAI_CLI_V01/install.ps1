$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $Here

Write-Host "Native AI CLI installer" -ForegroundColor Cyan
Write-Host "Folder: $Here"

$Python = $null
# Prefer a working python.exe. The py launcher may point at a broken 3.13 install.
if (Get-Command python -ErrorAction SilentlyContinue) {
    $Python = "python"
    & python --version
} elseif (Get-Command py -ErrorAction SilentlyContinue) {
    $Python = "py"
    & py -3 --version
} else {
    throw "Python 3 was not found. Install Python 3 first, then rerun install.ps1."
}

if (-not (Test-Path ".venv\Scripts\python.exe")) {
    Write-Host "Creating local virtual environment..." -ForegroundColor Yellow
    if ($Python -eq "py") { & py -3 -m venv .venv }
    else { & python -m venv .venv }
    & (Join-Path $Here ".venv\Scripts\python.exe") -c "print('venv-ok')"
}

$ShortcutDir = [Environment]::GetFolderPath("Desktop")
$ShortcutPath = Join-Path $ShortcutDir "NativeAI CLI.lnk"
try {
    $Wsh = New-Object -ComObject WScript.Shell
    $Sc = $Wsh.CreateShortcut($ShortcutPath)
    $Sc.TargetPath = "powershell.exe"
    $Sc.Arguments = "-NoExit -ExecutionPolicy Bypass -File `"$Here\native-ai.ps1`" --backend demo --trace full"
    $Sc.WorkingDirectory = $Here
    $Sc.WindowStyle = 1
    $Sc.Description = "Native AI V3.1 development console (U6 TYPECLASS XSim PASS replay)"
    $Sc.Save()
    Write-Host "Desktop shortcut: $ShortcutPath" -ForegroundColor Green
} catch {
    Write-Host "Desktop shortcut skipped: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installed. No internet packages are required." -ForegroundColor Green
Write-Host "Run:"
Write-Host "  .\native-ai.ps1" -ForegroundColor Cyan
Write-Host ""
Write-Host "Optional:"
Write-Host "  .\native-ai.ps1 --backend demo --trace full"
Write-Host "  .\native-ai.ps1 --backend xsim --trace full"
Write-Host "  .\native-ai.ps1 --backend uart --trace full"
