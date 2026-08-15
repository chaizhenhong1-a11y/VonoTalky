# VonoTalky Phase 17.1 — Pinned Messages Sync Fix

## Fixed
- New pinned messages now use a simple read/merge/write flow instead of a Firestore transaction.
- Management page and top banner use the same pinned-message parser.
- Legacy Phase 16 single-pin data remains readable.
- Firestore map/list values are normalized defensively for Flutter Web.
- Pin failures now show the actual Firestore error instead of silently appearing successful.

## Compatibility
- Continues directly from Phase 17.
- No package changes.
- No Firestore Rules changes.
