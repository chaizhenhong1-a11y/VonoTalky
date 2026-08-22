# CHANGELOG

## Phase 105.3.15
### Fixed
- Removed the duplicate Pet Center landscape painter completely.
- Pet House now renders transparently on top of Space's existing `SharedSpaceBackground`.
- Aligned the house contact point to the real shared-world ground formula used by `TimeCapsuleScenePainter` (`groundY = size.height * 0.72`), accounting for Space's background and TabBarView offsets.
- Removed the Pet page's redundant `SafeArea` so its coordinate system matches the shared Space scene.
- Preserved pet loading, multi-pet picker, navigation, house illustration, empty state, and error state.
## Phase 105.3.16

### Changed

- Enlarged the fixed Pet House entrance while preserving responsive phone scaling.
- Removed the three decorative stepping-stone rows below the house.
- Anchored the house body directly to the shared Space ground line.
- Moved the `Tap house to enter` hint higher so it no longer overlaps the roof.
- Shared Space background, tree scene, pet data flow, and detail navigation remain unchanged.

## Phase 105.3.17
### Fixed
- Removed the large `InkWell` hover/press overlay around the Pet House, eliminating the sticker-like translucent rounded rectangle on Edge/Web.
- Replaced the visual ink tap surface with a transparent `GestureDetector` while preserving the full house tap target and semantics.
- Increased the Pet House entrance size again.
- The actual house illustration now scales with the responsive scene using `LayoutBuilder` + `FittedBox`; enlarging the scene now enlarges the house itself instead of only enlarging an empty outer box.
- Moved the `Tap house to enter` hint higher to maintain clear spacing above the larger roof.
- Shared Space landscape, tree painter, ground geometry, pet data flow, and detail navigation remain unchanged.

## Phase 105.3.18

### Changed

- Lowered the `Tap house to enter` hint slightly so it stays comfortably above the roof without sitting too high in the scene.
- House scale, shared Space background alignment, and tap behavior remain unchanged.

## Phase 105.3.19

### Changed

- Moved the `Tap house to enter` hint substantially lower so it sits close above the Pet House roof instead of floating high in the sky.
- House size, shared Space background, ground alignment, and tap behavior remain unchanged.

## Phase 106.0.1

### Added

- Added the first production-structured voice-call foundation under `lib/features/calls`.
- Added a dedicated call controller and immutable call state instead of placing call lifecycle logic inside chat UI files.
- Added a WebRTC audio service with microphone capture, echo cancellation, noise suppression, automatic gain control, mute control, speaker routing, and STUN-ready peer connection setup.
- Added the initial VonoTalky audio call screen with contact identity, call state, timer, mute, speaker, and hang-up controls.
- Added Android microphone/audio/network permissions and iOS microphone/camera usage descriptions.
- Added `flutter_webrtc` 1.6.0 as the real-time media dependency.

### Notes

- This increment establishes the media and call-screen foundation only.
- Firestore signaling, incoming-call routing, background notifications, and chat-header call entry are intentionally deferred to the next call increment so signaling is introduced as a separate, testable layer.

## Phase 106.0.2

### Added

- Added the direct-chat voice-call action without changing or importing from any `part` child file.
- Added Firestore-backed one-to-one audio call sessions.
- Added caller WebRTC SDP offer publishing and caller/callee ICE candidate signaling.
- Added remote answer handling so the caller can transition from ringing to connected.
- Added participant-scoped Firestore rules for call sessions and signaling candidate collections.

### Changed

- Upgraded the WebRTC audio service from local microphone preparation to signaling-capable peer connection management.
- Upgraded the call controller to own outgoing call creation, Firestore state observation, remote answer application, ICE candidate handling, call timing, and hang-up synchronization.
- Updated the audio call page to start a real outgoing Firestore/WebRTC call.

### Fixed

- Rebuilt this increment against VonoTalky's current `part`-based chat-room architecture.
- No imports are added to `part of` widget files, preventing the cascading analyzer failures from the discarded Phase 106.0.2 package.

