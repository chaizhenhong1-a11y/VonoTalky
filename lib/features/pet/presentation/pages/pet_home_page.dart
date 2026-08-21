import 'package:flutter/material.dart';

import '../../data/models/shared_pet.dart';
import '../../data/services/shared_pet_service.dart';
import 'shared_pet_detail_page.dart';

class PetHomePage extends StatefulWidget {
  const PetHomePage({super.key});

  @override
  State<PetHomePage> createState() => _PetHomePageState();
}

class _PetHomePageState extends State<PetHomePage> {
  final service = SharedPetService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<SharedPet>>(
        stream: service.watchMyPets(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final pets = snapshot.data!;

          if (pets.isEmpty) {
            return const _EmptyPetCenter();
          }

          return _FixedPetHouseScene(onEnter: () => _enterHouse(pets));
        },
      ),
    );
  }

  Future<void> _enterHouse(List<SharedPet> pets) async {
    if (pets.isEmpty) return;

    if (pets.length == 1) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SharedPetDetailPage(petId: pets.first.id),
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<SharedPet>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) =>
          _PetPickerSheet(pets: pets, myId: service.myId),
    );

    if (selected == null || !mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SharedPetDetailPage(petId: selected.id),
      ),
    );
  }
}

class _PetPickerSheet extends StatelessWidget {
  const _PetPickerSheet({required this.pets, required this.myId});

  final List<SharedPet> pets;
  final String myId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            const Text(
              'Choose a pet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pick who you want to visit inside the Pet House.',
              style: TextStyle(color: Color(0xFF8D828F), fontSize: 11),
            ),
            const SizedBox(height: 14),
            ...pets.map(
              (pet) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: scheme.primary.withValues(alpha: .06),
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    onTap: () => Navigator.pop(context, pet),
                    leading: CircleAvatar(
                      backgroundColor: scheme.primary.withValues(alpha: .12),
                      child: Icon(Icons.pets_rounded, color: scheme.primary),
                    ),
                    title: Text(
                      pet.petName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      'with ${pet.friendName(myId)} · Lv.${pet.level}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FixedPetHouseScene extends StatelessWidget {
  const _FixedPetHouseScene({required this.onEnter});

  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;

        // Larger than the previous version while still scaling safely on phones.
        final houseHeight = (h * .54).clamp(300.0, 430.0);

        const spaceTopInset = 116.0;
        const backgroundTop = 50.0;
        final spaceHeight = h + spaceTopInset;
        final sharedCanvasHeight = spaceHeight + 50.0;

        // Must stay identical to TimeCapsuleScenePainter:
        // groundY = size.height * 0.72
        final groundY =
            backgroundTop + sharedCanvasHeight * .72 - spaceTopInset;

        // The house illustration now sits directly on the shared ground,
        // with no stepping-stone rows below it.
        final sceneBottom = (h - groundY).clamp(0.0, h);

        return Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: sceneBottom,
              child: Center(
                child: Semantics(
                  button: true,
                  label: 'Enter Pet House',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onEnter,
                    child: SizedBox(
                      height: houseHeight,
                      width: houseHeight * 1.22,
                      child: _PetHouseScene(primary: scheme.primary),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: (groundY - houseHeight + 12).clamp(10.0, h),
              child: const IgnorePointer(
                child: Center(
                  child: Text(
                    'Tap house to enter',
                    style: TextStyle(
                      color: Color(0xFF726D65),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PetHouseScene extends StatelessWidget {
  const _PetHouseScene({required this.primary});

  final Color primary;

  @override
  Widget build(BuildContext context) {
    const roof = Color(0xFF8A76A4);
    const door = Color(0xFF8A6248);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              bottom: 4,
              child: Container(
                width: maxWidth * .58,
                height: (maxHeight * .055).clamp(14.0, 24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF6F7A62).withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
            Positioned.fill(
              bottom: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: SizedBox(
                  width: maxWidth * .82,
                  height: maxHeight * .88,
                  child: const FittedBox(
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                    child: _PetHouseIllustration(
                      roofColor: roof,
                      doorColor: door,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PetHouseIllustration extends StatelessWidget {
  const _PetHouseIllustration({
    required this.roofColor,
    required this.doorColor,
  });

  final Color roofColor;
  final Color doorColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 232,
      height: 188,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Warm cream body.
          Positioned(
            bottom: 0,
            child: Container(
              width: 170,
              height: 116,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E7D6),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                  bottom: Radius.circular(22),
                ),
                border: Border.all(color: const Color(0xFFD8C9B7), width: 1.4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A514A43),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
            ),
          ),

          // Low-saturation roof.
          Positioned(
            top: 20,
            child: Transform.rotate(
              angle: .785398,
              child: Container(
                width: 122,
                height: 122,
                decoration: BoxDecoration(
                  color: roofColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: const Color(0xFF756488),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // Roof lip softens the geometric diamond look.
          Positioned(
            top: 66,
            child: Container(
              width: 184,
              height: 22,
              decoration: BoxDecoration(
                color: roofColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Paw emblem.
          Positioned(
            top: 54,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF7F0E6),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9CCBD), width: 1),
              ),
              child: Icon(Icons.pets_rounded, size: 22, color: roofColor),
            ),
          ),

          // Wooden door.
          Positioned(
            bottom: 0,
            child: Container(
              width: 56,
              height: 76,
              decoration: BoxDecoration(
                color: doorColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
              ),
              child: Align(
                alignment: const Alignment(.56, .08),
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE5C06A),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            left: 48,
            bottom: 42,
            child: _HouseWindow(frameColor: roofColor),
          ),
          Positioned(
            right: 48,
            bottom: 42,
            child: _HouseWindow(frameColor: roofColor),
          ),
        ],
      ),
    );
  }
}

class _HouseWindow extends StatelessWidget {
  const _HouseWindow({required this.frameColor});

  final Color frameColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 33,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7A8),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: Color.lerp(frameColor, const Color(0xFF6F5D7F), .28)!,
          width: 3,
        ),
        boxShadow: const [BoxShadow(color: Color(0x22E5B84E), blurRadius: 8)],
      ),
      child: const Center(
        child: Icon(Icons.add_rounded, color: Color(0xCFFFFFFF), size: 22),
      ),
    );
  }
}

class _EmptyPetCenter extends StatelessWidget {
  const _EmptyPetCenter();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .09),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.cottage_rounded, size: 45, color: scheme.primary),
          ),
          const SizedBox(height: 18),
          const Text(
            'Your pet house is waiting',
            style: TextStyle(
              color: Color(0xFF3D3340),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Start a shared pet from a friend chat. Once a pet moves in, this page becomes the entrance to your Pet House.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF938795),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Pet Center could not load.\n\n$message',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
