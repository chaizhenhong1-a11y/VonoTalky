param(
    [string]$ProjectRoot = "C:\flutter project\vonotalky"
)

$ErrorActionPreference = 'Stop'

$chatPath = Join-Path $ProjectRoot 'lib\features\home\presentation\pages\chat_home_page.dart'
$contactsPath = Join-Path $ProjectRoot 'lib\features\contacts\presentation\pages\contacts_page.dart'

if (-not (Test-Path $chatPath)) {
    throw "Missing file: $chatPath"
}
if (-not (Test-Path $contactsPath)) {
    throw "Missing file: $contactsPath"
}

$chat = Get-Content -Raw -Encoding UTF8 $chatPath
$contacts = Get-Content -Raw -Encoding UTF8 $contactsPath

# Canonical shared header geometry. Chats already uses these values in the
# current baseline; enforce them so future small drift is corrected too.
$chatUpdated = $chat.Replace(
    'padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),',
    'padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),'
).Replace(
    'padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),',
    'padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),'
)

$contactsUpdated = $contacts.Replace(
    'padding: const EdgeInsets.fromLTRB(18, 12, 10, 6),',
    'padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),'
).Replace(
    'padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),',
    'padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),'
)

if ($contactsUpdated -eq $contacts) {
    $alreadyFixed = $contacts.Contains('padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),') -and
                    $contacts.Contains('padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),')
    if (-not $alreadyFixed) {
        throw 'Contacts header layout did not match the expected current baseline. No files were changed.'
    }
}

# Write only after validation succeeds.
[System.IO.File]::WriteAllText($chatPath, $chatUpdated, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText($contactsPath, $contactsUpdated, [System.Text.UTF8Encoding]::new($false))

Write-Host 'Phase 104.2 header stability fix applied.' -ForegroundColor Green
Write-Host 'Chats and Contacts now use the same title/search vertical geometry.'
Write-Host ''
Write-Host 'Next:'
Write-Host '  dart format lib/features/home/presentation/pages/chat_home_page.dart lib/features/contacts/presentation/pages/contacts_page.dart'
Write-Host '  flutter analyze'
