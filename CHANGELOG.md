# Changelog

All notable changes to VonoTalky are documented in this file.

## [Unreleased]

### Changed

- Phase 105.2.5 makes the Chats home screen accent UI follow the active app theme color.
- Top Contacts avatar rings, placeholder avatar colors, Archived Chats, pin/group/draft accents, unread badges, swipe actions, action icons, and empty-state icons now derive from `Theme.of(context).colorScheme.primary`.
- Online presence indicators remain green because they represent status rather than the selected theme color.


### Changed

- Phase 105.2.4 makes the Settings Sign Out row follow the app's purple theme.
- The row now uses a primary-color icon, light primary icon container, normal text, neutral border, and neutral chevron.
- Red is reserved for the final confirmation action after the user taps Sign Out.


### Changed

- Phase 105.2.3 moves Sign Out out of the Profile page and into the bottom of Settings.
- Profile is now focused only on identity, personal information, QR code, and pet showcase content.
- Settings now owns the account exit action with a dedicated red Sign Out row.
- Existing sign-out confirmation, presence-offline update, and Firebase Auth sign-out behavior are preserved.


### Fixed

- Phase 105.2.2 fixes bottom overflow in the Profile Pet Showcase badge cards.
- Increased showcase row height so pet name and level fit on compact visitor profiles without clipping.
- Slightly reduced badge width, icon size, padding, and text size for a cleaner collectible-badge proportion.
- Pet showcase data, public visibility, selection limit, and visitor display behavior are unchanged.


### Fixed

- Phase 105.2.1 adds the public Pet Showcase directly to the real `ContactDetailPage` implementation instead of relying on a fragile one-time patch script.
- Visitor profiles now display the selected pet badges immediately after the public contact information card.
- Empty showcases remain hidden so visitor profiles stay clean.
- No private contact notes, pet documents, or private pet state are exposed.


### Changed

- Phase 105.2 replaces the previous single Pet profile card/toggle with a badge-style Pet Showcase.
- Users can choose up to 3 owned pets to display publicly on their profile.
- Pet showcase items are deliberately denormalized into the public user profile document so visitors can see the selected badge summary without gaining access to private `sharedPets` data.
- Contact Detail pages can display the selected public pet badges for other users.

### Added

- Added a Pet Showcase editor with multi-select and a maximum of 3 displayed pets.
- Added reusable `ProfilePetShowcase` badge UI for both own Profile and visitor Profile.
- Added `profilePetShowcase` user-document field containing only `petId`, `name`, and `level` summaries.


### Fixed

- Phase 105.1.2 fixes the Profile QR Code bottom sheet overflowing on short/small viewports.
- QR size now scales with available screen height and stays between 150 px and 210 px.
- Added a safe maximum sheet height, scrolling fallback, and bottom SafeArea spacing.
- QR Code remains square and readable without being clipped by the bottom navigation/system area.
- Added the VonoTalky user ID below the QR for manual verification/copying.


### Fixed

- Phase 105.1.1 replaces the incomplete birthday patch with a full `EditProfilePage` implementation.
- Removed the accidental `intl` dependency and all `DateFormat` usage.
- Birthday now uses the native Flutter date picker instead of a free-text field.
- Saving writes Birthday directly as `yyyy-MM-dd`.
- Existing legacy `DD/MM/YYYY` birthday values are also parsed when opening Edit Profile.
- Added a clear-birthday action without reopening the keyboard.


### Changed

- Phase 105.1 changes Birthday editing from free-text input to the platform date picker.
- Birthday is displayed in a locale-friendly format such as `18 Aug 2005`.
- Birthday is stored consistently as `yyyy-MM-dd` so Profile display and privacy logic remain stable.
- The birthday picker prevents selecting future dates and supports dates back to 1900.
- Existing `Only me` / `Public` birthday visibility is preserved.

### Changed