### Notes

- This increment completes the caller-side signaling path.
- Incoming call discovery, accept/reject, callee answer creation, and notification routing are the next increment.

## Phase 106.0.3

### Added

- Added foreground incoming-call discovery for authenticated callees.
- Added an incoming voice-call screen with caller identity, Accept, Decline, mute, speaker, timer, and hang-up controls.
- Added callee WebRTC answer generation and Firestore answer publishing.
- Added callee ICE candidate publishing and caller ICE candidate consumption.
- Added an `IncomingCallController` so incoming-call lifecycle logic stays outside UI widgets.
- Added a lightweight `IncomingCallListener` around the embedded Chat home, allowing foreground calls to surface while MainShell keeps the home page mounted.

### Changed

- Extended `CallSignalingService` with incoming-call observation, offer reading, accept/reject operations, and both candidate directions.
- Extended `WebRtcAudioService` with remote-offer application and WebRTC answer creation.
- Tightened call-document read rules around caller/callee identity so callee-scoped queries are rule-compatible.

### Notes

- With both devices running the app in the foreground, A can call B, B can accept/reject, and both peers now complete SDP + ICE signaling.
- Background/terminated-app ringing and native lock-screen integration are intentionally deferred to the notification/CallKit/Telecom phase.

## Phase 106.0.4

### Added

- Added a dedicated second-generation `onCallCreated` Cloud Function module for high-priority incoming-call FCM notifications.
- Added background and terminated-app notification-tap routing into the real incoming voice-call page.
- Added direct call-session validation before notification routing so stale, rejected, or ended calls do not reopen.
- Added a 45-second outgoing ring timeout so unanswered call sessions do not stay active indefinitely.
- Added defensive FCM token lookup for the existing per-user `devices` collection.
- Added invalid FCM token cleanup after Firebase Messaging delivery failures.

### Changed

- `IncomingCallListener` now handles both foreground Firestore call discovery and Firebase Messaging notification opens.
- `CallSignalingService` can resolve a specific ringing call by `callId`.
- The outgoing call controller now cancels its ring timeout when the call connects, is rejected, ends, or the controller is disposed.

### Deployment

- This increment deliberately does not overwrite `functions/index.js`, preserving all existing chat, group, pet invite, and pet care Functions.
- Add this one export to the existing `functions/index.js`:
  `exports.onCallCreated = require("./call_notifications").onCallCreated;`
- Deploy only the new Function:
  `firebase deploy --only functions:onCallCreated`

### Notes

- Android and iOS can receive a normal high-priority system call notification while VonoTalky is backgrounded, and tapping it routes back into the incoming-call experience.
- Native lock-screen Accept/Decline and WhatsApp-style full-screen ringing still require Android Telecom/full-screen calling integration and iOS CallKit/VoIP push support.

## Phase 106.0.5

### Added

- Added Android native incoming-call UI using `flutter_callkit_incoming`.
- Added Android locked-screen/full-screen incoming-call presentation for real VonoTalky VoIP calls.
- Added native Accept, Decline, timeout, and end event routing back into the existing Firestore/WebRTC call lifecycle.
- Added automatic WebRTC answer flow when a call is accepted from the native Android call screen.
- Added Android 13+ notification permission handling and Android 14+ full-screen intent permission handling.
- Added full-screen incoming-call, vibration, wake-lock, and phone-call foreground-service permissions.
- Added a top-level Firebase Messaging background handler dedicated to incoming-call pushes.

### Changed

- Incoming-call FCM delivery is now Android data-only/high-priority so the background handler can create the native call surface without a duplicate generic notification.
- Foreground Android calls use the same native incoming-call surface as background and locked-screen calls.
- Android `MainActivity` launch mode is changed to `singleInstance` as required by the call UI plugin.
- Native call UI is closed when the call is declined or leaves the active call lifecycle.

### Platform scope

- Phase 106.0.5 is Android-first.
- iOS still uses the Phase 106.0.4 notification route; true iOS CallKit + PushKit is reserved for the next Apple-specific phase.

