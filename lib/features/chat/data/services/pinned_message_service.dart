import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinnedMessageService {
  PinnedMessageService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _myId => _auth.currentUser!.uid;

  DocumentReference<Map<String, dynamic>> _preference(String id) => _db
      .collection('users')
      .doc(_myId)
      .collection('contactPreferences')
      .doc(id);

  Stream<Map<String, dynamic>> directPreferences(String otherId) =>
      _preference(otherId).snapshots().map((snapshot) => snapshot.data() ?? {});

  Stream<Map<String, dynamic>> groupPreferences(String groupId) =>
      _preference('group_$groupId')
          .snapshots()
          .map((snapshot) => snapshot.data() ?? {});

  Stream<Map<String, dynamic>> preferencesById(String preferenceId) =>
      _preference(preferenceId)
          .snapshots()
          .map((snapshot) => snapshot.data() ?? {});

  Future<void> pinDirect({
    required String otherId,
    required String messageId,
    required Map<String, dynamic> data,
    required String senderName,
  }) =>
      _pin(
        preferenceId: otherId,
        messageId: messageId,
        data: data,
        senderName: senderName,
      );

  Future<void> pinGroup({
    required String groupId,
    required String messageId,
    required Map<String, dynamic> data,
    required String senderName,
  }) =>
      _pin(
        preferenceId: 'group_$groupId',
        messageId: messageId,
        data: data,
        senderName: senderName,
      );

  Future<void> removeDirect(String otherId, String messageId) =>
      _remove(otherId, messageId);

  Future<void> removeGroup(String groupId, String messageId) =>
      _remove('group_$groupId', messageId);

  Future<void> clearDirect(String otherId) => _clear(otherId);

  Future<void> clearGroup(String groupId) => _clear('group_$groupId');

  Future<void> _pin({
    required String preferenceId,
    required String messageId,
    required Map<String, dynamic> data,
    required String senderName,
  }) async {
    final reference = _preference(preferenceId);
    final snapshot = await reference.get();
    final current = parsePinned(snapshot.data());

    final next = current
        .where((item) => item['messageId'] != messageId)
        .toList();

    next.insert(0, {
      'messageId': messageId,
      'preview': _preview(data),
      'sender': senderName,
      'type': data['type'] as String? ?? 'text',
      'pinnedAt': Timestamp.now(),
    });

    await reference.set({
      'pinnedMessages': next.take(20).toList(),
      'pinnedMessagesUpdatedAt': FieldValue.serverTimestamp(),
      'pinnedMessageId': FieldValue.delete(),
      'pinnedMessagePreview': FieldValue.delete(),
      'pinnedMessageSender': FieldValue.delete(),
      'pinnedMessageType': FieldValue.delete(),
      'pinnedMessageAt': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  Future<void> _remove(String preferenceId, String messageId) async {
    final reference = _preference(preferenceId);
    final snapshot = await reference.get();
    final next = parsePinned(snapshot.data())
        .where((item) => item['messageId'] != messageId)
        .toList();

    await reference.set({
      'pinnedMessages': next,
      'pinnedMessagesUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _clear(String preferenceId) => _preference(preferenceId).set({
        'pinnedMessages': <Map<String, dynamic>>[],
        'pinnedMessagesUpdatedAt': FieldValue.serverTimestamp(),
        'pinnedMessageId': FieldValue.delete(),
        'pinnedMessagePreview': FieldValue.delete(),
        'pinnedMessageSender': FieldValue.delete(),
        'pinnedMessageType': FieldValue.delete(),
        'pinnedMessageAt': FieldValue.delete(),
      }, SetOptions(merge: true));

  static List<Map<String, dynamic>> parsePinned(Map<String, dynamic>? data) {
    if (data == null) return const [];

    final result = <Map<String, dynamic>>[];
    final raw = data['pinnedMessages'];

    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          final normalized = Map<String, dynamic>.from(item);
          final id = normalized['messageId']?.toString() ?? '';
          if (id.isNotEmpty) {
            normalized['messageId'] = id;
            result.add(normalized);
          }
        }
      }
    }

    if (result.isNotEmpty) return result;

    final legacyId = data['pinnedMessageId']?.toString() ?? '';
    if (legacyId.isEmpty) return const [];

    return [
      {
        'messageId': legacyId,
        'preview': data['pinnedMessagePreview']?.toString() ?? 'Pinned message',
        'sender': data['pinnedMessageSender']?.toString() ?? '',
        'type': data['pinnedMessageType']?.toString() ?? 'text',
        'pinnedAt': data['pinnedMessageAt'],
      },
    ];
  }

  String _preview(Map<String, dynamic> data) {
    final type = data['type'] as String? ?? 'text';
    if (type == 'image') return 'Photo';
    if (type == 'voice') return 'Voice message';
    if (type == 'file') return data['fileName'] as String? ?? 'File';

    final value =
        (data['text'] as String? ?? '').replaceAll('\n', ' ').trim();
    return value.isEmpty ? 'Message' : value;
  }
}