- Phase 105 redesigns Profile with an Instagram-inspired information hierarchy: avatar on the left, name/username on the right, left-aligned bio, and compact profile actions.
- Removed the large gradient hero, offline/last-seen label, Quick Actions dashboard, Activity chart, and oversized QR card from Profile.
- Moved Settings to the Profile AppBar and moved Saved Messages, Shared Media, and Privacy & Security into Settings.
- Profile and Settings accent icons now derive from `Theme.colorScheme.primary`, so icon containers follow the active theme color.
- Added a Shared Media directory in Settings that lets users choose a direct conversation before opening its shared photos/files/voice content.

### Added

- Added independent `Only me` / `Public` visibility controls for Phone, Email, and Birthday using the user document `profileVisibility` map.
- Added a compact Pet section at the bottom of Profile with a `showPetOnProfile` visibility switch.
- Added a compact QR Code bottom sheet instead of permanently occupying Profile screen space.


### Fixed

- Phase 104.8.4: repaired the malformed AppBar online-status Dart collection-if that caused the 254-line analyzer/editor error cascade.
- Preserved the existing `Show pet / Hide pet` item in the chat `⋮` menu.
- Preserved the removal of the floating top-right paw button.
- Preserved Mochi's 92 px visual size, 108 px drag hitbox, root Overlay architecture, position persistence, and visibility persistence.
- Preserved the safely braced `pet == null` guard.


### Changed

- Phase 104.8.3 removes the floating top-right paw button that appeared while Mochi was hidden.
- Added `Show pet / Hide pet` to the existing chat `⋮` more-options menu.
- Hidden Mochi now leaves no floating control over the AppBar or conversation UI.
- Preserved the 92 px Mochi visual size, 108 px drag hitbox, root Overlay architecture, saved position, and visibility persistence.
- Fixed the remaining `pet == null` curly-braces lint.


### Fixed

- Phase 104.8.2 repairs the malformed Dart collection-if introduced by the Phase 104.8.1 lint auto-fix.
- Restored the online-status `Positioned` widget to valid collection-if syntax inside the AppBar avatar `Stack`.
- Fixes the cascade of hundreds of editor/analyzer syntax errors caused by that single misplaced brace.
- Mochi size, 108 px drag hitbox, global Overlay architecture, animations, and saved position are unchanged.


### Fixed

- Phase 104.8.1 reduces Mochi's visible size from 118 px to 92 px for a lighter floating-pet presence.
- Reduced the invisible drag hit area from 176 px to 108 px so the Overlay no longer blocks a large invisible portion of the chat.
- Reduced the minimum on-screen grip from 28 px to 20 px while preserving edge/partially-offscreen placement.
- Cleared the remaining `curly_braces_in_flow_control_structures` lint in the direct chat page.
- Preserved the root `OverlayEntry` architecture and normalized per-contact position persistence.


### Fixed

- Phase 104.8 moves Mochi out of the chat page `Stack` and into a root `OverlayEntry`.
- Mochi drag gestures now live above the chat `ListView`, preventing Edge mouse dragging and mobile touch dragging from fighting conversation scrolling.
- Drag updates rebuild only the floating overlay instead of rebuilding the full chat room for every pointer movement.
- Preserved the Phase 104.7 native vector Mochi appearance, full tail, animation states, 176 px invisible hit target, hide/show state, and normalized saved position.
- The overlay is installed after the chat route mounts and is removed safely when leaving the conversation.


### Fixed

- Phase 104.7.2 replaces the corrupted Phase 104.7.1 `pet_actor.dart` with a clean full-file implementation.
- Fixed the malformed `State<PetActorclass ...` source corruption and the resulting analyzer cascade.
- Mochi keeps the Phase 104.7 native vector appearance and full tail.
- Dragging now uses a valid `GestureDetector` pan recognizer with `DragStartBehavior.down` and the existing large invisible hit area.
- No chat, Firebase, notification, or pet persistence logic is changed.


### Changed

- Phase 104.7 removes the unreliable AI-cropped Mochi sprite assets entirely.
- Mochi is now rendered as a native vector-style Flutter `CustomPainter`, so there is no rectangular background to cut out and the full fluffy tail is always preserved.
- Increased the invisible drag target to 176 px while the visible pet remains compact.
- Pointer-level dragging remains immediate and independent from the visible pet silhouette.
- Idle breathing, tail sway, blink, happy/touched reaction, drag, land and sleep states are rendered procedurally.
- Removed the obsolete `assets/pets/mochi/` registration and files.


