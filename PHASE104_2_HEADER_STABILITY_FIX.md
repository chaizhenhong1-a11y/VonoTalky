# Phase 104.2 — Home Header Stability Fix

This hotfix continues directly from Phase 104.1.

## Problem

Recent Chats and Contacts used nearly identical but not identical header spacing.
The title row differed by 2 px at the top and the search row differed by 2 px
at the bottom. When switching tabs, `VonoTalky` and the search field therefore
moved visibly even though the designs looked almost the same.

## Fix

Both tabs now use the same header geometry:

- Title row: `EdgeInsets.fromLTRB(18, 14, 10, 6)`
- Search row: `EdgeInsets.fromLTRB(18, 4, 18, 8)`

The page-specific right-side actions are preserved.

## Apply

Extract the ZIP over:

`C:\flutter project\vonotalky`

Then run once:

```powershell
cd "C:\flutter project\vonotalky"
powershell -ExecutionPolicy Bypass -File .\scripts\apply_phase104_2_header_stability.ps1

dart format lib/features/home/presentation/pages/chat_home_page.dart lib/features/contacts/presentation/pages/contacts_page.dart
flutter analyze
```

The apply script is intentionally used for this hotfix so it patches your local
Phase 104.1 tree without replacing either full page with an older GitHub copy.
