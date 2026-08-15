# VonoTalky Phase 11.1 — Bottom Sheet Overflow Fix

## Fixed
- Direct-chat long-press action sheet no longer overflows on shorter screens.
- Group-chat long-press action sheet receives the same responsive fix.
- Action sheets can use up to 82% of the current screen height.
- Content becomes vertically scrollable when it cannot fit.
- `isScrollControlled` is enabled so Flutter does not impose the smaller default sheet height.

## Changed files
- `lib/features/home/presentation/widgets/unified_recent_chats.dart`
- `CHANGELOG_PHASE_11_1.md`