### Fixed

- Phase 104.6.2 replaces the previous over-cropped Mochi frames with a new full-tail sprite set derived from the cleaner approved visual source.
- Increased the invisible drag hit area from the visible pet size to 164 px while keeping the on-screen Mochi around 112 px.
- Replaced GestureDetector pan handling with pointer-level `Listener` tracking so dragging starts immediately and no longer competes heavily with the chat ListView scroll gesture.
- A movement threshold separates tap interaction from dragging, so tapping still opens pet interaction while small finger movement does not accidentally trigger the menu.
- Full-screen/partially-offscreen placement and normalized saved position are preserved.


### Fixed

- Phase 104.6.1 rebuilt all 28 Mochi animation frames with a true transparent canvas so the visible square/card edge is removed.
- Mochi can now be dragged across the full chat overlay, including all four edges and partly offscreen like a floating control.
- Removed the previous 10 px edge margin and 106 px bottom reserve.
- Only 24 px of Mochi is forced to remain reachable so it cannot be permanently lost offscreen.
- Existing animation states, tap interaction, hide/show behavior, and normalized position persistence are preserved.


### Changed

- Phase 104.6 replaces the Phase 104.5 single-image floating pet with a multi-state Mochi 2D actor system.
- Added 28 transparent animation frames across idle, blink, happy, touched, drag, land, and sleep states.
- Added a dedicated `PetActor` state machine with timed frame playback and randomized idle behavior.
- Dragging switches Mochi into a drag state immediately, follows the finger/pointer directly, and plays a landing animation on release.
- Tapping Mochi plays a touched reaction and opens a compact interaction menu instead of placing controls over the pet body.
- Hide/show and normalized per-contact position persistence from Phase 104.5 are preserved.
- Removed the old `mochi_floating.png` single-image asset path.


### Changed

- Phase 104.5: replaced the placeholder circular fire icon with the actual Mochi 2D pet appearance from the approved visual direction.
- Floating Mochi now has no card or circular background and sits directly over the conversation.
- Reworked dragging to immediate pan tracking so the pet follows the pointer/finger without a long-press delay.
- Added a subtle idle floating animation that pauses while dragging.
- Preserved per-contact position, hide/show state, pet detail access, and care notification badge.


### Fixed

- Phase 104.4.1: restored `_PetInviteBanner`, `_MessageDetailRow`, and `_SelectionToolbar` that were accidentally removed while replacing the old fixed pet card.
- Fixed 7 analyzer errors in `real_chat_room_page.dart`.
- Floating pet behavior from Phase 104.4 is unchanged.


### Fixed

- Phase 104.4: removed the large shared-pet card from the top of direct chats so it no longer consumes conversation space.
- Shared pets now appear as a compact floating pet overlay that can be dragged around the chat screen.
- Added hide/show control for the floating pet without changing or deleting pet data.
- Floating pet position and visibility are persisted per contact in the existing user-owned `contactPreferences` document.
- Tapping the floating pet still opens pet details; long-press keeps quick-care access.
- The overlay reserves space above the message composer and clamps dragging to safe chat bounds.


### Fixed

- Phase 104.3: added the missing Cloud Function trigger for `groups/{groupId}/messages/{messageId}` so group messages can generate FCM notifications.
- Group notifications are fanned out to every current group member except the sender.
- Group text, photo, file and voice notifications now use appropriate notification previews.
- Group chat now marks `group_<groupId>` as the active conversation so the device currently viewing that group is not needlessly notified.
- Added structured logs for missing groups, invalid senders and partial group-notification failures.


### Fixed

- Phase 104.2: aligned the Recent Chats and Contacts top headers to the same vertical geometry to remove the visible tab-switch jump.
- Standardized the VonoTalky title row to the same top padding on both tabs.
- Standardized the search row bottom padding so the search field stays at the same Y position.
- Kept the existing page-specific actions and search behavior unchanged.


### Fixed

