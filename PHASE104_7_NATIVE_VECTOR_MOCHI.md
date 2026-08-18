# Phase 104.7 — Native Vector Mochi

This replaces the failed cropped-image approach completely.

## Why

The previous generated sprite frames could not reliably separate pale white fur
and a pale-purple tail from the similarly colored poster background. That caused
visible squares, clipped tails, and even near-empty frames.

## New approach

Mochi is drawn directly by Flutter using `CustomPainter`:

- no image asset
- no square/card background
- full tail always exists
- transparent by definition
- smooth pointer-level drag
- large invisible hit target
- animated breathing, tail movement and state reactions

## Apply

```powershell
cd "C:\flutter project\vonotalky"

powershell -ExecutionPolicy Bypass -File .\scripts\apply_phase104_7_vector_mochi.ps1

flutter pub get

dart format lib/features/pet/animation lib/features/pet/presentation/widgets/floating_pet_actor.dart lib/features/chat/presentation/pages/real_chat_room_page.dart

flutter analyze
```

No Firebase deployment is required.