### Android 14+

- Full-screen call intent access is a user-controlled special permission on Android 14+.
- VonoTalky requests it only once when the calling feature initializes.
- If the user does not grant it, Android can fall back to an emphasized heads-up incoming-call notification.

## Phase 106.0.5.1

### Fixed

- Updated Android native call integration for the actual `flutter_callkit_incoming 3.1.5` API.
- Moved Android Accept/Decline labels from `CallKitParams` to `AndroidParams`.
- Replaced removed legacy `CallEvent.body`, `CallEvent.event`, and `Event.*` access with the 3.1.5 sealed event classes.
- Native accept, decline, timeout, and ended events now use `CallEventActionCallAccept`, `CallEventActionCallDecline`, `CallEventActionCallTimeout`, and `CallEventActionCallEnded`.
- Call IDs are resolved from each event's `CallKitParams.extra` first and fall back to the CallKit id.

## Phase 106.0.5.2

### Fixed

- Removed `CallEventActionCallTimeout.callKitParams` access because the 3.1.5 timeout event does not expose that property.
- Accept, Decline, Ended, and Incoming events continue resolving their call id through `CallKitParams`.
- Timeout events remain harmless and no longer block compilation.

## Phase 106.0.5.3

### Fixed

- Removed the unnecessary null comparison on `CallKitParams.id` for `flutter_callkit_incoming 3.1.5`.
- Clears the final analyzer warning in the Android native incoming-call integration.

## Phase 106.0.5.4

### Fixed

- Prevented `CallController` from notifying listeners after disposal.
- Added disposed guards to call-session and remote-answer listeners.
- Hardened Firestore call rules for caller/callee reads, updates, and both ICE candidate directions.
- Fixed a chat floating-pet teardown race where deactivated widget context could still be used to read Bloc state.
- Cached chat Bloc references in `didChangeDependencies()` and avoided ancestor lookup during overlay teardown.
- Added an overlay builder mounted guard during route disposal.

### Notes

- This hotfix targets the runtime failures observed during Edge/Android call testing:
  Firestore permission denied, `CallController was used after being disposed`, and deactivated widget ancestor lookup.

## Phase 106.0.5.5

### Fixed

- Restored the direct-chat voice-call import, call launch method, and AppBar phone action that were accidentally overwritten by the Phase 106.0.5.4 runtime hotfix.
- Preserved the latest part-based chat-room architecture.
- Preserved the floating-pet teardown safety fix by caching only `ChatPetCubit`.
- Removed the unused cached presence/preferences Cubit fields introduced by the previous hotfix.

## Phase 106.0.5.7

### Fixed

- Restored `CallSignalingService.readIncomingInvite()` that was accidentally lost in Phase 106.0.5.6 due to an older signaling-service baseline being used.
- Kept the Phase 106.0.5.6 `memberIds` + `arrayContains` incoming-call query fix.
- Restores compatibility with `IncomingCallListener` notification and native CallKit routing.

## Phase 106.0.5.8

### Fixed

- Split Firestore call reads into explicit `get` and `list` permissions.
- Direct call-document reads/listeners remain restricted to call participants through `memberIds`.
- Incoming-call collection queries are explicitly restricted to documents where `calleeId` equals the authenticated user.
- Changed incoming-call discovery back to `where('calleeId', isEqualTo: uid)` so the query exactly matches the Firestore `allow list` rule.
- Preserved `readIncomingInvite()` and all Android CallKit routing added in earlier call phases.

## Phase 106.0.5.9

### Fixed

- Disabled incoming-call Firestore and Firebase Messaging listeners on Web and desktop.
- Incoming-call receiving now runs only on Android and iOS.
- Edge/Windows can act purely as the caller without starting a callee-only Firestore listener during app startup.
- Added explicit incoming-call stream error logging on mobile to identify any future permission failures without crashing the app.

### Testing