- Phase 104.1: vertically centered the microphone/keyboard toggle, text field, emoji button, attachment button and send button in both direct and group chat composers.
- Fixed the single-line composer state where action icons appeared lower than the message text.
- Kept multiline text growth independent from the icon row alignment.


### Fixed

- Reworked direct-message and group-message composers to use the same WeChat-style text/voice switching flow.
- Added a dedicated left-side voice/keyboard toggle instead of replacing the send button with a microphone when the text field is empty.
- Added hold-to-talk voice input with release-to-send and slide-up-to-cancel behavior.
- Kept the keyboard focused after sending a text message so consecutive messages can be typed without reopening the keyboard.
- Increased active send/voice control contrast so enabled controls no longer look disabled.
- Unified the direct-chat and group-chat composer interaction model.

### Added

- Added private per-contact nicknames in Contact Detail.
- Added private per-contact notes with a multiline editor.
- Added clear/save actions for contact nickname and note fields.
- Stored contact notes inside the existing user-owned `contactPreferences` documents.

### Changed

- Contact Detail now groups personal contact metadata above pin and mute controls.
- Private text preferences are removed from Firestore when cleared instead of storing empty strings.

### Security

- Contact nicknames and private notes remain readable and writable only by the signed-in owner through the existing `contactPreferences` Firestore rules.
- No Firestore Rules changes.
- No Firebase Functions deployment required.

### Added

- Added global System / Light / Dark appearance modes.
- Added Purple, Pink, Blue, Green and Orange VonoTalky theme colors.
- Added locally persisted theme preferences that survive app restarts.
- Added Profile → Settings → Appearance with instant theme preview.
- Added theme-aware Login, Register and Welcome styling.
- Added per-theme authentication background selection with safe color-treated fallback.
- Added theme-aware Chat, Contacts, Pet, Profile and bottom-navigation top-level surfaces.

### Changed

- Purple remains the default VonoTalky brand theme.
- Material 3 ColorScheme is now generated from the user's selected theme color for both light and dark modes.
- Authentication controls and background treatment now follow the selected theme.

### Technical

- Added `shared_preferences` for device-local appearance persistence.
- No Firestore Rules changes.
- No Firebase Functions deployment required.
---

## \[0.4.0\] - 2026-08-17

VonoTalky 0.4.0 expands the app beyond messaging with the shared Pet
Center, production push-notification workflows, deeper notification
routing, scalable chat-history pagination, improved reply navigation,
and Profile birthday UX. \### Added

#### Pet system

-   Added a shared pet system backed by Firebase for persistent pet data
    and friend interactions.
-   Added multiple pet types and expanded pet-related presentation and
    service logic.
-   Added shared pet detail flows and pet-care interactions.
-   Added pet invitations and pet care requests.
-   Added Cloud Functions for pet invitation and pet care request
    events.
-   Added Firebase Cloud Messaging notifications for supported pet
    events.
-   Added notification deep links so pet notifications can route users
    into the relevant pet experience.
-   Added pet assets and supporting Firebase setup documentation.

#### Notifications

-   Added a second-generation Cloud Function for direct-message push
    notifications.
-   Added notification routing from system notifications into the
    relevant direct conversation.
-   Added notification deep-link handling for pet invitations and care
    requests.
-   Added foreground notification suppression so VonoTalky does not show
    redundant in-app notification UI while the user is already viewing
    the relevant content.
-   Added supporting setup documentation for FCM, chat notifications and
    notification deep links.

#### Chat history and navigation

-   Added paginated direct-message history loading in batches instead of
    keeping the entire conversation in memory.
-   Added automatic loading of older messages when the user scrolls
    toward the beginning of a conversation.
-   Added a visible beginning-of-conversation state after the complete
    available history has been reached.
-   Added direct Firestore recovery for reply targets outside the
    currently loaded message window.
-   Added exact reply navigation that can continue loading older pages
    until the referenced message is found.
-   Added highlighting after navigating to the original replied-to
    message.
-   Added loading feedback while VonoTalky searches older history for an
    original message.

#### Profile

-   Added a birthday date picker to Profile User Info.
-   Added fast year-first birthday selection instead of requiring manual
    date entry.
-   Added support for existing birthday values and automatic Firestore
    persistence.
