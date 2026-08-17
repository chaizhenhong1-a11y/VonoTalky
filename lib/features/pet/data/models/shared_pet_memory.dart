import 'package:cloud_firestore/cloud_firestore.dart';

class SharedPetMemory {
  const SharedPetMemory({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    required this.actorId,
  });

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime? createdAt;
  final String? actorId;

  factory SharedPetMemory.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return SharedPetMemory(
      id: document.id,
      type: data['type'] as String? ?? 'event',
      title: data['title'] as String? ?? 'Pet memory',
      subtitle: data['subtitle'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      actorId: data['actorId'] as String?,
    );
  }
}