- Recommended path: Edge/Windows caller -> Android callee.
- If Edge still reports `cloud_firestore/permission-denied` after this increment, the failing query is not the calls listener and should be traced elsewhere instead of changing call rules again.

## Phase 107.0.1

### Added

- Added the new official VonoTalky 1024×1024 app icon asset at `assets/icon/app_icon.png`.
- Added `flutter_launcher_icons` tooling for consistent Android and iOS launcher icon generation.

### Changed

- Configured Android and iOS to generate launcher icons from the new VonoTalky logo asset.
- Enabled iOS alpha removal for App Store-compatible launcher icon output.

### Generate icons

- Run `flutter pub get`.
- Run `dart run flutter_launcher_icons`.

## Phase 107.0.2

### Added

- Added `TimeCapsuleRepository` for persistent Firestore-backed time capsules.
- Added real-time time-capsule loading from `users/{userId}/timeCapsules`.
- Added Firestore security rules for private owner-only time-capsule reads and creates.

### Changed

- Replaced the temporary in-memory `_capsules` list with a Firestore stream.
- Creating a time capsule now persists its title, content, creation time, and unlock date.
- Time capsules now survive page changes, app restarts, and sign-in on another device with the same account.
- Preserved the existing tree-tag layer and friend-tree entry.
- Preserved the manually added `users/{userId}/treeTags` Firestore rules and corrected their nesting with the existing user subcollections.

### Fixed

- Fixed time-capsule history disappearing after leaving or restarting the app.
- Added visible save-failure feedback instead of silently showing a capsule that was never persisted.

### Firestore

- New path: `users/{userId}/timeCapsules/{capsuleId}`.
- Deploy the updated Firestore rules after applying this increment.

## Phase 107.0.3

### Added

- Added time-capsule management actions after selecting a saved capsule.
- Added explicit Open/View and Delete actions.
- Added a destructive confirmation dialog before permanent deletion.
- Added Firestore-backed capsule deletion through `TimeCapsuleRepository`.

### Changed

- Saved capsule selection now opens a compact management sheet before opening the capsule.
- Locked capsules remain protected by the existing unlock-date behavior.
- Capsule deletion updates every signed-in device automatically through the existing Firestore stream.

### Firestore

- The authenticated owner can now delete documents under `users/{userId}/timeCapsules`.
- Time-capsule updates remain disabled so an already-buried capsule cannot silently change.

## Phase 107.0.4

### Changed

- Restored normal time-capsule tap behavior: unlocked capsules open directly and locked capsules show their lock state.
- Moved destructive capsule deletion out of the normal tap flow.
- Long-pressing a saved capsule now invokes deletion with a confirmation dialog.
- Buried capsules remain immutable: title, content, and unlock date cannot be edited.

### UX

- Delete is now a secondary recovery/management action rather than a prominent capsule action.
- The interaction better preserves the intended “bury now, open in the future” time-capsule experience.

## Phase 107.0.4.1

### Fixed

- Repaired malformed UTF-8 Chinese strings in the time-capsule collection sheet.
- Fixed the unterminated string literals that blocked `dart format` and `flutter analyze`.
- Preserved Phase 107.0.4 behavior: tap to open/view, long-press to delete with confirmation.

## Phase 107.0.5

### Changed

- Redesigned the Profile top area into a theme-aware Hero section using the active `ColorScheme`.
- Added a responsive three-stop gradient built from the current primary, secondary, and surface colors.
- Dark mode and light mode now receive different gradient opacity for consistent contrast.
- Increased avatar prominence and aligned its fallback colors with the shared theme surface/on-surface palette.
- Moved Edit Profile and QR Code actions into the Hero section.
- Refined Personal Information into a softer themed container with icon-backed rows.
- Kept all existing profile Firebase data, privacy controls, QR behavior, pet showcase, and navigation logic unchanged.

### Theme

- No fixed purple/pink gradient values were added.
- Profile accents now automatically follow whichever VonoTalky theme is active.

## Phase 107.0.6

### Changed

