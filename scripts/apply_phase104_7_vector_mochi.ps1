param([string]$ProjectRoot = "C:\flutter project\vonotalky")
$ErrorActionPreference = 'Stop'
$pubspec = Join-Path $ProjectRoot 'pubspec.yaml'
if (Test-Path $pubspec) {
  $c = Get-Content -Raw -Encoding UTF8 $pubspec
  $c = $c.Replace("`r`n    - assets/pets/mochi/", '')
  $c = $c.Replace("`n    - assets/pets/mochi/", '')
  $c = $c.Replace("`r`n    - assets/pets/mochi_floating.png", '')
  $c = $c.Replace("`n    - assets/pets/mochi_floating.png", '')
  [IO.File]::WriteAllText($pubspec, $c, [Text.UTF8Encoding]::new($false))
}
$oldDir = Join-Path $ProjectRoot 'assets\pets\mochi'
if (Test-Path $oldDir) { Remove-Item $oldDir -Recurse -Force }
$oldSingle = Join-Path $ProjectRoot 'assets\pets\mochi_floating.png'
if (Test-Path $oldSingle) { Remove-Item $oldSingle -Force }
Write-Host 'Removed obsolete Mochi sprite assets. Vector Mochi needs no image files.' -ForegroundColor Green
