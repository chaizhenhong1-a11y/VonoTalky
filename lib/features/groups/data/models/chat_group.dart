import 'package:cloud_firestore/cloud_firestore.dart';

class ChatGroup {
  const ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.adminIds,
    required this.memberIds,
    required this.memberCount,
    this.photoUrl,
    this.lastMessage = '',
    this.updatedAt,
    this.unreadCount = 0,
  });
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final List<String> adminIds;
  final List<String> memberIds;
  final int memberCount;
  final String? photoUrl;
  final String lastMessage;
  final DateTime? updatedAt;
  final int unreadCount;

  factory ChatGroup.fromDoc(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};
    return ChatGroup(
      id: document.id,
      name: data['name'] as String? ?? 'Unnamed group',
      description: data['description'] as String? ?? '',
      ownerId: data['ownerId'] as String? ?? '',
      adminIds: List<String>.from(data['adminIds'] as List? ?? const []),
      memberIds: List<String>.from(data['memberIds'] as List? ?? const []),
      memberCount: data['memberCount'] as int? ?? 0,
      photoUrl: data['photoUrl'] as String?,
      lastMessage: data['lastMessage'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      unreadCount:
          ((data['unreadCounts'] as Map<String, dynamic>? ??
                          const {})[GroupServiceIdentity.currentUid]
                      as num? ??
                  0)
              .toInt(),
    );
  }
}

abstract final class GroupServiceIdentity {
  static String currentUid = '';
}
