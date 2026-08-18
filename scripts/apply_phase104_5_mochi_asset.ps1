param([string]$ProjectRoot = "C:\flutter project\vonotalky")
$ErrorActionPreference = 'Stop'
$pubspec = Join-Path $ProjectRoot 'pubspec.yaml'
if (-not (Test-Path $pubspec)) { throw "Missing $pubspec" }
$c = Get-Content -Raw -Encoding UTF8 $pubspec
if ($c.Contains('assets/pets/mochi_floating.png')) {
  Write-Host 'Mochi asset already registered.' -ForegroundColor Yellow
  exit 0
}
if ($c -match '(?m)^flutter:\s*$') {
  if ($c -match '(?m)^  assets:\s*$') {
    $c = [regex]::Replace($c, '(?m)^(  assets:\s*)$', "`$1`r`n    - assets/pets/mochi_floating.png", 1)
  } else {
    $c = [regex]::Replace($c, '(?m)^(flutter:\s*)$', "`$1`r`n  assets:`r`n    - assets/pets/mochi_floating.png", 1)
  }
} else { throw 'Could not find flutter: section in pubspec.yaml' }
[IO.File]::WriteAllText($pubspec, $c, [Text.UTF8Encoding]::new($false))
Write-Host 'Registered assets/pets/mochi_floating.png in pubspec.yaml.' -ForegroundColor Green
