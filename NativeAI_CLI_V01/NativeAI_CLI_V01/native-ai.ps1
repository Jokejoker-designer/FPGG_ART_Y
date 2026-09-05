$ErrorActionPreference = "Stop"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Py = Join-Path $Here ".venv\Scripts\python.exe"
if (-not (Test-Path $Py)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        & py -3 (Join-Path $Here "native_ai_cli.py") @args
        exit $LASTEXITCODE
    }
    & python (Join-Path $Here "native_ai_cli.py") @args
    exit $LASTEXITCODE
}
& $Py (Join-Path $Here "native_ai_cli.py") @args
exit $LASTEXITCODE
