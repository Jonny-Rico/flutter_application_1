$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ud = Join-Path $env:TEMP "chrome-shop-mockups-2"
New-Item -ItemType Directory -Force -Path $ud | Out-Null
$files = Get-ChildItem (Join-Path $dir "*.html") | Sort-Object Name
foreach ($f in $files) {
  $out = Join-Path $dir ($f.BaseName + ".png")
  $url = "file:///" + ($f.FullName.Replace('\', '/'))
  Write-Host "SHOT $($f.Name)"
  $p = Start-Process -FilePath $chrome -ArgumentList @(
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--force-device-scale-factor=2",
    "--window-size=390,844",
    "--virtual-time-budget=8000",
    "--no-first-run",
    "--user-data-dir=$ud",
    "--screenshot=$out",
    $url
  ) -Wait -PassThru
  if (Test-Path $out) {
    Write-Host "  ok $([math]::Round((Get-Item $out).Length/1KB)) KB exit=$($p.ExitCode)"
  } else {
    Write-Host "  MISSING exit=$($p.ExitCode)"
  }
}
