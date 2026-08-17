import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/shared_pet.dart';
import '../../data/models/shared_pet_memory.dart';
import '../../data/models/pet_care_request.dart';
import '../../data/services/shared_pet_service.dart';

enum FlameMood { idle, happy, eating, playing, sleepy, celebrating }

class SharedPetDetailPage extends StatefulWidget {
  const SharedPetDetailPage({super.key, required this.petId});

  final String petId;

  @override
  State<SharedPetDetailPage> createState() => _SharedPetDetailPageState();
}

class _SharedPetDetailPageState extends State<SharedPetDetailPage>
    with TickerProviderStateMixin {
  final service = SharedPetService();

  late final AnimationController _idle;
  late final AnimationController _pulse;
  late final AnimationController _blink;
  Timer? _actionTimer;
  FlameMood mood = FlameMood.idle;
  bool writing = false;

  int? _lastSeenLevel;
  PetEvolutionStage? _lastSeenStage;
  _PetCelebrationData? _celebration;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _actionTimer?.cancel();
    _idle.dispose();
    _pulse.dispose();
    _blink.dispose();
    super.dispose();
  }

  void _react(FlameMood next, int milliseconds) {
    _actionTimer?.cancel();
    setState(() => mood = next);
    _pulse.forward(from: 0);
    _actionTimer = Timer(Duration(milliseconds: milliseconds), () {
      if (mounted) setState(() => mood = FlameMood.idle);
    });
  }

  Future<void> _perform(SharedPetAction action, FlameMood reaction) async {
    if (writing) return;
    setState(() => writing = true);
    _react(reaction, action == SharedPetAction.dailyReward ? 1800 : 1200);

    try {
      await service.performAction(widget.petId, action);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Future<void> _showCustomization(SharedPet pet) async {
    final nameController = TextEditingController(text: pet.petName);
    var selectedTheme = pet.petTheme;
    var selectedSpecies = pet.petSpecies;

    final result = await showModalBottomSheet<_PetCustomizationResult>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.fromLTRB(
              18,
              4,
              18,
              18 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customize shared pet',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Changes are shared with both pet owners.',
                    style: TextStyle(color: Color(0xFF928594), fontSize: 10),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    maxLength: 24,
                    decoration: const InputDecoration(
                      labelText: 'Pet name',
                      prefixIcon: Icon(Icons.pets_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pet species',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _speciesChoice(
                        'flame',
                        '🔥',
                        'Flame',
                        selectedSpecies,
                        (value) => setSheetState(() => selectedSpecies = value),
                      ),
                      _speciesChoice(
                        'mochi',
                        '🐱',
                        'Mochi',
                        selectedSpecies,
                        (value) => setSheetState(() => selectedSpecies = value),
                      ),
                      _speciesChoice(
                        'cloud',
                        '☁️',
                        'Cloud',
                        selectedSpecies,
                        (value) => setSheetState(() => selectedSpecies = value),
                      ),
                      _speciesChoice(
                        'star',
                        '⭐',
                        'Star',
                        selectedSpecies,
                        (value) => setSheetState(() => selectedSpecies = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Theme',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _themeChoice(
                        'rose',
                        'Rose',
                        const Color(0xFFFF7196),
                        selectedTheme,
                        (value) => setSheetState(() => selectedTheme = value),
                      ),
                      _themeChoice(
                        'violet',
                        'Violet',
                        const Color(0xFF9C70DB),
                        selectedTheme,
                        (value) => setSheetState(() => selectedTheme = value),
                      ),
                      _themeChoice(
                        'sunset',
                        'Sunset',
                        const Color(0xFFFF8A65),
                        selectedTheme,
                        (value) => setSheetState(() => selectedTheme = value),
                      ),
                      _themeChoice(
                        'ocean',
                        'Ocean',
                        const Color(0xFF5B9DE8),
                        selectedTheme,
                        (value) => setSheetState(() => selectedTheme = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(
                          sheetContext,
                          _PetCustomizationResult(
                            name: name,
                            theme: selectedTheme,
                            species: selectedSpecies,
                          ),
                        );
                      },
                      child: const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    nameController.dispose();
    if (result == null || !mounted) return;

    setState(() => writing = true);
    try {
      if (result.name != pet.petName) {
        await service.renamePet(widget.petId, result.name);
      }
      if (result.theme != pet.petTheme) {
        await service.setPetTheme(widget.petId, result.theme);
      }
      if (result.species != pet.petSpecies) {
        await service.setPetSpecies(widget.petId, result.species);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Pet customization saved'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Widget _speciesChoice(
    String value,
    String emoji,
    String label,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    final active = value == selected;
    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFEEF5) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFFFF7196) : const Color(0xFFE5DEE7),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFFD95780)
                    : const Color(0xFF675B69),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChoice(
    String value,
    String label,
    Color color,
    String selected,
    ValueChanged<String> onSelected,
  ) {
    final active = value == selected;

    return GestureDetector(
      onTap: () => onSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color.withAlpha(30) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? color : const Color(0xFFE5DEE7),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? color : const Color(0xFF5A4D5E),
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkForProgressCelebration(SharedPet pet) {
    final previousLevel = _lastSeenLevel;
    final previousStage = _lastSeenStage;

    _lastSeenLevel ??= pet.level;
    _lastSeenStage ??= pet.evolutionStage;

    if (previousLevel == null || previousStage == null) {
      return;
    }

    final evolved = previousStage != pet.evolutionStage;
    final leveledUp = pet.level > previousLevel;

    if (!evolved && !leveledUp) {
      return;
    }

    _lastSeenLevel = pet.level;
    _lastSeenStage = pet.evolutionStage;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _celebration = _PetCelebrationData(
          fromLevel: previousLevel,
          toLevel: pet.level,
          stage: pet.evolutionStage,
          evolved: evolved,
        );
      });

      _react(FlameMood.celebrating, 2200);

      Future<void>.delayed(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        setState(() => _celebration = null);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SharedPet?>(
      stream: service.watchPet(widget.petId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(snapshot.error.toString())),
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
        final claimedToday = SharedPetService.claimedToday(pet);

        _checkForProgressCelebration(pet);

        return Scaffold(
          backgroundColor: const Color(0xFFFFF7FB),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                tooltip: 'Customize pet',
                onPressed: () => _showCustomization(pet),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.petName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  'with $friendName',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF91869B),
                  ),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                children: [
                  _streakCard(pet),
                  if (pet.streakAtRisk) ...[
                    const SizedBox(height: 10),
                    _streakGuardCard(pet, friendName),
                  ],
                  const SizedBox(height: 12),
                  _evolutionCard(pet),
                  const SizedBox(height: 15),
                  _petStage(pet),
                  const SizedBox(height: 10),
                  _speciesPersonalityCard(pet),
                  const SizedBox(height: 12),
                  _needsCard(pet),
                  const SizedBox(height: 15),
                  _actionRow(),
                  const SizedBox(height: 16),
                  _progressCard(pet),
                  const SizedBox(height: 14),
                  _teamworkCard(pet, friendName),
                  const SizedBox(height: 14),
                  _streakMilestones(pet),
                  const SizedBox(height: 14),
                  _careTogetherCard(pet, friendName),
                  const SizedBox(height: 14),
                  _memoriesCard(),
                  const SizedBox(height: 14),
                  _dailyReward(pet, claimedToday),
                ],
              ),
              if (_celebration != null)
                Positioned.fill(
                  child: _LevelEvolutionCelebration(
                    data: _celebration!,
                    onDismiss: () {
                      if (mounted) {
                        setState(() => _celebration = null);
                      }
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _streakGuardCard(SharedPet pet, String friendName) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF0E5), Color(0xFFFFF6EC)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFD6B2)),
      ),
      child: Row(
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFF7A55),
              size: 23,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Keep your streak alive',
                  style: TextStyle(
                    color: Color(0xFF5D493E),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Chat with $friendName today so your '
                  '${pet.streakDays}-day streak can continue.',
                  style: const TextStyle(
                    color: Color(0xFF937A6C),
                    fontSize: 9.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.schedule_rounded,
            color: Color(0xFFC88C68),
            size: 19,
          ),
        ],
      ),
    );
  }

  Widget _evolutionCard(SharedPet pet) {
    final next = pet.nextEvolutionLevel;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 47,
            height: 47,
            decoration: const BoxDecoration(
              color: Color(0xFFF6EDFB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF9B6CC5),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pet.evolutionStage.label,
                  style: const TextStyle(
                    color: Color(0xFF443848),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pet.evolutionProgress,
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF0E8F3),
                    color: const Color(0xFFB88CDF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  next == null
                      ? 'Final evolution reached'
                      : 'Next evolution at Lv.$next',
                  style: const TextStyle(
                    color: Color(0xFF928594),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(SharedPet pet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE4EC), Color(0xFFFFF0D9)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.local_fire_department_rounded,
              color: Color(0xFFFF6C70),
              size: 30,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${pet.streakDays} day streak',
                  style: const TextStyle(
                    color: Color(0xFF3A2E3F),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Your shared progress is synced with Firebase.',
                  style: TextStyle(color: Color(0xFF8E7886), fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _petStage(SharedPet pet) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFEEF5), Color(0xFFFFFAFC)],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(top: 20, child: _speech(pet)),
          AnimatedBuilder(
            animation: Listenable.merge([_idle, _pulse, _blink]),
            builder: (_, _) {
              final cycle = _idle.value * math.pi * 2;
              final species = PetSpecies.fromKey(pet.petSpecies);

              final baseBreath = switch (species) {
                PetSpecies.flame => math.sin(cycle) * 4.5,
                PetSpecies.mochi => math.sin(cycle) * 3.0,
                PetSpecies.cloud => math.sin(cycle * .72) * 7.0,
                PetSpecies.star => math.sin(cycle * 1.25) * 4.0,
              };

              final speciesSway = switch (species) {
                PetSpecies.flame => math.sin(cycle * .72) * .035,
                PetSpecies.mochi => math.sin(cycle * .55) * .018,
                PetSpecies.cloud => math.sin(cycle * .5) * .026,
                PetSpecies.star => math.sin(cycle * .82) * .055,
              };

              final jump = mood == FlameMood.playing
                  ? switch (species) {
                      PetSpecies.mochi => -math.sin(_idle.value * math.pi) * 30,
                      PetSpecies.cloud => -math.sin(_idle.value * math.pi) * 17,
                      PetSpecies.star => -math.sin(_idle.value * math.pi) * 27,
                      PetSpecies.flame => -math.sin(_idle.value * math.pi) * 24,
                    }
                  : mood == FlameMood.celebrating
                  ? -math.sin(_idle.value * math.pi) * 16
                  : 0.0;

              final reactionScale =
                  1 +
                  (_pulse.value < .5 ? _pulse.value : 1 - _pulse.value) * .11;

              final speciesScaleX = switch (species) {
                PetSpecies.cloud => 1 + math.sin(cycle) * .025,
                PetSpecies.mochi => 1 + math.sin(cycle * .85) * .012,
                PetSpecies.star => 1 + math.sin(cycle * 1.3) * .018,
                PetSpecies.flame => 1.0,
              };

              final moodScaleY = mood == FlameMood.eating
                  ? .96 + math.sin(cycle * 2) * .025
                  : mood == FlameMood.sleepy
                  ? .94
                  : 1.0;

              return Transform.translate(
                offset: Offset(0, baseBreath + jump + 16),
                child: Transform.rotate(
                  angle: mood == FlameMood.sleepy ? -.035 : speciesSway,
                  child: Transform.scale(
                    scaleX: reactionScale * speciesScaleX,
                    scaleY: reactionScale * moodScaleY,
                    child: GestureDetector(
                      onTap: () =>
                          _perform(SharedPetAction.pet, FlameMood.happy),
                      child: SizedBox(
                        width: 185,
                        height: 205,
                        child: CustomPaint(
                          painter: _FlamePetPainter(
                            mood: mood,
                            t: _idle.value,
                            blinkT: _blink.value,
                            stage: pet.evolutionStage,
                            theme: pet.petTheme,
                            species: PetSpecies.fromKey(pet.petSpecies),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 16,
            bottom: 14,
            child: _statPill(Icons.favorite_rounded, '${pet.affection} / 500'),
          ),
          Positioned(
            right: 16,
            bottom: 14,
            child: _statPill(Icons.bolt_rounded, '${pet.energy} / 100'),
          ),
          Positioned(top: 72, right: 16, child: _wellbeingChip(pet)),
          Positioned(left: 16, right: 16, bottom: 54, child: _levelBar(pet)),
        ],
      ),
    );
  }

  Widget _speech(SharedPet pet) {
    final status = _petWellbeing(pet);

    final text = switch (mood) {
      FlameMood.happy => 'Hehe! ♡',
      FlameMood.eating => 'Yummy!',
      FlameMood.playing => 'Again! Again!',
      FlameMood.sleepy => 'So sleepy...',
      FlameMood.celebrating => 'We did it!',
      FlameMood.idle => _speciesIdleSpeech(
        PetSpecies.fromKey(pet.petSpecies),
        status,
      ),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey('$mood-$status-$text'),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(19),
          boxShadow: const [
            BoxShadow(
              color: Color(0x10000000),
              blurRadius: 9,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF59495D),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _speciesIdleSpeech(PetSpecies species, _PetWellbeing status) {
    return switch (species) {
      PetSpecies.flame => switch (status) {
        _PetWellbeing.thriving => 'My flame is shining bright! 🔥',
        _PetWellbeing.happy => 'Keep my little flame glowing!',
        _PetWellbeing.lonely => 'A chat would warm me up...',
        _PetWellbeing.needsAttention => 'My flame feels tiny...',
        _PetWellbeing.sleepy => 'The flame is getting quiet...',
      },
      PetSpecies.mochi => switch (status) {
        _PetWellbeing.thriving => 'Purrfect day! ♡',
        _PetWellbeing.happy => 'Mrrp! Stay with me.',
        _PetWellbeing.lonely => 'Mew... where did you go?',
        _PetWellbeing.needsAttention => 'I need cuddles...',
        _PetWellbeing.sleepy => 'Nap time... zzz',
      },
      PetSpecies.cloud => switch (status) {
        _PetWellbeing.thriving => 'I feel light as the sky! ☁️',
        _PetWellbeing.happy => 'Floating happily together.',
        _PetWellbeing.lonely => 'The sky feels a little empty...',
        _PetWellbeing.needsAttention => 'I feel a little grey...',
        _PetWellbeing.sleepy => 'Drifting into a soft nap...',
      },
      PetSpecies.star => switch (status) {
        _PetWellbeing.thriving => 'I am sparkling so bright! ✨',
        _PetWellbeing.happy => 'Twinkle with me!',
        _PetWellbeing.lonely => 'I need someone to shine with...',
        _PetWellbeing.needsAttention => 'My light is fading...',
        _PetWellbeing.sleepy => 'Dim mode... good night.',
      },
    };
  }

  _PetWellbeing _petWellbeing(SharedPet pet) {
    if (pet.energy <= 22) return _PetWellbeing.sleepy;
    if (pet.affection <= 110) return _PetWellbeing.needsAttention;
    if (pet.todayChatProgress <= 1) return _PetWellbeing.lonely;

    if (pet.energy >= 75 &&
        pet.affection >= 360 &&
        pet.todayChatProgress >= 6 &&
        pet.streakDays >= 3) {
      return _PetWellbeing.thriving;
    }

    return _PetWellbeing.happy;
  }

  Widget _wellbeingChip(SharedPet pet) {
    final status = _petWellbeing(pet);

    final (icon, label, color) = switch (status) {
      _PetWellbeing.thriving => (
        Icons.auto_awesome_rounded,
        'Thriving',
        const Color(0xFF8B6ED7),
      ),
      _PetWellbeing.happy => (
        Icons.sentiment_very_satisfied_rounded,
        'Happy',
        const Color(0xFFFF7196),
      ),
      _PetWellbeing.lonely => (
        Icons.chat_bubble_outline_rounded,
        'Wants chat',
        const Color(0xFF7C8FD5),
      ),
      _PetWellbeing.needsAttention => (
        Icons.favorite_outline_rounded,
        'Needs love',
        const Color(0xFFE06B8B),
      ),
      _PetWellbeing.sleepy => (
        Icons.bedtime_rounded,
        'Sleepy',
        const Color(0xFF8F83A9),
      ),
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFFFF7DA4)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF59495D),
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelBar(SharedPet pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Text(
            'Lv.${pet.level}',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: pet.xp / 600,
                minHeight: 7,
                backgroundColor: const Color(0xFFFFE4EE),
                color: const Color(0xFFFF7DA4),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${pet.xp}/600', style: const TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  Widget _speciesPersonalityCard(SharedPet pet) {
    final species = PetSpecies.fromKey(pet.petSpecies);

    final (title, subtitle, icon) = switch (species) {
      PetSpecies.flame => (
        'Warm & energetic',
        'Flame pets glow brighter when happy and flicker when excited.',
        Icons.local_fire_department_rounded,
      ),
      PetSpecies.mochi => (
        'Playful & cuddly',
        'Mochi reacts with its ears, tail, paws, and extra affection.',
        Icons.pets_rounded,
      ),
      PetSpecies.cloud => (
        'Soft & dreamy',
        'Cloudy floats, puffs, drifts, and gets misty when sleepy.',
        Icons.cloud_rounded,
      ),
      PetSpecies.star => (
        'Bright & curious',
        'Twinkle rotates, sparkles, and throws starbursts while playing.',
        Icons.star_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5FC),
        borderRadius: BorderRadius.circular(21),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF9B6CC5), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${species.label} · $title',
                  style: const TextStyle(
                    color: Color(0xFF514552),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF958A98),
                    fontSize: 9,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _needsCard(SharedPet pet) {
    final status = _petWellbeing(pet);

    final message = switch (status) {
      _PetWellbeing.thriving =>
        'Everything is going great. Keep the streak alive together.',
      _PetWellbeing.happy =>
        'Your pet feels good. A little chat or care will keep it smiling.',
      _PetWellbeing.lonely =>
        'No chat progress yet today. Chat with your friend to help your shared pet feel connected.',
      _PetWellbeing.needsAttention =>
        'Affection is getting low. Pet, play, or care for it together.',
      _PetWellbeing.sleepy =>
        'Energy is low. Give your pet some time to recover before more play.',
    };

    final progress = switch (status) {
      _PetWellbeing.thriving => 1.0,
      _PetWellbeing.happy => .78,
      _PetWellbeing.lonely => .48,
      _PetWellbeing.needsAttention => .32,
      _PetWellbeing.sleepy => .22,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Color(0xFFFFEFF5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.monitor_heart_outlined,
              color: Color(0xFFFF7196),
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How your pet feels',
                  style: TextStyle(
                    color: Color(0xFF4D4250),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF928694),
                    fontSize: 9,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF3EBF1),
                    color: const Color(0xFFFF7DA4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow() {
    return Row(
      children: [
        Expanded(
          child: _actionButton(
            Icons.restaurant_rounded,
            'Feed',
            () => _perform(SharedPetAction.feed, FlameMood.eating),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            Icons.sports_esports_rounded,
            'Play',
            () => _perform(SharedPetAction.play, FlameMood.playing),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _actionButton(
            Icons.favorite_rounded,
            'Pet',
            () => _perform(SharedPetAction.pet, FlameMood.happy),
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, VoidCallback onTap) {
    return FilledButton.tonalIcon(
      onPressed: writing ? null : onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 13),
        foregroundColor: const Color(0xFF7D5578),
        backgroundColor: const Color(0xFFFFEAF2),
      ),
    );
  }

  Widget _progressCard(SharedPet pet) {
    final interactedToday =
        pet.lastInteractionAt != null &&
        _sameDay(pet.lastInteractionAt!, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's progress",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            pet.hasChattedToday
                ? 'Today is active · keep going together'
                : 'New day · chat progress starts fresh',
            style: const TextStyle(
              color: Color(0xFF9A8E9C),
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          _progressRow(
            Icons.chat_bubble_rounded,
            'Chat progress',
            '${pet.todayChatProgress} / 10',
            pet.todayChatProgress / 10,
          ),
          const SizedBox(height: 14),
          _progressRow(
            Icons.favorite_rounded,
            'Daily interaction',
            interactedToday ? 'Done' : '0 / 1',
            interactedToday ? 1 : 0,
          ),
        ],
      ),
    );
  }

  Widget _progressRow(
    IconData icon,
    String label,
    String value,
    double progress,
  ) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFFF7DA4)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(label)),
                  Text(value),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 7,
                backgroundColor: const Color(0xFFFFEDF3),
                color: const Color(0xFFFF7DA4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _teamworkCard(SharedPet pet, String friendName) {
    final myId = service.myId;
    final friendId = pet.friendId(myId);
    final mine = pet.contributionFor(myId);
    final theirs = pet.contributionFor(friendId);
    final total = mine + theirs;

    final myPercent = total <= 0 ? 50 : (mine * 100 / total).round();
    final friendPercent = 100 - myPercent;

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.groups_2_rounded, color: Color(0xFF9B6CC5), size: 20),
              SizedBox(width: 8),
              Text(
                'Growing together',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Chatting and caring for your pet both count toward contribution.',
            style: TextStyle(
              color: Color(0xFF938795),
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  Expanded(
                    flex: myPercent <= 0 ? 1 : myPercent,
                    child: Container(color: const Color(0xFFFF7DA4)),
                  ),
                  Expanded(
                    flex: friendPercent <= 0 ? 1 : friendPercent,
                    child: Container(color: const Color(0xFFBCA2E2)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _contributionPerson(
                  title: 'You',
                  value: mine,
                  percent: myPercent,
                  color: const Color(0xFFFF7DA4),
                  alignRight: false,
                ),
              ),
              Expanded(
                child: _contributionPerson(
                  title: friendName,
                  value: theirs,
                  percent: friendPercent,
                  color: const Color(0xFF9B79CA),
                  alignRight: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contributionPerson({
    required String title,
    required int value,
    required int percent,
    required Color color,
    required bool alignRight,
  }) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF4E4352),
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$percent% · $value pts',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _streakMilestones(SharedPet pet) {
    const milestones = [3, 7, 14, 30];

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: Color(0xFFFF7A6B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Streak rewards',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Keep your friendship streak alive to unlock bonus growth.',
            style: TextStyle(
              color: Color(0xFF938795),
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          ...milestones.map(
            (days) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _milestoneRow(pet, days),
            ),
          ),
        ],
      ),
    );
  }

  Widget _milestoneRow(SharedPet pet, int days) {
    final claimed = pet.claimedStreakMilestones.contains(days);
    final unlocked = pet.streakDays >= days;

    final rewardText = switch (days) {
      3 => '+30 XP · +15 Bond',
      7 => '+70 XP · +30 Bond',
      14 => '+140 XP · +50 Bond',
      30 => '+300 XP · +100 Bond',
      _ => '',
    };

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: unlocked ? const Color(0xFFFFE9DD) : const Color(0xFFF1EDF2),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$days',
            style: TextStyle(
              color: unlocked
                  ? const Color(0xFFFF744F)
                  : const Color(0xFF9C929F),
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$days day streak',
                style: const TextStyle(
                  color: Color(0xFF4E4352),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                rewardText,
                style: const TextStyle(
                  color: Color(0xFF958999),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        FilledButton.tonal(
          onPressed: writing || claimed || !unlocked
              ? null
              : () => _claimStreakMilestone(days),
          child: Text(
            claimed
                ? 'Claimed'
                : unlocked
                ? 'Claim'
                : 'Locked',
          ),
        ),
      ],
    );
  }

  Future<void> _claimStreakMilestone(int days) async {
    if (writing) return;
    setState(() => writing = true);
    _react(FlameMood.celebrating, 1600);

    try {
      await service.claimStreakMilestone(widget.petId, days);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Widget _careTogetherCard(SharedPet pet, String friendName) {
    final friendId = pet.friendId(service.myId);

    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.volunteer_activism_rounded,
                color: Color(0xFFFF7DA4),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Care together',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                'with $friendName',
                style: const TextStyle(
                  color: Color(0xFF978A99),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Ask your friend to help care for your shared pet.',
            style: TextStyle(
              color: Color(0xFF938795),
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: _careRequestButton(
                  icon: Icons.restaurant_rounded,
                  label: 'Feed',
                  onTap: () => _sendCareRequest(friendId, 'feed', friendName),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _careRequestButton(
                  icon: Icons.sports_esports_rounded,
                  label: 'Play',
                  onTap: () => _sendCareRequest(friendId, 'play', friendName),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _careRequestButton(
                  icon: Icons.favorite_rounded,
                  label: 'Pet',
                  onTap: () => _sendCareRequest(friendId, 'pet', friendName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          StreamBuilder<List<PetCareRequest>>(
            stream: service.watchPendingCareRequests(widget.petId),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? const <PetCareRequest>[];

              final incoming = requests
                  .where((item) => item.receiverId == service.myId)
                  .toList();
              final outgoing = requests
                  .where((item) => item.senderId == service.myId)
                  .toList();

              if (incoming.isEmpty && outgoing.isEmpty) {
                return const SizedBox.shrink();
              }

              return Column(
                children: [
                  ...incoming.map(
                    (request) => _incomingCareRequest(request, pet.petName),
                  ),
                  ...outgoing.map(
                    (request) => _outgoingCareRequest(request, friendName),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _careRequestButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FilledButton.tonalIcon(
      onPressed: writing ? null : onTap,
      icon: Icon(icon, size: 17),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 11),
        foregroundColor: const Color(0xFF7D5578),
        backgroundColor: const Color(0xFFFFEDF4),
      ),
    );
  }

  Widget _incomingCareRequest(PetCareRequest request, String petName) {
    final label = switch (request.type) {
      'feed' => 'Feed $petName',
      'play' => 'Play with $petName',
      _ => 'Pet $petName',
    };

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD9E6)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.notifications_active_rounded,
              color: Color(0xFFFF7DA4),
              size: 18,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF514453),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: writing ? null : () => _dismissCareRequest(request),
            icon: const Icon(Icons.close_rounded, size: 19),
          ),
          FilledButton(
            onPressed: writing ? null : () => _completeCareRequest(request),
            child: const Text('Do it'),
          ),
        ],
      ),
    );
  }

  Widget _outgoingCareRequest(PetCareRequest request, String friendName) {
    final action = switch (request.type) {
      'feed' => 'feed',
      'play' => 'play',
      _ => 'pet',
    };

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 17,
            color: Color(0xFF9B79C8),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              'Waiting for $friendName to $action',
              style: const TextStyle(
                color: Color(0xFF75687A),
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendCareRequest(
    String friendId,
    String type,
    String friendName,
  ) async {
    if (writing) return;
    setState(() => writing = true);

    try {
      await service.sendCareRequest(
        widget.petId,
        receiverId: friendId,
        type: type,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Care request sent to $friendName'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Future<void> _completeCareRequest(PetCareRequest request) async {
    if (writing) return;
    setState(() => writing = true);

    final reaction = switch (request.type) {
      'feed' => FlameMood.eating,
      'play' => FlameMood.playing,
      _ => FlameMood.happy,
    };
    _react(reaction, 1400);

    try {
      await service.completeCareRequest(widget.petId, request);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Future<void> _dismissCareRequest(PetCareRequest request) async {
    if (writing) return;
    setState(() => writing = true);

    try {
      await service.dismissCareRequest(widget.petId, request);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => writing = false);
    }
  }

  Widget _memoriesCard() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFF9B6CC5),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Memories',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Little moments from raising this pet together.',
            style: TextStyle(
              color: Color(0xFF938795),
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SharedPetMemory>>(
            stream: service.watchMemories(widget.petId),
            builder: (context, snapshot) {
              final memories = snapshot.data ?? const <SharedPetMemory>[];

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (memories.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Your first shared-pet memory will appear here.',
                    style: TextStyle(color: Color(0xFF9A8F9D), fontSize: 10),
                  ),
                );
              }

              return Column(
                children: memories.take(6).map(_memoryRow).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _memoryRow(SharedPetMemory memory) {
    final icon = switch (memory.type) {
      'created' => Icons.favorite_rounded,
      'streak' => Icons.local_fire_department_rounded,
      'rename' => Icons.edit_rounded,
      'theme' => Icons.palette_rounded,
      'reward' => Icons.card_giftcard_rounded,
      'careRequest' => Icons.notifications_active_rounded,
      'careCompleted' => Icons.task_alt_rounded,
      _ => Icons.auto_awesome_rounded,
    };

    final color = switch (memory.type) {
      'created' => const Color(0xFFFF7DA4),
      'streak' => const Color(0xFFFF7A6B),
      'rename' => const Color(0xFF7D84D8),
      'theme' => const Color(0xFF9B6CC5),
      'reward' => const Color(0xFFFFA15F),
      'careRequest' => const Color(0xFFFF7DA4),
      'careCompleted' => const Color(0xFF63B985),
      _ => const Color(0xFF9B6CC5),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withAlpha(22),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: const TextStyle(
                    color: Color(0xFF4D4250),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (memory.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    memory.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF958A98),
                      fontSize: 9,
                      height: 1.3,
                    ),
                  ),
                ],
                if (memory.createdAt != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    _memoryDate(memory.createdAt!),
                    style: const TextStyle(
                      color: Color(0xFFB0A5B1),
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _memoryDate(DateTime value) {
    final now = DateTime.now();
    final sameDay =
        value.year == now.year &&
        value.month == now.month &&
        value.day == now.day;

    if (sameDay) {
      final hour = value.hour.toString().padLeft(2, '0');
      final minute = value.minute.toString().padLeft(2, '0');
      return 'Today $hour:$minute';
    }

    return '${value.year}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }

  Widget _dailyReward(SharedPet pet, bool claimedToday) {
    final ready =
        pet.todayChatProgress >= 6 &&
        pet.lastInteractionAt != null &&
        _sameDay(pet.lastInteractionAt!, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0D9),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF9A61)),
          const SizedBox(width: 11),
          const Expanded(
            child: Text(
              'Daily bond reward\n+15 affection · +20 XP',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          FilledButton(
            onPressed: ready && !claimedToday && !writing
                ? () => _perform(
                    SharedPetAction.dailyReward,
                    FlameMood.celebrating,
                  )
                : null,
            child: Text(claimedToday ? 'Claimed' : 'Claim'),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

enum _PetWellbeing { thriving, happy, lonely, needsAttention, sleepy }

class _PetCelebrationData {
  const _PetCelebrationData({
    required this.fromLevel,
    required this.toLevel,
    required this.stage,
    required this.evolved,
  });

  final int fromLevel;
  final int toLevel;
  final PetEvolutionStage stage;
  final bool evolved;
}

class _LevelEvolutionCelebration extends StatefulWidget {
  const _LevelEvolutionCelebration({
    required this.data,
    required this.onDismiss,
  });

  final _PetCelebrationData data;
  final VoidCallback onDismiss;

  @override
  State<_LevelEvolutionCelebration> createState() =>
      _LevelEvolutionCelebrationState();
}

class _LevelEvolutionCelebrationState extends State<_LevelEvolutionCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB3221730),
      child: InkWell(
        onTap: widget.onDismiss,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _CelebrationParticlePainter(t: _controller.value),
                  ),
                ),
                Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: .72, end: 1),
                    duration: const Duration(milliseconds: 520),
                    curve: Curves.easeOutBack,
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 28),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFEEF5), Color(0xFFF4EDFF)],
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x55000000),
                            blurRadius: 28,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFE4EF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              widget.data.evolved
                                  ? Icons.auto_awesome_rounded
                                  : Icons.trending_up_rounded,
                              size: 42,
                              color: const Color(0xFFFF6F9D),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.data.evolved
                                ? 'Evolution unlocked!'
                                : 'Level up!',
                            style: const TextStyle(
                              color: Color(0xFF3F3345),
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 7),
                          if (widget.data.evolved) ...[
                            Text(
                              widget.data.stage.label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF8B64AE),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                          ],
                          Text(
                            'Lv.${widget.data.fromLevel}  →  Lv.${widget.data.toLevel}',
                            style: const TextStyle(
                              color: Color(0xFF766879),
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Keep chatting and caring together to grow even further.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF938795),
                              fontSize: 10.5,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 17),
                          const Text(
                            'Tap anywhere to continue',
                            style: TextStyle(
                              color: Color(0xFFB0A3B2),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CelebrationParticlePainter extends CustomPainter {
  const _CelebrationParticlePainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final pink = Paint()..color = const Color(0xFFFF82AA);
    final violet = Paint()..color = const Color(0xFFAD86E8);
    final gold = Paint()..color = const Color(0xFFFFD86A);

    final paints = [pink, violet, gold];

    for (var i = 0; i < 20; i++) {
      final baseX = (i * 53.0) % size.width;
      final phase = (t + i * .083) % 1.0;
      final y = size.height * (1 - phase);
      final wave = math.sin((phase * math.pi * 2) + i) * 22;
      final x = (baseX + wave).clamp(6.0, size.width - 6.0);
      final radius = 2.5 + (i % 3);

      canvas.drawCircle(Offset(x, y), radius, paints[i % paints.length]);
    }
  }

  @override
  bool shouldRepaint(covariant _CelebrationParticlePainter oldDelegate) {
    return oldDelegate.t != t;
  }
}

class _PetCustomizationResult {
  const _PetCustomizationResult({
    required this.name,
    required this.theme,
    required this.species,
  });

  final String name;
  final String theme;
  final String species;
}

class _FlamePetPainter extends CustomPainter {
  const _FlamePetPainter({
    required this.mood,
    required this.t,
    required this.blinkT,
    required this.stage,
    required this.theme,
    required this.species,
  });

  final FlameMood mood;
  final double t;
  final double blinkT;
  final PetEvolutionStage stage;
  final String theme;
  final PetSpecies species;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 10);
    final base = switch (theme) {
      'violet' => const Color(0xFF9C70DB),
      'sunset' => const Color(0xFFFF8A65),
      'ocean' => const Color(0xFF5B9DE8),
      _ => const Color(0xFFFF7196),
    };

    final colors = switch (stage) {
      PetEvolutionStage.seed => [
        Color.lerp(base, Colors.white, .28)!,
        Color.lerp(base, const Color(0xFFFFC67A), .45)!,
        Color.lerp(base, Colors.white, .55)!,
      ],
      PetEvolutionStage.spark => [
        base,
        Color.lerp(base, const Color(0xFFFF9A73), .4)!,
        Color.lerp(base, const Color(0xFFFFC469), .5)!,
      ],
      PetEvolutionStage.flame => [
        Color.lerp(base, const Color(0xFF7E5DD8), .35)!,
        Color.lerp(base, const Color(0xFFE06CB2), .32)!,
        Color.lerp(base, const Color(0xFFFF8F75), .4)!,
      ],
      PetEvolutionStage.nova => [
        Color.lerp(base, const Color(0xFF496FE6), .55)!,
        Color.lerp(base, const Color(0xFF8A69E9), .5)!,
        Color.lerp(base, const Color(0xFFFF79B6), .38)!,
      ],
    };

    final body = Paint()
      ..shader = LinearGradient(
        colors: colors,
      ).createShader(Rect.fromCenter(center: center, width: 130, height: 160));

    final bodyPath = switch (species) {
      PetSpecies.flame => _flameBody(center),
      PetSpecies.mochi => _mochiBody(center),
      PetSpecies.cloud => _cloudBody(center),
      PetSpecies.star => _starBody(center),
    };

    canvas.drawPath(bodyPath, body);

    if (species == PetSpecies.mochi) {
      final ear = Paint()..color = Color.lerp(colors.first, Colors.white, .12)!;
      final leftEar = Path()
        ..moveTo(center.dx - 46, center.dy - 50)
        ..lineTo(center.dx - 34, center.dy - 92)
        ..lineTo(center.dx - 13, center.dy - 58)
        ..close();
      final rightEar = Path()
        ..moveTo(center.dx + 46, center.dy - 50)
        ..lineTo(center.dx + 34, center.dy - 92)
        ..lineTo(center.dx + 13, center.dy - 58)
        ..close();
      canvas.drawPath(leftEar, ear);
      canvas.drawPath(rightEar, ear);
    }

    switch (species) {
      case PetSpecies.flame:
        _drawFlameFlicker(canvas, center, colors, t);
      case PetSpecies.mochi:
        _drawMochiDetails(canvas, center, colors, mood, t);
      case PetSpecies.cloud:
        _drawCloudDetails(canvas, center, colors, mood, t);
      case PetSpecies.star:
        _drawStarDetails(canvas, center, colors, mood, t);
    }

    if (stage == PetEvolutionStage.spark ||
        stage == PetEvolutionStage.flame ||
        stage == PetEvolutionStage.nova) {
      final glow = Paint()
        ..color = colors.first.withAlpha(
          stage == PetEvolutionStage.nova ? 75 : 45,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          stage == PetEvolutionStage.nova ? 24 : 14,
        );
      canvas.drawCircle(
        center,
        stage == PetEvolutionStage.nova ? 82 : 72,
        glow,
      );
      canvas.drawPath(bodyPath, body);
    }

    if (stage == PetEvolutionStage.flame || stage == PetEvolutionStage.nova) {
      final crown = Paint()
        ..color = stage == PetEvolutionStage.nova
            ? const Color(0xFFFFE37B)
            : const Color(0xFFFFC6E8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 91),
          width: 42,
          height: 14,
        ),
        math.pi,
        math.pi,
        false,
        crown,
      );
    }

    if (stage == PetEvolutionStage.nova) {
      final starPaint = Paint()..color = const Color(0xFFFFE37B);
      for (final offset in const [
        Offset(-66, -48),
        Offset(66, -38),
        Offset(-54, 55),
        Offset(57, 49),
      ]) {
        canvas.drawCircle(center + offset, 3.5, starPaint);
      }
    }

    final eye = Paint()..color = const Color(0xFF4A3244);
    final happy = mood == FlameMood.happy || mood == FlameMood.celebrating;
    final sleepy = mood == FlameMood.sleepy;
    final blink = blinkT > .90 || sleepy;

    final eyeY = center.dy - 4.0;
    final eyeSpread = stage == PetEvolutionStage.nova ? 25.0 : 24.0;

    if (happy) {
      final stroke = Paint()
        ..color = const Color(0xFF4A3244)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx - eyeSpread, eyeY),
          width: 18,
          height: 12,
        ),
        0,
        math.pi,
        false,
        stroke,
      );
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx + eyeSpread, eyeY),
          width: 18,
          height: 12,
        ),
        0,
        math.pi,
        false,
        stroke,
      );
    } else if (blink) {
      final eyelid = Paint()
        ..color = const Color(0xFF4A3244)
        ..style = PaintingStyle.stroke
        ..strokeWidth = sleepy ? 3.2 : 2.8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(center.dx - eyeSpread - 7, eyeY),
        Offset(center.dx - eyeSpread + 7, eyeY),
        eyelid,
      );
      canvas.drawLine(
        Offset(center.dx + eyeSpread - 7, eyeY),
        Offset(center.dx + eyeSpread + 7, eyeY),
        eyelid,
      );
    } else {
      final eyeScale = mood == FlameMood.eating ? 1.08 : 1.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx - eyeSpread, eyeY),
          width: 12 * eyeScale,
          height: 14 * eyeScale,
        ),
        eye,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + eyeSpread, eyeY),
          width: 12 * eyeScale,
          height: 14 * eyeScale,
        ),
        eye,
      );

      final shine = Paint()..color = Colors.white;
      canvas.drawCircle(
        Offset(center.dx - eyeSpread + 2, eyeY - 3),
        2.1,
        shine,
      );
      canvas.drawCircle(
        Offset(center.dx + eyeSpread + 2, eyeY - 3),
        2.1,
        shine,
      );
    }

    final blush = Paint()..color = const Color(0x55FF4D86);
    final blushWidth = happy ? 23.0 : 18.0;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - 40, center.dy + 11),
        width: blushWidth,
        height: 9,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + 40, center.dy + 11),
        width: blushWidth,
        height: 9,
      ),
      blush,
    );

    final mouth = Paint()
      ..color = const Color(0xFF4A3244)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    if (mood == FlameMood.eating) {
      canvas.drawCircle(Offset(center.dx, center.dy + 17), 6, mouth);
      _drawSnack(canvas, Offset(center.dx + 52, center.dy + 39));
    } else if (mood == FlameMood.sleepy) {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 17),
          width: 15,
          height: 7,
        ),
        math.pi,
        math.pi,
        false,
        mouth,
      );
      _drawZzz(canvas, Offset(center.dx + 48, center.dy - 60));
    } else {
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 15),
          width: happy ? 30 : 20,
          height: happy ? 21 : 12,
        ),
        0,
        math.pi,
        false,
        mouth,
      );
    }

    final armPaint = Paint()
      ..color = colors.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    final speciesArmMultiplier = switch (species) {
      PetSpecies.mochi => 1.15,
      PetSpecies.cloud => .75,
      PetSpecies.star => 1.25,
      PetSpecies.flame => 1.0,
    };

    final armWave =
        (mood == FlameMood.playing
            ? math.sin(t * math.pi * 2) * 18
            : mood == FlameMood.celebrating
            ? 23.0
            : mood == FlameMood.happy
            ? 10.0
            : 0.0) *
        speciesArmMultiplier;

    canvas.drawLine(
      Offset(center.dx - 44, center.dy + 30),
      Offset(center.dx - 64, center.dy + 43 - armWave),
      armPaint,
    );
    canvas.drawLine(
      Offset(center.dx + 44, center.dy + 30),
      Offset(center.dx + 64, center.dy + 43 - armWave),
      armPaint,
    );

    if (mood == FlameMood.playing) {
      final effectCenter = Offset(
        center.dx + 67,
        center.dy - 35 + math.sin(t * math.pi * 2) * 8,
      );

      switch (species) {
        case PetSpecies.flame:
          _drawPlaySpark(canvas, effectCenter);
        case PetSpecies.mochi:
          _drawPawSpark(canvas, effectCenter);
        case PetSpecies.cloud:
          _drawCloudDrops(canvas, effectCenter);
        case PetSpecies.star:
          _drawStarBurst(canvas, effectCenter);
      }
    }

    if (happy) {
      _heart(canvas, Offset(center.dx + 65, center.dy - 45), 10);
      if (mood == FlameMood.celebrating) {
        _heart(canvas, Offset(center.dx - 63, center.dy - 32), 7);
        _drawPlaySpark(canvas, Offset(center.dx, center.dy - 112));
      }
    }
  }

  void _drawFlameFlicker(
    Canvas canvas,
    Offset center,
    List<Color> colors,
    double t,
  ) {
    final flicker = Paint()
      ..color = Color.lerp(colors.last, Colors.white, .25)!.withAlpha(175);

    final y = center.dy - 77 - math.sin(t * math.pi * 2) * 6;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(center.dx + 8, y), width: 14, height: 30),
      flicker,
    );
  }

  void _drawMochiDetails(
    Canvas canvas,
    Offset center,
    List<Color> colors,
    FlameMood mood,
    double t,
  ) {
    final tail = Paint()
      ..color = colors.first
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round;

    final wag = mood == FlameMood.happy || mood == FlameMood.playing
        ? math.sin(t * math.pi * 4) * 15
        : math.sin(t * math.pi * 2) * 5;

    final tailPath = Path()
      ..moveTo(center.dx + 49, center.dy + 42)
      ..quadraticBezierTo(
        center.dx + 83,
        center.dy + 25 + wag,
        center.dx + 70,
        center.dy - 1 + wag,
      );
    canvas.drawPath(tailPath, tail);

    final innerEar = Paint()..color = const Color(0x66FFB0C5);
    canvas.drawPath(
      Path()
        ..moveTo(center.dx - 37, center.dy - 55)
        ..lineTo(center.dx - 33, center.dy - 80)
        ..lineTo(center.dx - 21, center.dy - 59)
        ..close(),
      innerEar,
    );
    canvas.drawPath(
      Path()
        ..moveTo(center.dx + 37, center.dy - 55)
        ..lineTo(center.dx + 33, center.dy - 80)
        ..lineTo(center.dx + 21, center.dy - 59)
        ..close(),
      innerEar,
    );

    final whisker = Paint()
      ..color = const Color(0x884A3244)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (final y in [-1.0, 6.0]) {
      canvas.drawLine(
        Offset(center.dx - 37, center.dy + y),
        Offset(center.dx - 58, center.dy + y - 4),
        whisker,
      );
      canvas.drawLine(
        Offset(center.dx + 37, center.dy + y),
        Offset(center.dx + 58, center.dy + y - 4),
        whisker,
      );
    }
  }

  void _drawCloudDetails(
    Canvas canvas,
    Offset center,
    List<Color> colors,
    FlameMood mood,
    double t,
  ) {
    final puff = Paint()..color = Colors.white.withAlpha(105);

    final offset = math.sin(t * math.pi * 2) * 4;
    canvas.drawCircle(
      Offset(center.dx - 29, center.dy - 34 + offset),
      10,
      puff,
    );
    canvas.drawCircle(Offset(center.dx + 25, center.dy - 42 - offset), 8, puff);

    if (mood == FlameMood.sleepy) {
      final mist = Paint()
        ..color = colors.first.withAlpha(55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy + 66),
          width: 100,
          height: 20,
        ),
        mist,
      );
    }
  }

  void _drawStarDetails(
    Canvas canvas,
    Offset center,
    List<Color> colors,
    FlameMood mood,
    double t,
  ) {
    final sparkle = Paint()..color = const Color(0xFFFFE477);
    final orbit = t * math.pi * 2;

    for (var i = 0; i < 3; i++) {
      final angle = orbit + i * math.pi * 2 / 3;
      final radius = mood == FlameMood.happy ? 88.0 : 80.0;
      final p = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      canvas.drawCircle(p, 3.5 + i, sparkle);
    }
  }

  void _drawPawSpark(Canvas canvas, Offset center) {
    final paint = Paint()..color = const Color(0xFFFF9DB7);
    canvas.drawCircle(Offset(center.dx, center.dy + 3), 5, paint);
    canvas.drawCircle(Offset(center.dx - 6, center.dy - 4), 3, paint);
    canvas.drawCircle(Offset(center.dx, center.dy - 7), 3, paint);
    canvas.drawCircle(Offset(center.dx + 6, center.dy - 4), 3, paint);
  }

  void _drawCloudDrops(Canvas canvas, Offset center) {
    final paint = Paint()..color = const Color(0xFF78B9F2);
    for (var i = 0; i < 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(center.dx + i * 9 - 9, center.dy + i * 6),
          width: 5,
          height: 10,
        ),
        paint,
      );
    }
  }

  void _drawStarBurst(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFFFFDB61)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3;
      final inner = Offset(
        center.dx + math.cos(angle) * 4,
        center.dy + math.sin(angle) * 4,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * 13,
        center.dy + math.sin(angle) * 13,
      );
      canvas.drawLine(inner, outer, paint);
    }
  }

  Path _flameBody(Offset center) {
    return Path()
      ..moveTo(center.dx, center.dy + 72)
      ..cubicTo(
        center.dx - 65,
        center.dy + 64,
        center.dx - 67,
        center.dy + 6,
        center.dx - 39,
        center.dy - 27,
      )
      ..cubicTo(
        center.dx - 18,
        center.dy - 51,
        center.dx - 23,
        center.dy - 75,
        center.dx - 10,
        center.dy - 96,
      )
      ..cubicTo(
        center.dx - 1,
        center.dy - 75,
        center.dx + 20,
        center.dy - 66,
        center.dx + 15,
        center.dy - 40,
      )
      ..cubicTo(
        center.dx + 48,
        center.dy - 55,
        center.dx + 68,
        center.dy - 18,
        center.dx + 59,
        center.dy + 19,
      )
      ..cubicTo(
        center.dx + 52,
        center.dy + 54,
        center.dx + 32,
        center.dy + 71,
        center.dx,
        center.dy + 72,
      )
      ..close();
  }

  Path _mochiBody(Offset center) {
    return Path()
      ..moveTo(center.dx, center.dy - 69)
      ..cubicTo(
        center.dx - 58,
        center.dy - 69,
        center.dx - 67,
        center.dy - 20,
        center.dx - 61,
        center.dy + 26,
      )
      ..cubicTo(
        center.dx - 57,
        center.dy + 65,
        center.dx - 31,
        center.dy + 76,
        center.dx,
        center.dy + 76,
      )
      ..cubicTo(
        center.dx + 31,
        center.dy + 76,
        center.dx + 57,
        center.dy + 65,
        center.dx + 61,
        center.dy + 26,
      )
      ..cubicTo(
        center.dx + 67,
        center.dy - 20,
        center.dx + 58,
        center.dy - 69,
        center.dx,
        center.dy - 69,
      )
      ..close();
  }

  Path _cloudBody(Offset center) {
    final path = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx - 34, center.dy + 4),
          radius: 39,
        ),
      )
      ..addOval(
        Rect.fromCircle(center: Offset(center.dx, center.dy - 24), radius: 49),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(center.dx + 39, center.dy + 5),
          radius: 36,
        ),
      )
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + 29),
            width: 121,
            height: 67,
          ),
          const Radius.circular(31),
        ),
      );
    return path;
  }

  Path _starBody(Offset center) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final radius = i.isEven ? 78.0 : 48.0;
      final point = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  void _drawSnack(Canvas canvas, Offset center) {
    final cookie = Paint()..color = const Color(0xFFFFC267);
    canvas.drawCircle(center, 14, cookie);

    final chip = Paint()..color = const Color(0xFF9C6643);
    for (final offset in const [
      Offset(-5, -4),
      Offset(5, -3),
      Offset(-2, 5),
      Offset(6, 5),
    ]) {
      canvas.drawCircle(center + offset, 2.2, chip);
    }
  }

  void _drawPlaySpark(Canvas canvas, Offset center) {
    final paint = Paint()
      ..color = const Color(0xFFFFD85C)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - 5, center.dy - 5),
      Offset(center.dx + 5, center.dy + 5),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + 5, center.dy - 5),
      Offset(center.dx - 5, center.dy + 5),
      paint,
    );
  }

  void _drawZzz(Canvas canvas, Offset start) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: const TextSpan(
        text: 'Zzz',
        style: TextStyle(
          color: Color(0xFF9877B8),
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    )..layout();

    painter.paint(canvas, start);
  }

  void _heart(Canvas canvas, Offset c, double s) {
    final paint = Paint()..color = const Color(0xFFFF5C91);
    final path = Path()
      ..moveTo(c.dx, c.dy + s)
      ..cubicTo(c.dx - s * 1.4, c.dy, c.dx - s, c.dy - s, c.dx, c.dy - s * .25)
      ..cubicTo(c.dx + s, c.dy - s, c.dx + s * 1.4, c.dy, c.dx, c.dy + s)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _FlamePetPainter oldDelegate) {
    return oldDelegate.mood != mood ||
        oldDelegate.t != t ||
        oldDelegate.blinkT != blinkT ||
        oldDelegate.stage != stage ||
        oldDelegate.theme != theme ||
        oldDelegate.species != species;
  }
}
