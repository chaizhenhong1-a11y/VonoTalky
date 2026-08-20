import 'package:flutter/material.dart';

import '../../animation/pet_actor.dart';
import '../../data/models/pet_care_request.dart';
import '../../data/models/shared_pet.dart';
import '../../data/services/shared_pet_service.dart';

class SharedPetDetailPage extends StatefulWidget {
  const SharedPetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  State<SharedPetDetailPage> createState() => _SharedPetDetailPageState();
}

class _SharedPetDetailPageState extends State<SharedPetDetailPage> {
  final SharedPetService service = SharedPetService();

  bool writing = false;

  Future<void> _perform(SharedPetAction action, {int? currentEnergy}) async {
    if (writing) return;

    if (action == SharedPetAction.play &&
        currentEnergy != null &&
        currentEnergy < SharedPetService.minimumPlayEnergy) {
      _showLowEnergyNotice();
      return;
    }

    setState(() => writing = true);
    try {
      await service.performAction(widget.petId, action);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  void _showLowEnergyNotice() {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Too tired to play. Feed your pet first to restore energy.',
          ),
        ),
      );
  }

  Future<void> _renamePet(SharedPet pet) async {
    final controller = TextEditingController(text: pet.petName);

    final name = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          18,
          0,
          18,
          18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rename pet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'Pet name',
                  prefixIcon: Icon(Icons.pets_rounded),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) return;
                    Navigator.pop(sheetContext, value);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.dispose();
    if (name == null || name == pet.petName || !mounted) return;

    setState(() => writing = true);
    try {
      await service.renamePet(widget.petId, name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Pet name updated'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Future<void> _showTogetherSheet(SharedPet pet) async {
    final friendId = pet.friendId(service.myId);
    final friendName = pet.friendName(service.myId);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = Theme.of(sheetContext).colorScheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Raise ${pet.petName} together',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask $friendName to help with one small action.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _RequestButton(
                        icon: Icons.restaurant_rounded,
                        label: 'Feed',
                        onTap: () =>
                            _sendCareRequest(friendId: friendId, type: 'feed'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _RequestButton(
                        icon: Icons.sports_esports_rounded,
                        label: 'Play',
                        onTap: () =>
                            _sendCareRequest(friendId: friendId, type: 'play'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: _RequestButton(
                        icon: Icons.favorite_rounded,
                        label: 'Pet',
                        onTap: () =>
                            _sendCareRequest(friendId: friendId, type: 'pet'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<PetCareRequest>>(
                  stream: service.watchPendingCareRequests(widget.petId),
                  builder: (context, snapshot) {
                    final requests = snapshot.data ?? const <PetCareRequest>[];
                    final incoming = requests
                        .where((item) => item.receiverId == service.myId)
                        .toList();

                    if (incoming.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Requests for you',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...incoming.map(
                          (request) => _IncomingCareTile(
                            request: request,
                            onComplete: () async {
                              Navigator.pop(sheetContext);
                              await _completeCareRequest(request);
                            },
                            onDismiss: () async {
                              Navigator.pop(sheetContext);
                              await _dismissCareRequest(request);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _sendCareRequest({
    required String friendId,
    required String type,
  }) async {
    Navigator.pop(context);

    try {
      await service.sendCareRequest(
        widget.petId,
        receiverId: friendId,
        type: type,
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Care request sent'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Future<void> _completeCareRequest(PetCareRequest request) async {
    try {
      await service.completeCareRequest(widget.petId, request);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Care request completed'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  Future<void> _dismissCareRequest(PetCareRequest request) async {
    try {
      await service.dismissCareRequest(widget.petId, request);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Care request dismissed'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return StreamBuilder<SharedPet?>(
      stream: service.watchPet(widget.petId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final pet = snapshot.data;
        if (pet == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final friendName = pet.friendName(service.myId);
        final bond = pet.bondPercent();
        final energy = pet.energy.clamp(0, 100);
        final mood = _moodFor(pet);
        final xpProgress = (pet.xp / 600).clamp(0.0, 1.0);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            titleSpacing: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.petName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'with $friendName',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Raise together',
                onPressed: () => _showTogetherSheet(pet),
                icon: StreamBuilder<int>(
                  stream: service.watchIncomingCareRequestCount(widget.petId),
                  initialData: 0,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;

                    return Badge(
                      isLabelVisible: count > 0,
                      label: Text(count > 9 ? '9+' : '$count'),
                      child: const Icon(Icons.group_rounded),
                    );
                  },
                ),
              ),
              IconButton(
                tooltip: 'Rename pet',
                onPressed: writing ? null : () => _renamePet(pet),
                icon: const Icon(Icons.tune_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              _PetHeroCard(
                pet: pet,
                mood: mood,
                onTapPet: writing ? null : () => _perform(SharedPetAction.pet),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.favorite_rounded,
                      label: 'Bond',
                      value: '$bond%',
                      color: const Color(0xFFFF7199),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.restaurant_rounded,
                      label: 'Energy',
                      value: '$energy%',
                      color: const Color(0xFFFFA45C),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.sentiment_satisfied_alt_rounded,
                      label: 'Mood',
                      value: mood,
                      color: colors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _ActionRow(
                disabled: writing,
                playDisabled: energy < SharedPetService.minimumPlayEnergy,
                onFeed: () => _perform(SharedPetAction.feed),
                onPet: () => _perform(SharedPetAction.pet),
                onPlay: () =>
                    _perform(SharedPetAction.play, currentEnergy: energy),
              ),
              if (energy < SharedPetService.minimumPlayEnergy) ...[
                const SizedBox(height: 8),
                _LowEnergyHint(petName: pet.petName),
              ],
              const SizedBox(height: 14),
              _LevelCard(level: pet.level, xp: pet.xp, progress: xpProgress),
              const SizedBox(height: 12),
              _StreakCard(
                streakDays: pet.streakDays,
                friendName: friendName,
                atRisk: pet.streakAtRisk,
              ),
            ],
          ),
        );
      },
    );
  }

  String _moodFor(SharedPet pet) {
    if (pet.energy < 25) return 'Sleepy';
    if (pet.affection < 120) return 'Needs love';
    if (pet.energy > 75 && pet.affection > 300) return 'Happy';
    if (pet.energy > 50) return 'Good';
    return 'Calm';
  }
}

class _PetHeroCard extends StatelessWidget {
  const _PetHeroCard({
    required this.pet,
    required this.mood,
    required this.onTapPet,
  });

  final SharedPet pet;
  final String mood;
  final VoidCallback? onTapPet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: 330,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.primary.withValues(alpha: .08), colors.surface],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.primary.withValues(alpha: .10)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            left: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: .92),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                mood,
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Center(
            child: PetActor(
              visualSize: 205,
              hitSize: 228,
              onDragUpdate: (_) {},
              onDragEnd: () {},
              onTap: onTapPet ?? () {},
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 17,
            child: Text(
              'Tap ${pet.petName} to give some love',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: .45)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.disabled,
    required this.playDisabled,
    required this.onFeed,
    required this.onPet,
    required this.onPlay,
  });

  final bool disabled;
  final bool playDisabled;
  final VoidCallback onFeed;
  final VoidCallback onPet;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.restaurant_rounded,
            label: 'Feed',
            onPressed: disabled ? null : onFeed,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.favorite_rounded,
            label: 'Pet',
            onPressed: disabled ? null : onPet,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            icon: Icons.sports_esports_rounded,
            label: playDisabled ? 'Too tired' : 'Play',
            onPressed: disabled || playDisabled ? null : onPlay,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _LowEnergyHint extends StatelessWidget {
  const _LowEnergyHint({required this.petName});

  final String petName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.bedtime_outlined, size: 17, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$petName is too tired to play. Feed first to restore energy.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({
    required this.level,
    required this.xp,
    required this.progress,
  });

  final int level;
  final int xp;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .09),
              shape: BoxShape.circle,
            ),
            child: Text(
              'Lv.$level',
              style: TextStyle(
                color: colors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    backgroundColor: colors.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      'Growth',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$xp / 600 XP',
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.streakDays,
    required this.friendName,
    required this.atRisk,
  });

  final int streakDays;
  final String friendName;
  final bool atRisk;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: atRisk ? const Color(0xFFFFF4EA) : colors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: const Color(0xFFFFEEE8),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFF7D62),
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streakDays day streak',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  atRisk
                      ? 'Chat with $friendName today to keep it going.'
                      : 'You and $friendName are raising this pet together.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 9.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}

class _IncomingCareTile extends StatelessWidget {
  const _IncomingCareTile({
    required this.request,
    required this.onComplete,
    required this.onDismiss,
  });

  final PetCareRequest request;
  final VoidCallback onComplete;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = switch (request.type) {
      'feed' => 'Feed the pet',
      'play' => 'Play together',
      _ => 'Give some love',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: onDismiss,
            icon: const Icon(Icons.close_rounded, size: 18),
          ),
          FilledButton(onPressed: onComplete, child: const Text('Done')),
        ],
      ),
    );
  }
}
