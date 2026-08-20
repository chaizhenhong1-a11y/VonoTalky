class TimeCapsuleItem {
  const TimeCapsuleItem({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.unlockDate,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime unlockDate;

  bool isUnlocked([DateTime? now]) {
    final current = now ?? DateTime.now();

    final today = DateTime(current.year, current.month, current.day);

    final unlockDay = DateTime(
      unlockDate.year,
      unlockDate.month,
      unlockDate.day,
    );

    return !today.isBefore(unlockDay);
  }
}
