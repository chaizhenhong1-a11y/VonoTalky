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

