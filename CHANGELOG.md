# Changelog

All notable changes to VonoTalky are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/).

## [0.1.0] - 2026-08-14

### Added

#### Application foundation

- Established a professional feature-first Flutter project structure.
- Added centralized Material 3 theme, application colors, navigation and routing.
- Added a persistent four-tab application shell for Chats, Contacts, Groups and Profile.
- Preserved page state across bottom-navigation tab changes with an `IndexedStack`.

#### Authentication and onboarding

- Added an authentication welcome screen with separate Sign Up and Log In actions.
- Added Firebase email/password registration, login, logout and authentication gating.
- Added first-run onboarding flow and persisted onboarding completion state.
- Added the approved purple landscape background and near-transparent glassmorphism forms.
- Added reusable authentication background and form-field components.

#### Home and conversations

- Added the pink-to-purple gradient chat home design.
- Added contact and conversation search entry points.
- Added Top Contacts and a unified Recent Chats list for direct and group conversations.
- Added unread counters, timestamps, message previews, online indicators and a New Chat menu.
- Added real-time unread badge aggregation on the bottom navigation bar.

#### Direct messaging

- Added real-time one-to-one conversations backed by Cloud Firestore.
- Added responsive message bubbles with content-based width and sender alignment.
- Added text, image, file and voice messages.
- Added cancellable voice recording with a single adaptive Send/Record action button.
- Added message replies, reactions, editing, deletion, forwarding and saved messages.
- Added conversation search, shared-media browsing and a full-screen media viewer.
- Added read state, delivery state and typing indicators.
- Added a functional 64-item Emoji picker that inserts at the current cursor position.

#### Group messaging

- Added group creation, group list, group details and real-time group conversations.
- Added group text, image, file and voice messages.
- Added replies and the shared adaptive Send/Record composer design.
- Added the same functional Emoji picker used by direct conversations.
- Integrated group conversations into the home Recent Chats feed.

#### Contacts and friend requests

- Added a searchable contacts directory with alphabetical navigation.
- Added user search by username, email and display name.
- Added friend-request sending, receiving, accepting and rejecting.
- Added contact profile details and direct chat actions.
- Added blocked-user management.

#### Profile and settings

- Added the approved purple header and pink-to-purple profile gradient.
- Added profile avatar, online status, biography and user-information card.
- Added editable display name, username, phone, birthday, bio and profile photo.
- Added settings, privacy and security pages.
- Added a visible logout action with presence cleanup.

#### Media, storage and platform support

- Added camera/gallery image selection and Firebase Storage uploads.
- Added cross-platform file selection and message attachments.
- Added platform-specific media transfer implementations for mobile, desktop and web.
- Added Firebase Storage rules for authenticated chat and profile media access.

#### Notifications

- Added Firebase Cloud Messaging initialization and permission handling.
- Added per-device notification token registration and token refresh handling.
- Added foreground in-app notification banners.
- Added notification routing into direct and group chat rooms.

#### Presence

- Added application-wide online/offline presence management.
- Added a 30-second presence heartbeat.
- Added automatic stale-session detection after 90 seconds without a heartbeat.
- Added periodic contact presence refresh so force-closed clients no longer remain online.

### Changed

- Moved presence lifecycle ownership from the home page to the persistent application shell.
- Consolidated direct and group conversations into a single home feed.
- Converted the original Groups tab into a dedicated group-management area.
- Removed the duplicated bottom navigation bar from conversation screens.
- Unified Send and Record into one light-purple composer action.
- Moved reply previews outside the text input and simplified their visual treatment.
- Aligned direct-chat headers with the group-chat identity layout.
- Updated message bubbles to size themselves according to their content.

### Fixed

- Fixed invalid `const NavigationBar` construction.
- Fixed Firebase deployment configuration for Firestore and Storage rules.
- Fixed missing media and file-picker package integrations.
- Fixed Android stale plugin-registration build failures after dependency changes.
- Fixed blank Edge startup caused by platform initialization and configuration issues.
- Fixed uploaded profile photos not refreshing in the interface.
- Fixed direct and group chat composer layout inconsistencies.
- Fixed online indicators remaining active after a browser, app or device was force-closed.
- Replaced the Emoji placeholder snackbar with a working picker.

### Security

- Added authenticated Firestore access rules for users, contacts, requests, conversations and groups.
- Added authenticated Firebase Storage rules for profile, chat and group media.
- Restricted presence and profile updates to the owning authenticated user.