- Simplified the Profile Hero background from a three-stop gradient to a two-color theme gradient.
- The Hero now transitions directly from the active theme `primary` color to `secondary`.
- Preserved separate light/dark opacity tuning while removing the surface-color third stop.

## Phase 107.0.7

### Changed

- Matched the Profile Hero gradient exactly to the current ChatHomePage gradient.
- Gradient direction is now `Alignment.topLeft` to `Alignment.topRight`.
- Gradient colors now use `primary(.18) -> secondary(.13) -> primary(.10)`.
- Restored the same `[0, 0.5, 1]` stops used by ChatHomePage.
- ChatHomePage itself is unchanged.

## Phase 107.0.7.1

### Fixed

- Removed the two stale `isDark` references left in the Profile Hero border and shadow after the gradient was changed to exactly match ChatHomePage.
- Fixed Edge/Flutter compilation errors in `profile_page.dart`.
- Profile Hero gradient remains unchanged and still matches ChatHomePage exactly.

## Phase 107.0.8

### Changed

- Added theme-aware Dark Mode styling to the direct chat room without changing chat, call, attachment, or floating-pet behavior.
- Chat AppBar now blends the active theme primary color into the current surface instead of using a fixed light lavender.
- Chat fallback backgrounds now have dedicated dark variants for blue, lavender, pink, and cream selections.
- Message bubbles now use `primaryContainer` / `surfaceContainerHighest` with matching foreground colors.
- Composer surface, border, action icons, send button, avatar surfaces, status text, and jump-to-latest control now follow the active `ColorScheme`.
- Voice recording controls now use theme surface, primary, outline, and error container colors.
- Pinned-message banner now follows `primaryContainer` and `onPrimaryContainer` in both light and dark themes.

## Phase 107.0.8.1

### Fixed

- Removed stale `const` qualifiers from chat widgets and text styles that now depend on runtime theme colors.
- Fixed five `Invalid constant value` analyzer errors introduced by the Dark Mode conversion.
- Dark Mode styling and chat behavior remain unchanged.

## Phase 107.0.8.2

### Fixed

- Removed the final stale `const` declaration around the remaining runtime theme color in the direct chat room.
- Fixes the last `Invalid constant value` analyzer error reported near line 1063.

## Phase 107.0.8.3

### Fixed

- Fixed repeated `Provider<ChatPetCubit>` runtime exceptions from the floating-pet overlay.
- The overlay `LayoutBuilder` no longer reads `ChatPetCubit` from its overlay context, which sits outside the page's `MultiBlocProvider`.
- Floating-pet drag updates now reuse the `_chatPetCubit` instance already captured by the chat page state.
- No changes to pet positioning, drag behavior, chat logic, or Dark Mode styling.

## Phase 107.0.8.4

### Fixed

- Fixed unreadable dark message text on dark chat bubbles.
- Message body foreground now pairs with the active bubble container: `onPrimaryContainer` for the current user's messages and `onSurface` for incoming messages.
- Secondary message metadata uses theme-aware container/surface foreground colors instead of fixed dark text values.
- Light Mode remains theme-aware; no global white text override was introduced.

## Phase 107.0.8.5

### Fixed

- Restored floating-pet visibility after the overlay/provider fix.
- The floating-pet `OverlayEntry` now listens directly to `_chatPetCubit.stream` with the current state as `initialData`.
- Pet loading, visibility changes, and anchor updates now rebuild the overlay independently of the overlay widget tree's provider context.
- Removed the duplicate visibility check in the floating-pet overlay.
- Preserved existing pet drag, hide/show, quick-care, chat, and Dark Mode behavior.

## Phase 107.0.8.6

### Changed

- Improved floating-pet drag responsiveness, especially on Flutter Web / Edge.
- Drag movement now updates a local overlay anchor instead of emitting `ChatPetCubit` state on every pointer update.
- The floating-pet overlay rebuilds directly during drag using `markNeedsBuild()`.
- The final anchor is written back to `ChatPetCubit` only when dragging ends, then the existing persistence logic saves the position.
- Preserved existing drag bounds, hide/show behavior, pet menu, Dark Mode, and chat features.

