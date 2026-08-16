**# Changelog**

All notable changes to VonoTalky are documented in this file.

The format follows [Keep a Changelog]\(https\://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning]\(https\://semver.org/).

**## [0.3.0] - 2026-08-16**

**### Added**

**#### Direct-message navigation and selection**

\- Added jump-to-first-message navigation for direct conversations.
\- Added a dedicated multi-select mode with checkmark-based message selection.
\- Added a top-level Select All / Clear Selection control that only counts selectable messages.
\- Added labeled multi-select actions for Reply, Forward, Save, Delete and More.
\- Added contextual More actions for Copy text, Copy with time and Pin.
\- Added selection-aware More behavior so text-copy actions are hidden when the current selection contains no copyable text.
- Added jump-to-date navigation with date picking, nearest-message lookup and message highlighting.
- Added smart chat back handling that exits selection mode or closes the Emoji picker before leaving the conversation.
- Added persistent multi-select mode that remains active even when zero messages are selected.
- Added WeChat-style circular message selectors and tap-to-toggle selection behavior.
- Hid the message composer, recording controls and Emoji picker while multi-select mode is active.
- Disabled invalid bulk actions when no messages are selected.

**#### Message deletion and recall**

\- Unified multi-select deletion behind a single Delete action.
\- Added separate Delete for me and Recall for everyone choices.
\- Kept destructive actions behind a second confirmation step.
\- Removed Recall from the More menu to avoid duplicate destructive actions.
\- Added mixed-selection recall support so only messages sent by the current user are recalled when received messages are selected at the same time.
\- Unified the single-message delete flow with the same Delete for me / Recall for everyone model.
\- Hid Recall for everyone entirely when a single selected message was sent by the other participant.

**### Changed**

**#### Multi-select workflow**

\- Simplified the multi-select toolbar while keeping Select All exclusively in the top app bar.
\- Improved Select All state detection so recalled or deleted messages do not prevent Clear Selection from appearing correctly.
\- Improved bulk Save so one failed save no longer stops the remaining selected messages from being saved.
\- Improved bulk Forward so recalled or deleted messages are skipped instead of being forwarded.
\- Improved bulk Pin so recalled or deleted messages are skipped instead of being pinned.
\- Added partial-success feedback for bulk Save, Forward and Pin operations.

**#### Profile and settings**

\- Cleaned up the Profile page after duplicate settings controls were identified.
\- Adjusted the user-information card layout to prevent profile information from overlapping the biography area.

**#### Project maintenance

- Reorganized setup documentation under `docs/setup/`.
- Moved migration documentation under `docs/migration/`.
- Moved maintenance PowerShell scripts under `scripts/maintenance/`.
- Consolidated Phase 25–52 development notes into the main project changelog.

### Fixed**

\- Completed project-wide Dart analyzer cleanup and reached \`No issues found\`.
\- Replaced unnecessary multi-underscore callback parameters reported by the analyzer.
\- Added missing braces around flow-control statements reported by the analyzer.
\- Migrated the profile-visibility selector away from deprecated per-tile radio group handling.
\- Fixed Select All calculations when non-selectable messages are present.
\- Fixed multi-select actions attempting to operate on recalled or deleted messages.
\- Fixed profile layout regressions where the user-information section could cover biography content.
\- Fixed the Phase 45 mixed-recall implementation syntax issue caused by a missing semicolon.

**## [0.2.0] - 2026-08-15**

**### Added**

**#### Conversation management**

\- Added direct-chat and group-chat quick actions from Recent Chats.
\- Added pin/unpin, archive/unarchive and mark read/unread controls.
\- Added swipe actions for archive and read-state changes.
\- Added a dedicated Archived Chats manager for direct chats and groups.
\- Added draft previews for direct chats and persistent debounced drafts for groups.

**#### Pinned messages**

\- Added pinned messages for direct chats and group chats.
\- Added a pinned-message banner with jump-to-message navigation.
\- Added support for multiple pinned messages per conversation.
\- Added a dedicated pinned-message management page with individual unpin actions.
\- Preserved compatibility with legacy single-pin data.

**#### Search**

\- Added advanced private-chat message search with keyword highlighting.
\- Added filters for text, photos, files and voice messages.
\- Added file-name matching and jump-to-message navigation from search results.
\- Added group-message search by keyword, sender name and file name.
\- Improved home search so contacts and recent chats respond to the same search query.
\- Added clear-search and matching-state UI on the home page.

**#### Group messaging**

\- Added group message reactions with emoji counts and per-user toggling.
\- Added Message Info for sent group messages, including sent time and seen-by members.
\- Added editing for the sender's own group text messages.
\- Added an \`edited\` indicator for modified group messages.

**### Changed**

\- Recent Chats now preserves pinned conversations above normal conversations.
\- Draft activity can influence conversation ordering when a saved draft is newer than the last message.
\- Group and direct-chat preferences reuse each user's \`contactPreferences\` subcollection.
\- Private-chat search now opens the enhanced search experience.
\- Pinned-message management reads directly from the correct preference document.

**### Fixed**

\- Fixed Archived Chats patch compatibility after Recent Chats changes.
\- Fixed Recent Chats action-sheet overflow on shorter screens.
\- Fixed pinned-message synchronization on Flutter Web.
\- Fixed pinned-message manager reads when Firestore already contained pinned data.
\- Fixed stale Flutter widget-test scaffolding that still referenced the removed default \`MyApp\`.
\- Fixed duplicate default \`FloatingActionButton\` Hero tags.
\- Removed analyzer warnings caused by stale imports and unused helper declarations.

**### Security**

\- Updated group-message Firestore permissions to support member reactions.
\- Updated sender-only group-message permissions to support \`editedAt\`.
\- Preserved participant/member access restrictions for conversations and groups.

**## [0.1.0] - 2026-08-14**

**### Added**

**#### Application foundation**

\- Established a professional feature-first Flutter project structure.
\- Added centralized Material 3 theme, application colors, navigation and routing.
\- Added a persistent four-tab application shell for Chats, Contacts, Groups and Profile.
\- Preserved page state across bottom-navigation tab changes with an \`IndexedStack\`.

**#### Authentication and onboarding**

\- Added an authentication welcome screen with separate Sign Up and Log In actions.
\- Added Firebase email/password registration, login, logout and authentication gating.
\- Added first-run onboarding flow and persisted onboarding completion state.
\- Added the approved purple landscape background and near-transparent glassmorphism forms.
\- Added reusable authentication background and form-field components.

**#### Home and conversations**

\- Added the pink-to-purple gradient chat home design.
\- Added contact and conversation search entry points.
\- Added Top Contacts and a unified Recent Chats list for direct and group conversations.
\- Added unread counters, timestamps, message previews, online indicators and a New Chat menu.
\- Added real-time unread badge aggregation on the bottom navigation bar.

**#### Direct messaging**

\- Added real-time one-to-one conversations backed by Cloud Firestore.
\- Added responsive message bubbles with content-based width and sender alignment.
\- Added text, image, file and voice messages.
\- Added cancellable voice recording with a single adaptive Send/Record action button.
\- Added message replies, reactions, editing, deletion, forwarding and saved messages.
\- Added conversation search, shared-media browsing and a full-screen media viewer.
\- Added read state, delivery state and typing indicators.
\- Added a functional 64-item Emoji picker that inserts at the current cursor position.

**#### Group messaging**

\- Added group creation, group list, group details and real-time group conversations.
\- Added group text, image, file and voice messages.
\- Added replies and the shared adaptive Send/Record composer design.
\- Added the same functional Emoji picker used by direct conversations.
\- Integrated group conversations into the home Recent Chats feed.

**#### Contacts and friend requests**

\- Added a searchable contacts directory with alphabetical navigation.
\- Added user search by username, email and display name.
\- Added friend-request sending, receiving, accepting and rejecting.
\- Added contact profile details and direct chat actions.
\- Added blocked-user management.

**#### Profile and settings**

\- Added the approved purple header and pink-to-purple profile gradient.
\- Added profile avatar, online status, biography and user-information card.
\- Added editable display name, username, phone, birthday, bio and profile photo.
\- Added settings, privacy and security pages.
\- Added a visible logout action with presence cleanup.

**#### Media, storage and platform support**

\- Added camera/gallery image selection and Firebase Storage uploads.
\- Added cross-platform file selection and message attachments.
\- Added platform-specific media transfer implementations for mobile, desktop and web.
\- Added Firebase Storage rules for authenticated chat and profile media access.

**#### Notifications**

\- Added Firebase Cloud Messaging initialization and permission handling.
\- Added per-device notification token registration and token refresh handling.
\- Added foreground in-app notification banners.
\- Added notification routing into direct and group chat rooms.

**#### Presence**

\- Added application-wide online/offline presence management.
\- Added a 30-second presence heartbeat.
\- Added automatic stale-session detection after 90 seconds without a heartbeat.
\- Added periodic contact presence refresh so force-closed clients no longer remain online.

**### Changed**

\- Moved presence lifecycle ownership from the home page to the persistent application shell.
\- Consolidated direct and group conversations into a single home feed.
\- Converted the original Groups tab into a dedicated group-management area.
\- Removed the duplicated bottom navigation bar from conversation screens.
\- Unified Send and Record into one light-purple composer action.
\- Moved reply previews outside the text input and simplified their visual treatment.
\- Aligned direct-chat headers with the group-chat identity layout.
\- Updated message bubbles to size themselves according to their content.

**### Fixed**

\- Fixed invalid \`const NavigationBar\` construction.
\- Fixed Firebase deployment configuration for Firestore and Storage rules.
\- Fixed missing media and file-picker package integrations.
\- Fixed Android stale plugin-registration build failures after dependency changes.
\- Fixed blank Edge startup caused by platform initialization and configuration issues.
\- Fixed uploaded profile photos not refreshing in the interface.
\- Fixed direct and group chat composer layout inconsistencies.
\- Fixed online indicators remaining active after a browser, app or device was force-closed.
\- Replaced the Emoji placeholder snackbar with a working picker.

**### Security**

\- Added authenticated Firestore access rules for users, contacts, requests, conversations and groups.
\- Added authenticated Firebase Storage rules for profile, chat and group media.
\- Restricted presence and profile updates to the owning authenticated user.