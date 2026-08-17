import 'package:cloud_firestore/cloud_firestore.dart';

class PetCareRequest {
  const PetCareRequest({
    required this.id,
    required this.type,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.respondedAt,
  });

  final String id;
  final String type;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  bool get isPending => status == 'pending';

  factory PetCareRequest.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};

    return PetCareRequest(
      id: document.id,
      type: data['type'] as String? ?? 'pet',
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      status: data['status'] as String? ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
    );
  }
}