-   Added an `Add birthday` state when no birthday has been saved.

### Changed

#### Chat experience

-   Improved historical-message loading so older records are fetched on
    demand.
-   Improved upward pagination to preserve the user's visual scroll
    position when older messages are inserted.
-   Improved reply navigation for messages older than the currently
    loaded history window.
-   Improved mobile composer behavior while the Android keyboard is
    visible.
-   Constrained multiline composer growth and improved attachment/send
    button alignment.
-   Added drag-to-dismiss keyboard behavior to the direct-message list.
-   Improved foreground notification behavior to avoid duplicate or
    intrusive in-app notification surfaces.

#### Firebase and backend

-   Added Firebase Functions configuration to the project deployment
    configuration.
-   Updated Functions to use the Node.js 22 runtime.
-   Added and deployed second-generation event-driven Functions used by
    pet and direct-message notifications.

### Fixed

-   Fixed old reply targets displaying
    `Original message is outside the loaded history` without a useful
    recovery path.
-   Fixed direct-chat history appearing to end even when older Firestore
    messages were still available.
-   Fixed scroll-position jumps while loading older conversation pages.
-   Fixed invalid `ScrollPosition.offset` usage by using
    `ScrollPosition.pixels`.
-   Fixed mobile composer/SafeArea behavior when the software keyboard
    is open.
-   Fixed direct-message push notification deployment and routing
    issues.
-   Fixed pet invitation and pet care request Function deployment after
    Firebase IAM and service-agent configuration.
-   Fixed remaining analyzer warnings in the pet feature and restored
    `No issues found`.

### Security

-   Preserved authenticated access requirements for pet, chat and
    profile data.
-   Preserved existing Firestore and Storage restrictions while
    extending pet and notification functionality.
-   Kept Cloud Function service permissions scoped to the Firebase/GCP
    services required for event delivery and execution.

## \[0.3.0\] - 2026-08-16

### Added

#### Direct-message navigation and selection

-   Added jump-to-first-message navigation for direct conversations.
-   Added a dedicated multi-select mode with checkmark-based message
    selection.
-   Added a top-level Select All / Clear Selection control that only
    counts selectable messages.
-   Added labeled multi-select actions for Reply, Forward, Save, Delete
    and More.
-   Added contextual More actions for Copy text, Copy with time and Pin.
-   Added selection-aware More behavior so text-copy actions are hidden
    when the current selection contains no copyable text.
-   Added jump-to-date navigation with date picking, nearest-message
    lookup and message highlighting.
-   Added smart chat back handling that exits selection mode or closes
    the Emoji picker before leaving the conversation.
-   Added persistent multi-select mode that remains active even when
    zero messages are selected.
-   Added WeChat-style circular message selectors and tap-to-toggle
    selection behavior.
-   Hid the message composer, recording controls and Emoji picker while
    multi-select mode is active.
-   Disabled invalid bulk actions when no messages are selected.

#### Message deletion and recall

-   Unified multi-select deletion behind a single Delete action.
-   Added separate Delete for me and Recall for everyone choices.
-   Kept destructive actions behind a second confirmation step.
-   Removed Recall from the More menu to avoid duplicate destructive
    actions.
-   Added mixed-selection recall support so only messages sent by the
    current user are recalled when received messages are selected at the
    same time.
-   Unified the single-message delete flow with the same Delete for me /
    Recall for everyone model.
-   Hid Recall for everyone entirely when a single selected message was
    sent by the other participant.

### Changed

#### Multi-select workflow

-   Simplified the multi-select toolbar while keeping Select All
    exclusively in the top app bar.
-   Improved Select All state detection so recalled or deleted messages
    do not prevent Clear Selection from appearing correctly.
-   Improved bulk Save so one failed save no longer stops the remaining
    selected messages from being saved.
-   Improved bulk Forward so recalled or deleted messages are skipped
    instead of being forwarded.
-   Improved bulk Pin so recalled or deleted messages are skipped
    instead of being pinned.
-   Added partial-success feedback for bulk Save, Forward and Pin
    operations.

#### Profile and settings

-   Cleaned up the Profile page after duplicate settings controls were
    identified.
