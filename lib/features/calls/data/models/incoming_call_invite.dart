import 'package:cloud_firestore/cloud_firestore.dart';

class IncomingCallInvite {
  const IncomingCallInvite({
    required this.id,
    required this.callerId,
    required this.callerName,
    required this.callerPhotoUrl,
    required this.createdAt,
  });

  final String id;
  final String callerId;
  final String callerName;
  final String? callerPhotoUrl;
  final DateTime? createdAt;

  factory IncomingCallInvite.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return IncomingCallInvite(
      id: document.id,
      callerId: data['callerId'] as String? ?? '',
      callerName: data['callerName'] as String? ?? 'VonoTalky user',
      callerPhotoUrl: data['callerPhotoUrl'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
