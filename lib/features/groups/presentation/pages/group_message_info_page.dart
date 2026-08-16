import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';

class GroupMessageInfoPage extends StatelessWidget {
  const GroupMessageInfoPage({
    super.key,
    required this.groupId,
    required this.messageId,
    required this.message,
  });

  final String groupId;
  final String messageId;
  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final sentAt = (message['sentAt'] as Timestamp?)?.toDate();
    final senderId = message['senderId'] as String? ?? '';
    final readBy = List<String>.from(
      message['readBy'] as List? ?? const [],
    ).where((uid) => uid != senderId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F7FC),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Message info',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
        children: [
          _MessagePreview(message: message),
          const SizedBox(height: 16),
          _InfoCard(
            icon: Icons.schedule_rounded,
            title: 'Sent',
            value: sentAt == null ? 'Unknown' : _dateTime(sentAt),
          ),
          const SizedBox(height: 10),
          _InfoCard(
            icon: Icons.done_all_rounded,
            title: 'Seen by',
            value:
                '${readBy.length} ${readBy.length == 1 ? 'member' : 'members'}',
          ),
          const SizedBox(height: 18),
          const Text(
            'Seen by',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          if (readBy.isEmpty)
            const _EmptySeenState()
          else
            ...readBy.map((uid) => _SeenMemberTile(uid: uid)),
          const SizedBox(height: 12),
          Text(
            'Message ID: $messageId',
            style: const TextStyle(color: Color(0xFF968E9D), fontSize: 10),
          ),
        ],
      ),
    );
  }

  static String _dateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/'
      '${value.year}  '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _SeenMemberTile extends StatelessWidget {
  const _SeenMemberTile({required this.uid});

  final String uid;

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context, snapshot) {
          final document = snapshot.data;
          final user = document != null && document.exists
              ? ChatUser.fromDoc(document)
              : null;

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 3,
              ),
              leading: CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFE5DAF5),
                backgroundImage: user?.photoUrl == null
                    ? null
                    : NetworkImage(user!.photoUrl!),
                child: user?.photoUrl == null
                    ? Text(
                        _initial(user?.name ?? ''),
                        style: const TextStyle(
                          color: Color(0xFF65439B),
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : null,
              ),
              title: Text(
                user?.name ?? 'Member',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: user?.email.isNotEmpty == true
                  ? Text(
                      user!.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              trailing: const Icon(
                Icons.done_all_rounded,
                size: 19,
                color: Color(0xFF7653A5),
              ),
            ),
          );
        },
      );

  static String _initial(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.message});

  final Map<String, dynamic> message;

  @override
  Widget build(BuildContext context) {
    final type = message['type'] as String? ?? 'text';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E9F8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_typeIcon(type), color: const Color(0xFF7653A5)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _preview(message),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF514B57),
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _preview(Map<String, dynamic> data) {
    if (data['isDeleted'] as bool? ?? false) {
      return 'This message was recalled';
    }

    final type = data['type'] as String? ?? 'text';
    if (type == 'image') return 'Photo';
    if (type == 'voice') return 'Voice message';
    if (type == 'file') {
      return data['fileName'] as String? ?? 'File';
    }

    final text = (data['text'] as String? ?? '').replaceAll('\n', ' ').trim();
    return text.isEmpty ? 'Message' : text;
  }

  static IconData _typeIcon(String type) {
    if (type == 'image') return Icons.image_outlined;
    if (type == 'voice') return Icons.mic_none_rounded;
    if (type == 'file') return Icons.attach_file_rounded;
    return Icons.chat_bubble_outline_rounded;
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF7653A5)),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF6A626F),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _EmptySeenState extends StatelessWidget {
  const _EmptySeenState();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Column(
      children: [
        Icon(Icons.visibility_off_outlined, size: 34, color: Color(0xFF9A92A3)),
        SizedBox(height: 8),
        Text(
          'No one else has seen this message yet.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF756E7C)),
        ),
      ],
    ),
  );
}
