# MODE-only UART probe for hs02_lm_path — COM12 @115200
# TX: 0xE0 enter exam, 0x53 status. No cue/addr/winner/grad/answer.
# Decode flags: {mig, pe_alive, lm_path, exam, pe_nib[3:0]}
param(
  [string]$Port = "COM12",
  [int]$Baud = 115200,
  [string]$OutJson = "results/A7-NATIVE-GRAPH/HS02-LMPATH/board_probe_repair.json",
  [string]$BitSha = "",
  [int]$SettleMaxS = 90
)
$ErrorActionPreference = "Stop"
function Decode-Flags([byte]$f) {
  return @{
    mig_calib = ($f -shr 7) -band 1
    pe_alive  = ($f -shr 6) -band 1
    lm_path   = ($f -shr 5) -band 1
    exam_mode = ($f -shr 4) -band 1
    pe_nibble = $f -band 0xF
  }
}
function Probe-Once($sp, $enter) {
  $sp.DiscardInBuffer()
  if ($enter) { $sp.Write([byte[]](0xE0), 0, 1); Start-Sleep -Milliseconds 50 }
  $sp.Write([byte[]](0x53), 0, 1)
  Start-Sleep -Milliseconds 80
  $n = $sp.BytesToRead
  $buf = New-Object byte[] ([Math]::Max($n, 2))
  if ($n -gt 0) { [void]$sp.Read($buf, 0, $n) }
  $rx = ($buf[0..([Math]::Max(0,$n-1))] | ForEach-Object { $_.ToString("X2") }) -join ""
  $status = if ($n -ge 1) { $buf[0] } else { 0 }
  $flags  = if ($n -ge 2) { $buf[1] } else { 0 }
  $d = Decode-Flags ([byte]$flags)
  return @{
    rx = $rx; status = ("0x{0:X2}" -f $status); flags = ("0x{0:X2}" -f $flags)
    exam_mode = $d.exam_mode; lm_path = $d.lm_path; mig_calib = $d.mig_calib
    pe_alive = $d.pe_alive; pe_nibble = $d.pe_nibble
  }
}

$sp = New-Object System.IO.Ports.SerialPort $Port, $Baud, None, 8, One
$sp.ReadTimeout = 500
$sp.WriteTimeout = 500
$sp.Open()
$probes = @()
$t0 = Get-Date
# early status-only
$probes += (Probe-Once $sp $false) + @{ label = "t0_status_only"; t_s = 0 }
Start-Sleep -Seconds 5
$probes += (Probe-Once $sp $true) + @{ label = "t5_enter_status"; t_s = 5 }
$long = @()
foreach ($t in 15, 30, 45, 60, 90) {
  $wait = $t - [int]((Get-Date) - $t0).TotalSeconds
  if ($wait -gt 0) { Start-Sleep -Seconds $wait }
  $p = Probe-Once $sp $true
  $p.label = "t${t}_enter_status"
  $p.t_s = $t
  $probes += $p
  $long += $p
  if ($p.lm_path -ne 0) { break }
}
$sp.Close()
$final = $probes[-1]
$pass = ($final.lm_path -ne 0) -and ($final.exam_mode -eq 1) -and ($final.status -eq "0x91")
$result = @{
  ts_utc = (Get-Date).ToUniversalTime().ToString("o")
  board = "Digilent Arty A7-100T xc7a100tcsg324-1"
  jtag_serial_expected = "210319BE776EA"
  uart = @{
    port = $Port; baud = $Baud
    tx_hex = @("E0", "53")
    all_probes = $probes
    long_settle = $long
    rx_hex_primary = $final.rx
    status = $final.status
    exam_mode = $final.exam_mode
    lm_path = $final.lm_path
    mig_calib = $final.mig_calib
    pe_alive = $final.pe_alive
    pe_nibble = $final.pe_nibble
    flags_byte = $final.flags
  }
  programmed_sha256 = $BitSha
  host_uart_driver = "mode_bytes_only_inline_probe"
  host_graded_answers = $false
  tinygpt = "ABSENT"
  board_pass = $false
  unknown_lm_path_ne_0 = [bool]($final.lm_path -ne 0)
  result = $(if ($pass) { "PASS_NARROW" } else { "FAIL" })
  reason = $(if ($pass) {
    "UART lm_path!=0 after MODE-only E0/S; exam framing 0x91; TinyGPT ABSENT LIMIT; no BOARD_PASS"
  } else {
    "lm_path remains 0 or framing fail after settle; honest FAIL"
  })
}
$dir = Split-Path $OutJson -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
($result | ConvertTo-Json -Depth 8) | Set-Content -Path $OutJson -Encoding UTF8
Write-Output ("RESULT=" + $result.result + " lm_path=" + $final.lm_path + " rx=" + $final.rx + " out=" + $OutJson)
