param([string]$ProjectRoot = "C:\flutter project\vonotalky")
$ErrorActionPreference = 'Stop'
$pubspec = Join-Path $ProjectRoot 'pubspec.yaml'
if (-not (Test-Path $pubspec)) { throw "Missing $pubspec" }

$c = Get-Content -Raw -Encoding UTF8 $pubspec
$c = $c.Replace('    - assets/pets/mochi_floating.png', '    - assets/pets/mochi/')
if (-not $c.Contains('    - assets/pets/mochi/')) {
  if ($c -match '(?m)^  assets:\s*$') {
    $c = [regex]::Replace(
      $c,
      '(?m)^(  assets:\s*)$',
      "`$1`r`n    - assets/pets/mochi/",
      1
    )
  } elseif ($c -match '(?m)^flutter:\s*$') {
    $c = [regex]::Replace(
      $c,
      '(?m)^(flutter:\s*)$',
      "`$1`r`n  assets:`r`n    - assets/pets/mochi/",
      1
    )
  } else {
    throw 'Could not find flutter/assets section.'
  }
}
[IO.File]::WriteAllText($pubspec, $c, [Text.UTF8Encoding]::new($false))

$oldAsset = Join-Path $ProjectRoot 'assets\pets\mochi_floating.png'
if (Test-Path $oldAsset) {
  Remove-Item $oldAsset -Force
}

Write-Host 'Phase 104.6 Mochi Actor assets registered.' -ForegroundColor Green
