$ErrorActionPreference = "Stop"

if (-not (Test-Path ".\pubspec.yaml")) {
    Write-Host "ERROR: Please run this script from the VonoTalky project root." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== VonoTalky Phase 26: Analyzer Cleanup ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/4] Previewing Dart automatic fixes..." -ForegroundColor Yellow
dart fix --dry-run
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "[2/4] Applying Dart automatic fixes..." -ForegroundColor Yellow
dart fix --apply
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "[3/4] Formatting only Phase 26 affected files..." -ForegroundColor Yellow

$files = @(
    "lib/features/auth/presentation/widgets/auth_background.dart",
    "lib/features/chat/presentation/pages/advanced_chat_search_page.dart",
    "lib/features/chat/presentation/pages/chat_search_page.dart",
    "lib/features/chat/presentation/pages/media_viewer_page.dart",
    "lib/features/chat/presentation/pages/pinned_messages_page.dart",
    "lib/features/chat/presentation/pages/real_chat_room_page.dart",
    "lib/features/chat/presentation/pages/saved_messages_page.dart",
    "lib/features/chat/presentation/pages/shared_media_page.dart",
    "lib/features/contacts/presentation/pages/add_contact_page.dart",
    "lib/features/contacts/presentation/pages/contacts_page.dart",
    "lib/features/contacts/presentation/pages/friend_requests_page.dart",
    "lib/features/groups/data/services/group_service.dart",
    "lib/features/groups/presentation/pages/group_chat_room_page.dart",
    "lib/features/groups/presentation/pages/group_chat_search_page.dart",
    "lib/features/home/presentation/pages/archived_chats_page.dart",
    "lib/features/home/presentation/pages/chat_home_page.dart",
    "lib/features/home/presentation/widgets/unified_recent_chats.dart",
    "lib/features/profile/presentation/pages/blocked_users_page.dart",
    "lib/features/profile/presentation/pages/privacy_security_page.dart"
)

$existingFiles = @()
foreach ($file in $files) {
    if (Test-Path $file) {
        $existingFiles += $file
    }
}

if ($existingFiles.Count -gt 0) {
    dart format $existingFiles
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

Write-Host ""
Write-Host "[4/4] Running flutter analyze..." -ForegroundColor Yellow
flutter analyze
$analyzeExit = $LASTEXITCODE

Write-Host ""
if ($analyzeExit -eq 0) {
    Write-Host "Phase 26 complete: analyzer is clean." -ForegroundColor Green
} else {
    Write-Host "Phase 26 completed automatic fixes, but analyzer still reports items." -ForegroundColor Yellow
    Write-Host "Copy the remaining analyzer output back to ChatGPT for the final targeted cleanup."
}

Write-Host ""
Write-Host "Review changes with:" -ForegroundColor Cyan
Write-Host "  git diff"
Write-Host ""
Write-Host "If everything is correct, create the Phase 26 patch with:" -ForegroundColor Cyan
Write-Host '  git diff --binary > "$env:USERPROFILE\Downloads\vonotalky_phase26_analyzer_cleanup.patch"'

exit $analyzeExit