## Phase 107.0.8.7

### Changed

- Decoupled direct-chat message foreground colors from the active theme palette.
- Message body text now uses pure black in Light Mode and pure white in Dark Mode.
- Secondary message metadata uses black54 in Light Mode and white70 in Dark Mode.
- Theme colors continue to control chat surfaces, bubbles, AppBar, controls, and accents; changing theme color no longer recolors message text.

## Phase 107.0.8.8

### Changed

- Decoupled Home/Recent Chats text foregrounds from the active theme palette.
- Top Contacts and Recent Chats section titles now use black in Light Mode and white in Dark Mode.
- Top Contact names use black/white by brightness; offline status uses black54/white70 while online status remains semantic green.
- Recent Chat names use black/white by brightness.
- Recent Chat previews, draft text, and timestamps use black54/white70 by brightness.
- Empty-state text follows the same strict neutral Light/Dark foreground rules.
- Theme colors continue to control icons, badges, surfaces, and accents, but no longer recolor Recent Chat text.
- Preserved the already-established theme-adaptive user/group avatar fallback styling.

## Phase 107.0.8.9

### Changed

- Applied the same fixed Light/Dark text policy to the Contacts page.
- Contact names now render black in Light Mode and white in Dark Mode.
- Contact status text and empty-state secondary text use black54 in Light Mode and white70 in Dark Mode.
- Contact text no longer changes color when the app theme accent changes.
- Preserved semantic status-dot colors for online/offline presence.
- Updated contact avatar fallback to the shared theme-adaptive surface/on-surface style.
- Contact action icons and selected alphabet index continue to use the active theme accent.
- Contact list dividers and request-badge borders now adapt correctly to Dark Mode.

## Phase 107.0.8.10.2

### Fixed

- Restored the previously completed Profile Hero implementation after it was accidentally overwritten by an older Profile source.
- Restored the Profile Hero theme-driven gradient and existing Hero layout from the Phase 107.0.7.1 working version.
- Applied the requested fixed text policy on top of the restored Hero: main text is black in Light Mode and white in Dark Mode; secondary text is black54 / white70.
- Kept theme colors for the Hero gradient, icons, buttons, and intentional accent states.
- No Profile data, Firestore, pet showcase, QR, navigation, or visibility behavior was changed.

## Phase 107.0.8.11

### Changed

- Added full Light/Dark theme support to the group chat room.
- Group AppBar, chat background, message bubbles, composer, reaction chips, and voice controls now adapt to the active theme.
- Group message body text now uses black in Light Mode and white in Dark Mode.
- Group message metadata uses black54/black45 in Light Mode and white70/white60 in Dark Mode.
- Theme accent colors remain for intentional emphasis such as sender names, read states, actions, and send controls.
- Pinned-message behavior continues to reuse the shared theme-aware `PinnedMessageBanner`.
- No group messaging, Firestore, reactions, pinning, recall, voice, attachment, draft, or navigation logic was changed.

## Phase 107.0.8.11.1

### Fixed

- Fixed group-chat analyzer errors caused by `colors` and `isDark` being referenced outside the `build()` method scope.
- `_voiceHoldButton()` now resolves its own `ColorScheme` and brightness from `Theme.of(context)`.
- No visual behavior or group-chat functionality was changed.

## Phase 107.0.8.13.1

### Fixed

- Fixed the group-chat composer wrapping into a visually two-line layout on narrow phones.
- Group chat now uses the same compact-width composer behavior as direct chat.
- Mic, text field, Emoji, Add, and Send controls remain on one horizontal row on compact screens.
- Reduced horizontal pressure under 390 logical pixels using tighter padding, compact button density, and smaller minimum control sizes.
- Multi-line input still grows upward instead of pushing action buttons onto another row.
- No group messaging, voice, emoji, attachment, draft, reaction, or Dark Mode behavior was changed.

## Phase 107.0.8.13.2