-   Adjusted the user-information card layout to prevent profile
    information from overlapping the biography area.

#### Project maintenance

-   Reorganized setup documentation under `docs/setup/`.
-   Moved migration documentation under `docs/migration/`.
-   Moved maintenance PowerShell scripts under `scripts/maintenance/`.
-   Consolidated Phase 25--52 development notes into the main project
    changelog.

### Fixed

-   Completed project-wide Dart analyzer cleanup and reached
    `No issues found`.
-   Replaced unnecessary multi-underscore callback parameters reported
    by the analyzer.
-   Added missing braces around flow-control statements reported by the
    analyzer.
-   Migrated the profile-visibility selector away from deprecated
    per-tile radio group handling.
-   Fixed Select All calculations when non-selectable messages are
    present.
-   Fixed multi-select actions attempting to operate on recalled or
    deleted messages.
-   Fixed profile layout regressions where the user-information section
    could cover biography content.
-   Fixed the Phase 45 mixed-recall implementation syntax issue caused
    by a missing semicolon.

## \[0.2.0\] - 2026-08-15

### Added

#### Conversation management

-   Added direct-chat and group-chat quick actions from Recent Chats.
-   Added pin/unpin, archive/unarchive and mark read/unread controls.
-   Added swipe actions for archive and read-state changes.
-   Added a dedicated Archived Chats manager for direct chats and
    groups.
-   Added draft previews for direct chats and persistent debounced
    drafts for groups.

#### Pinned messages

-   Added pinned messages for direct chats and group chats.
-   Added a pinned-message banner with jump-to-message navigation.
-   Added support for multiple pinned messages per conversation.
-   Added a dedicated pinned-message management page with individual
    unpin actions.
-   Preserved compatibility with legacy single-pin data.

#### Search

-   Added advanced private-chat message search with keyword
    highlighting.
-   Added filters for text, photos, files and voice messages.
-   Added file-name matching and jump-to-message navigation from search
    results.
-   Added group-message search by keyword, sender name and file name.
-   Improved home search so contacts and recent chats respond to the
    same search query.
-   Added clear-search and matching-state UI on the home page.

#### Group messaging

-   Added group message reactions with emoji counts and per-user
    toggling.
-   Added Message Info for sent group messages, including sent time and
    seen-by members.
-   Added editing for the sender's own group text messages.
-   Added an `edited` indicator for modified group messages.

### Changed

-   Recent Chats now preserves pinned conversations above normal
    conversations.
-   Draft activity can influence conversation ordering when a saved
    draft is newer than the last message.
-   Group and direct-chat preferences reuse each user's
    `contactPreferences` subcollection.
-   Private-chat search now opens the enhanced search experience.
-   Pinned-message management reads directly from the correct preference
    document.

### Fixed

-   Fixed Archived Chats patch compatibility after Recent Chats changes.
-   Fixed Recent Chats action-sheet overflow on shorter screens.
-   Fixed pinned-message synchronization on Flutter Web.
-   Fixed pinned-message manager reads when Firestore already contained
    pinned data.
-   Fixed stale Flutter widget-test scaffolding that still referenced
    the removed default `MyApp`.
-   Fixed duplicate default `FloatingActionButton` Hero tags.
-   Removed analyzer warnings caused by stale imports and unused helper
    declarations.

### Security

-   Updated group-message Firestore permissions to support member
    reactions.
-   Updated sender-only group-message permissions to support `editedAt`.
-   Preserved participant/member access restrictions for conversations
    and groups.

## \[0.1.0\] - 2026-08-14

### Added

#### Application foundation

-   Established a professional feature-first Flutter project structure.
-   Added centralized Material 3 theme, application colors, navigation
    and routing.
-   Added a persistent four-tab application shell for Chats, Contacts,
    Groups and Profile.
-   Preserved page state across bottom-navigation tab changes with an
    `IndexedStack`.

#### Authentication and onboarding

-   Added an authentication welcome screen with separate Sign Up and Log
    In actions.
-   Added Firebase email/password registration, login, logout and
    authentication gating.
-   Added first-run onboarding flow and persisted onboarding completion
    state.
