import 'package:cloud_firestore/cloud_firestore.dart';

class SharedPet {
  const SharedPet({
    required this.id,
    required this.petName,
    required this.memberIds,
    required this.memberNames,
    required this.streakDays,
    required this.level,
    required this.xp,
    required this.affection,
    required this.energy,
    required this.chatProgress,
    required this.contributions,
    required this.lastInteractionAt,
    required this.lastDailyClaimDate,
    required this.lastChatDate,
    required this.claimedStreakMilestones,
    required this.petTheme,
    required this.petSpecies,
  });

  final String id;
  final String petName;
  final List<String> memberIds;
  final Map<String, String> memberNames;
  final int streakDays;
  final int level;
  final int xp;
  final int affection;
  final int energy;
  final int chatProgress;
  final Map<String, int> contributions;
  final DateTime? lastInteractionAt;
  final String? lastDailyClaimDate;
  final String? lastChatDate;
  final List<int> claimedStreakMilestones;
  final String petTheme;
  final String petSpecies;

  factory SharedPet.fromDoc(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};

    return SharedPet(
      id: document.id,
      petName: data['petName'] as String? ?? 'Vono Pet',
      memberIds: List<String>.from(
        data['memberIds'] as List? ?? const <String>[],
      ),
      memberNames: Map<String, String>.from(
        data['memberNames'] as Map? ?? const <String, String>{},
      ),
      streakDays: data['streakDays'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      xp: data['xp'] as int? ?? 0,
      affection: data['affection'] as int? ?? 0,
      energy: data['energy'] as int? ?? 70,
      chatProgress: data['chatProgress'] as int? ?? 0,
      contributions: Map<String, int>.from(
        data['contributions'] as Map? ?? const <String, int>{},
      ),
      lastInteractionAt: (data['lastInteractionAt'] as Timestamp?)?.toDate(),
      lastDailyClaimDate: data['lastDailyClaimDate'] as String?,
      lastChatDate: data['lastChatDate'] as String?,
      claimedStreakMilestones: List<int>.from(
        data['claimedStreakMilestones'] as List? ?? const <int>[],
      ),
      petTheme: data['petTheme'] as String? ?? 'rose',
      petSpecies: data['petSpecies'] as String? ?? 'flame',
    );
  }

  String friendId(String myId) {
    for (final id in memberIds) {
      if (id != myId) return id;
    }
    return myId;
  }

  String friendName(String myId) {
    final id = friendId(myId);
    return memberNames[id] ?? 'Friend';
  }

  int contributionFor(String userId) => contributions[userId] ?? 0;

  int bondPercent() => ((affection / 500) * 100).round().clamp(0, 100);

  bool get hasChattedToday => lastChatDate == _dateKey(DateTime.now());

  int get todayChatProgress => hasChattedToday ? chatProgress : 0;

  bool get streakAtRisk => streakDays > 0 && !hasChattedToday;

  static String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  PetEvolutionStage get evolutionStage {
    if (level >= 20) return PetEvolutionStage.nova;
    if (level >= 10) return PetEvolutionStage.flame;
    if (level >= 5) return PetEvolutionStage.spark;
    return PetEvolutionStage.seed;
  }

  int? get nextEvolutionLevel {
    return switch (evolutionStage) {
      PetEvolutionStage.seed => 5,
      PetEvolutionStage.spark => 10,
      PetEvolutionStage.flame => 20,
      PetEvolutionStage.nova => null,
    };
  }

  double get evolutionProgress {
    final next = nextEvolutionLevel;
    if (next == null) return 1;

    final start = switch (evolutionStage) {
      PetEvolutionStage.seed => 1,
      PetEvolutionStage.spark => 5,
      PetEvolutionStage.flame => 10,
      PetEvolutionStage.nova => 20,
    };

    final span = next - start;
    if (span <= 0) return 1;
    return ((level - start) / span).clamp(0.0, 1.0);
  }
}

enum PetSpecies {
  flame,
  mochi,
  cloud,
  star;

  static PetSpecies fromKey(String value) => switch (value) {
    'mochi' => PetSpecies.mochi,
    'cloud' => PetSpecies.cloud,
    'star' => PetSpecies.star,
    _ => PetSpecies.flame,
  };

  String get key => name;
  String get label => switch (this) {
    PetSpecies.flame => 'Vono Flame',
    PetSpecies.mochi => 'Mochi Cat',
    PetSpecies.cloud => 'Cloudy',
    PetSpecies.star => 'Twinkle',
  };
}

enum PetEvolutionStage {
  seed,
  spark,
  flame,
  nova;

  String get label => switch (this) {
    PetEvolutionStage.seed => 'Little Ember',
    PetEvolutionStage.spark => 'Bright Spark',
    PetEvolutionStage.flame => 'Vono Flame',
    PetEvolutionStage.nova => 'Nova Heart',
  };

  String get shortLabel => switch (this) {
    PetEvolutionStage.seed => 'Ember',
    PetEvolutionStage.spark => 'Spark',
    PetEvolutionStage.flame => 'Flame',
    PetEvolutionStage.nova => 'Nova',
  };
}
