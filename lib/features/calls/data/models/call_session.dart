import 'package:cloud_firestore/cloud_firestore.dart';

enum CallSessionStatus { ringing, accepted, rejected, ended, failed }

class CallSession {
  const CallSession({
    required this.id,
    required this.callerId,
    required this.calleeId,
    required this.status,
    required this.createdAt,
    this.answeredAt,
    this.endedAt,
  });

  final String id;
  final String callerId;
  final String calleeId;
  final CallSessionStatus status;
  final DateTime? createdAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;

  factory CallSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? const <String, dynamic>{};
    return CallSession(
      id: document.id,
      callerId: data['callerId'] as String? ?? '',
      calleeId: data['calleeId'] as String? ?? '',
      status: _statusFromWire(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      answeredAt: (data['answeredAt'] as Timestamp?)?.toDate(),
      endedAt: (data['endedAt'] as Timestamp?)?.toDate(),
    );
  }

  static CallSessionStatus _statusFromWire(String? value) {
    return switch (value) {
      'accepted' => CallSessionStatus.accepted,
      'rejected' => CallSessionStatus.rejected,
      'ended' => CallSessionStatus.ended,
      'failed' => CallSessionStatus.failed,
      _ => CallSessionStatus.ringing,
    };
  }
}
