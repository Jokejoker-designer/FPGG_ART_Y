$root = "D:\Jetking_sem4\SEM_4\arty-a7-online-lm\build\out"
$exp = @{
  "arty_a7_lm00.bit" = "449A330BD2E23E1D9714ECF94142A0555914D6C76EDE6310EF347A3596534783"
  "arty_a7_lm01.bit" = "96065A174F22B6F79B6A04B79EBA4DDEF094B2BFAF36F5C93F0C376C679507B8"
  "arty_a7_lm02.bit" = "7CEBA854BDE500DDC87C4742315C45562CB5902C6F66377BCE499DA43BD95CC4"
  "arty_a7_lm03.bit" = "C98B7C85814C8D4C57CA5E4ED1C9C411BC71EBF2991ABA1B210B9347509F23D1"
  "arty_a7_lm04r5.bit" = "A177E0989956DF08C7150E451984C914E1D53B1FCF96A49EBEC68CE8497A55F8"
  "arty_a7_lm05.bit" = "1AA0B5C481B0ADF3CAA599F081B430AF3C28A26FB4715DC56A0D25D940548F51"
}
foreach ($n in @("arty_a7_lm00.bit","arty_a7_lm01.bit","arty_a7_lm02.bit","arty_a7_lm03.bit","arty_a7_lm04r5.bit","arty_a7_lm05.bit","arty_a7_lm06.bit")) {
  $p = Join-Path $root $n
  $h = (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash
  if ($exp.ContainsKey($n)) {
    Write-Output ("{0} {1} match={2}" -f $n, $h, ($h -eq $exp[$n]))
  } else {
    Write-Output ("{0} {1}" -f $n, $h)
  }
}
Write-Output "---PORTS---"
Get-CimInstance Win32_SerialPort | ForEach-Object { Write-Output ("{0} {1}" -f $_.DeviceID, $_.Name) }
Get-PnpDevice -Class Ports -Status OK -ErrorAction SilentlyContinue | ForEach-Object { Write-Output $_.Name }
