import 'package:cloud_firestore/cloud_firestore.dart';

class ChatUser {
  const ChatUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio = '',
    this.phone = '',
    this.isOnline = false,
    this.lastSeen,
  });
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String bio;
  final String phone;
  final bool isOnline;
  final DateTime? lastSeen;

  factory ChatUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final name = (data['displayName'] as String? ?? '').trim();
    final presenceUpdatedAt = (data['presenceUpdatedAt'] as Timestamp?)
        ?.toDate();
    final heartbeatIsFresh =
        presenceUpdatedAt != null &&
        DateTime.now().difference(presenceUpdatedAt).inSeconds < 90;
    return ChatUser(
      uid: doc.id,
      name: name.isEmpty ? 'VonoTalky user' : name,
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      bio: data['bio'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      isOnline: (data['isOnline'] as bool? ?? false) && heartbeatIsFresh,
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
}