-   Added the approved purple landscape background and near-transparent
    glassmorphism forms.
-   Added reusable authentication background and form-field components.

#### Home and conversations

-   Added the pink-to-purple gradient chat home design.
-   Added contact and conversation search entry points.
-   Added Top Contacts and a unified Recent Chats list for direct and
    group conversations.
-   Added unread counters, timestamps, message previews, online
    indicators and a New Chat menu.
-   Added real-time unread badge aggregation on the bottom navigation
    bar.

#### Direct messaging

-   Added real-time one-to-one conversations backed by Cloud Firestore.
-   Added responsive message bubbles with content-based width and sender
    alignment.
-   Added text, image, file and voice messages.
-   Added cancellable voice recording with a single adaptive Send/Record
    action button.
-   Added message replies, reactions, editing, deletion, forwarding and
    saved messages.
-   Added conversation search, shared-media browsing and a full-screen
    media viewer.
-   Added read state, delivery state and typing indicators.
-   Added a functional 64-item Emoji picker that inserts at the current
    cursor position.

#### Group messaging

-   Added group creation, group list, group details and real-time group
    conversations.
-   Added group text, image, file and voice messages.
-   Added replies and the shared adaptive Send/Record composer design.
-   Added the same functional Emoji picker used by direct conversations.
-   Integrated group conversations into the home Recent Chats feed.

#### Contacts and friend requests

-   Added a searchable contacts directory with alphabetical navigation.
-   Added user search by username, email and display name.
-   Added friend-request sending, receiving, accepting and rejecting.
-   Added contact profile details and direct chat actions.
-   Added blocked-user management.

#### Profile and settings

-   Added the approved purple header and pink-to-purple profile
    gradient.
-   Added profile avatar, online status, biography and user-information
    card.
-   Added editable display name, username, phone, birthday, bio and
    profile photo.
-   Added settings, privacy and security pages.
-   Added a visible logout action with presence cleanup.

#### Media, storage and platform support

-   Added camera/gallery image selection and Firebase Storage uploads.
-   Added cross-platform file selection and message attachments.
-   Added platform-specific media transfer implementations for mobile,
    desktop and web.
-   Added Firebase Storage rules for authenticated chat and profile
    media access.

#### Notifications

-   Added Firebase Cloud Messaging initialization and permission
    handling.
-   Added per-device notification token registration and token refresh
    handling.
-   Added foreground in-app notification banners.
-   Added notification routing into direct and group chat rooms.

#### Presence

-   Added application-wide online/offline presence management.
-   Added a 30-second presence heartbeat.
-   Added automatic stale-session detection after 90 seconds without a
    heartbeat.
-   Added periodic contact presence refresh so force-closed clients no
    longer remain online.

### Changed

-   Moved presence lifecycle ownership from the home page to the
    persistent application shell.
-   Consolidated direct and group conversations into a single home feed.
-   Converted the original Groups tab into a dedicated group-management
    area.
-   Removed the duplicated bottom navigation bar from conversation
    screens.
-   Unified Send and Record into one light-purple composer action.
-   Moved reply previews outside the text input and simplified their
    visual treatment.
-   Aligned direct-chat headers with the group-chat identity layout.
-   Updated message bubbles to size themselves according to their
    content.

### Fixed

-   Fixed invalid `const NavigationBar` construction.
-   Fixed Firebase deployment configuration for Firestore and Storage
    rules.
-   Fixed missing media and file-picker package integrations.
-   Fixed Android stale plugin-registration build failures after
    dependency changes.
-   Fixed blank Edge startup caused by platform initialization and
    configuration issues.
-   Fixed uploaded profile photos not refreshing in the interface.
-   Fixed direct and group chat composer layout inconsistencies.
-   Fixed online indicators remaining active after a browser, app or
    device was force-closed.
-   Replaced the Emoji placeholder snackbar with a working picker.

### Security

-   Added authenticated Firestore access rules for users, contacts,
    requests, conversations and groups.
-   Added authenticated Firebase Storage rules for profile, chat and
    group media.
-   Restricted presence and profile updates to the owning authenticated
    user.
