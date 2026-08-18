# Phase 104.6 — Mochi 2D Pet Actor

This increment upgrades directly from the already-applied Phase 104.5.

## Architecture

- `pet_animation_state.dart` — actor states
- `pet_actor.dart` — state machine and frame playback
- `floating_pet_actor.dart` — chat overlay wrapper
- `assets/pets/mochi/` — 28 transparent frames

States:

- idle
- blink
- happy
- touched
- drag
- land
- sleep

## Apply

Overlay the outer `vonotalky` folder, then:

```powershell
cd "C:\flutter project\vonotalky"

powershell -ExecutionPolicy Bypass -File .\scripts\apply_phase104_6_mochi_actor.ps1

flutter pub get

dart format lib/features/pet/animation lib/features/pet/presentation/widgets/floating_pet_actor.dart lib/features/chat/presentation/pages/real_chat_room_page.dart

flutter analyze
```

No Firebase Functions deployment is required.
