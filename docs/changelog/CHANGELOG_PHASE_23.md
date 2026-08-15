# VonoTalky Phase 23 — Group Message Editing

## Added

- Long-press your own group text message and choose `Edit message`.
- Edit dialog with multiline support.
- Empty edits are blocked.
- Unchanged edits are ignored.
- Successfully edited messages show an `edited` label beside the time.
- Existing Reply, React, Pin, Message info and Recall actions remain available.

## Firestore

- Group message sender updates now allow `editedAt`.
- Deploy the updated Firestore Rules after applying this patch.

## Compatibility

- Continues directly from Phase 22.
- No new Flutter packages.
- No schema migration.
