import 'package:flutter/material.dart';

import '../../../pet/data/models/shared_pet.dart';
import '../../../pet/data/services/shared_pet_service.dart';
import '../../data/services/profile_pet_showcase_service.dart';

class PetShowcaseEditorPage extends StatefulWidget {
  const PetShowcaseEditorPage({super.key});

  @override
  State<PetShowcaseEditorPage> createState() => _PetShowcaseEditorPageState();
}

class _PetShowcaseEditorPageState extends State<PetShowcaseEditorPage> {
  final SharedPetService petService = SharedPetService();
  final ProfilePetShowcaseService showcaseService = ProfilePetShowcaseService();

  final Set<String> selectedIds = <String>{};
  bool initialized = false;
  bool saving = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Pet showcase',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        TextButton(
          onPressed: saving ? null : _save,
          child: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
        ),
        const SizedBox(width: 6),
      ],
    ),
    body: StreamBuilder<List<Map<String, dynamic>>>(
      stream: showcaseService.watchUserShowcase(showcaseService.myId),
      builder: (context, showcaseSnapshot) {
        final current = showcaseSnapshot.data ?? const <Map<String, dynamic>>[];

        if (!initialized && showcaseSnapshot.hasData) {
          initialized = true;
          selectedIds.addAll(
            current.map((item) => item['petId'] as String?).whereType<String>(),
          );
        }

        return StreamBuilder<List<SharedPet>>(
          stream: petService.watchMyPets(),
          builder: (context, petsSnapshot) {
            if (!petsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final pets = petsSnapshot.data!;

            if (pets.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'You do not have any pets to showcase yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                Text(
                  'Choose up to 3 pets. These badges are visible to people who view your profile.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                ...pets.map((pet) {
                  final selected = selectedIds.contains(pet.id);
                  final disabled = !selected && selectedIds.length >= 3;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: selected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: .06)
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: disabled
                            ? null
                            : () => setState(() {
                                if (selected) {
                                  selectedIds.remove(pet.id);
                                } else {
                                  selectedIds.add(pet.id);
                                }
                              }),
                        child: Padding(
                          padding: const EdgeInsets.all(13),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: .10),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet.petName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Level ${pet.level}',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Checkbox(
                                value: selected,
                                onChanged: disabled
                                    ? null
                                    : (_) => setState(() {
                                        if (selected) {
                                          selectedIds.remove(pet.id);
                                        } else {
                                          selectedIds.add(pet.id);
                                        }
                                      }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    ),
  );

  Future<void> _save() async {
    setState(() => saving = true);

    try {
      final pets = await petService.watchMyPets().first;
      final selected = pets
          .where((pet) => selectedIds.contains(pet.id))
          .take(3)
          .toList(growable: false);

      await showcaseService.saveShowcase(selected);

      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
