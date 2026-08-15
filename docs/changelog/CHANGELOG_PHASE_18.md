# VonoTalky Phase 18 — Message Search Upgrade

## Added
- Enhanced private-chat search page.
- Keyword highlighting.
- Filters for All, Text, Photos, Files and Voice.
- File-name searching.
- Result cards show message type and date/time.
- Clear empty, no-result and error states.
- Tapping a result still returns its message id for jump-to-message behavior.

## Safe rollout
- The old `chat_search_page.dart` is left untouched.
- `RealChatRoomPage` now opens `AdvancedChatSearchPage`.

## Compatibility
- Continues directly from Phase 17.2.
- No new packages.
- No Firestore Rules changes.
