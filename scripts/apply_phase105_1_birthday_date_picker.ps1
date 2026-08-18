param(
  [string]$ProjectRoot = "C:\flutter project\vonotalky"
)

$ErrorActionPreference = 'Stop'

$path = Join-Path $ProjectRoot 'lib\features\profile\presentation\pages\edit_profile_page.dart'
if (-not (Test-Path $path)) {
  throw "Missing file: $path"
}

$content = Get-Content -Raw -Encoding UTF8 $path

# Ensure intl import exists for display formatting.
if ($content -notmatch "package:intl/intl.dart") {
  $content = $content -replace `
    "(import 'package:flutter/material.dart';)", `
    "`$1`r`nimport 'package:intl/intl.dart';"
}

# Add selected birthday state if not already present.
if ($content -notmatch "DateTime\? _selectedBirthday") {
  $content = $content -replace `
    "(class _EditProfilePageState extends State<EditProfilePage> \{)", `
    "`$1`r`n  DateTime? _selectedBirthday;"
}

# Initialize selected birthday from existing data if possible.
if ($content -notmatch "_selectedBirthday = _parseBirthday") {
  $content = $content -replace `
    "(void initState\(\) \{\s*super\.initState\(\);)", `
    "`$1`r`n    _selectedBirthday = _parseBirthday(widget.data['birthDate'] as String?);"
}

# Add helper methods before build().
if ($content -notmatch "Future<void> _pickBirthday") {
  $helpers = @'
  DateTime? _parseBirthday(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw.trim());
  }

  String _birthdayStorageValue(DateTime? value) {
    if (value == null) return '';
    return DateFormat('yyyy-MM-dd').format(value);
  }

  String _birthdayDisplayValue(BuildContext context, DateTime? value) {
    if (value == null) return 'Add birthday';
    final locale = Localizations.localeOf(context).toLanguageTag();
    return DateFormat.yMMMd(locale).format(value);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final initial = _selectedBirthday ?? DateTime(now.year - 18, now.month, now.day);

    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      helpText: 'Select birthday',
      cancelText: 'Cancel',
      confirmText: 'Done',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedBirthday = DateTime(
        selected.year,
        selected.month,
        selected.day,
      );
    });
  }

'@
  $content = $content -replace `
    "(\s+@override\s+Widget build\(BuildContext context\))", `
    "`r`n$helpers`$1"
}

# Replace a birthday TextField/TextFormField block when present.
# This intentionally targets common implementations by looking for labelText: 'Birthday'.
$birthdayPattern = "(?s)(TextFormField|TextField)\s*\([^)]*?decoration:\s*[^;]*?labelText:\s*'Birthday'[^;]*?\)"
if ([regex]::IsMatch($content, $birthdayPattern)) {
  $replacement = @'
InkWell(
            onTap: _pickBirthday,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Birthday',
                suffixIcon: Icon(Icons.calendar_month_rounded),
              ),
              child: Text(
                _birthdayDisplayValue(context, _selectedBirthday),
                style: TextStyle(
                  color: _selectedBirthday == null
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
'@
  $content = [regex]::Replace($content, $birthdayPattern, $replacement, 1)
}

# If a birthDate controller exists, synchronize it immediately before save/update calls.
# This covers common controller names without assuming the exact one.
$controllerCandidates = @(
  'birthDateController',
  'birthdayController',
  '_birthDateController',
  '_birthdayController'
)

foreach ($name in $controllerCandidates) {
  if ($content.Contains($name)) {
    $saveNeedle = "await "
    # Add assignment once before the first await inside a save-like method if not already there.
    if ($content -notmatch [regex]::Escape("$name.text = _birthdayStorageValue")) {
      $content = $content -replace `
        "(Future<[^>]*>\s+_[A-Za-z0-9_]*(save|update)[A-Za-z0-9_]*\([^)]*\)\s+async\s+\{)", `
        "`$1`r`n    $name.text = _birthdayStorageValue(_selectedBirthday);"
    }
    break
  }
}

# Fallback: if save writes a map containing birthDate directly, replace it with the selected value.
$content = $content -replace `
  "'birthDate'\s*:\s*[^,\r\n}]+", `
  "'birthDate': _birthdayStorageValue(_selectedBirthday)"

[IO.File]::WriteAllText(
  $path,
  $content,
  [Text.UTF8Encoding]::new($false)
)

Write-Host 'Phase 105.1 birthday date picker patch applied.' -ForegroundColor Green
Write-Host ''
Write-Host 'Next:'
Write-Host '  dart format lib/features/profile/presentation/pages/edit_profile_page.dart'
Write-Host '  flutter analyze'
