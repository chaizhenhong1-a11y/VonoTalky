import 'package:cloud_firestore/cloud_firestore.dart';

class PetInvite {
  const PetInvite({
    required this.id,
    required this.memberIds,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.petName,
    required this.status,
    required this.createdAt,
    required this.respondedAt,
    required this.petId,
  });

  final String id;
  final List<String> memberIds;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String petName;
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;
  final String? petId;

  bool get isPending => status == 'pending';

  factory PetInvite.fromDoc(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};

    return PetInvite(
      id: document.id,
      memberIds: List<String>.from(
        data['memberIds'] as List? ?? const <String>[],
      ),
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? 'Friend',
      receiverId: data['receiverId'] as String? ?? '',
      receiverName: data['receiverName'] as String? ?? 'Friend',
      petName: data['petName'] as String? ?? 'Vono Pet',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      petId: data['petId'] as String?,
    );
  }
}