### Fixed

- Removed the remaining stale `const` wrapper around a narrow-screen `MediaQuery.sizeOf(context)` expression in the group composer.
- Fixes the `Methods can't be invoked in constant expressions` analyzer error near line 542.
- No group-chat layout or behavior was otherwise changed.

## Phase 107.0.8.14

### Restored

- Restored the compact/collapsible chat background switcher in direct chat.
- The expanded background switcher now includes a dedicated collapse control.
- Collapsed mode uses a 42x42 circular wallpaper button so it does not cover chat content.
- Tapping the compact wallpaper button expands the full Mine/other-background switcher again.
- Existing background toggle behavior, unavailable-background hint, theme adaptation, and background state logic remain unchanged.

## Phase 107.0.8.14.1

### Fixed

- Fixed repeated `BoxDecoration.debugAssertIsValid()` assertions when collapsing or expanding the direct-chat background switcher.
- Expanded and collapsed switcher states now use distinct keyed subtrees so Flutter does not interpolate between a rounded rectangle and a circular decoration.
- Removed the unnecessary decoration animation from the collapsed circular button.
- Preserved the existing collapse/expand size animation, background switching behavior, Dark Mode, and unavailable-background hint.

## Phase 107.0.9.0

### Added

- Added real VonoTalky profile QR scanning from the Contacts page.
- Added a camera scanner flow backed by `mobile_scanner` for VonoTalky QR payloads in the existing `vonotalky://user/{uid}` format.
- Added strict QR parsing so unrelated QR codes are rejected instead of being treated as user IDs.
- Added scanned-user lookup through the existing Firestore `users` collection.
- Added a scanned-profile preview with avatar, name, email, current relationship state, and Add Friend action.
- Reused the existing `ContactService.sendRequest()` friend-request workflow instead of creating a second friendship system.
- Added handling for own QR code, missing users, invalid QR codes, pending requests, existing contacts, previously declined requests, repeated detections, and scanner resume behavior.
- Added a QR scanner entry button to the Contacts header.
- Added Android camera permission and updated the iOS camera usage description for QR scanning.
- Added `mobile_scanner` dependency.

## Phase 107.0.9.1

### Changed

- Redesigned the scanned-profile page into a compact contact-profile layout.
- Moved the profile avatar to the left with display name and username aligned beside it.
- Moved Bio into its own left-aligned section below the identity row.
- Bio now renders in full with no `maxLines` or ellipsis truncation.
- Removed email/contact-info content and the extra relationship status card from the scanned-profile UI.
- Existing contacts now see a direct `Message` action that opens the existing direct chat room.
- New users see `Add Friend`; pending requests show `Request Pending`.
- QR lookup now also reads the existing `username` and `bio` profile fields directly from the scanned user's Firestore profile document.
- Preserved Light/Dark text behavior and the existing friend-request flow.

## Phase 107.0.9.2

### Changed

- Polished the scanned-profile UI with theme-driven visual depth while preserving the compact profile structure.
- Added a subtle theme-based identity surface using `primary`, `secondary`, and surface colors instead of hard-coded purple.
- Added a theme-aware framed avatar with a light shadow.
- Converted the username into a compact `primaryContainer` pill.
- Moved Bio into a dedicated theme-aware surface card with a small quote accent.
- Bio remains fully visible, left-aligned, and untruncated.
- Refined the primary action spacing and added a QR icon to `Scan another code`.
- All Light/Dark behavior follows the active `ColorScheme`; no fixed accent color was introduced.

## Phase 107.0.9.3

### Changed

- Matched the scanned-profile identity gradient exactly to the current Chat Home gradient.
- Uses the same top-left to top-right direction, `primary` / `secondary` / `primary` color sequence, alpha values `.18 / .13 / .10`, and stops `0 / 0.5 / 1`.
- The gradient therefore follows the active app theme in exactly the same way as Chat Home.
- Preserved the left-side avatar, username pill, full Bio card, and Message/Add Friend behavior.

