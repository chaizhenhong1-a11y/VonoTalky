import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SharedPetChatProgressService {
  SharedPetChatProgressService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User? get _user => _auth.currentUser;

  Future<void> recordSuccessfulMessage({required String friendId}) async {
    final user = _user;
    if (user == null || friendId == user.uid) return;

    final query = await _firestore
        .collection('sharedPets')
        .where('memberIds', arrayContains: user.uid)
        .get();

    DocumentReference<Map<String, dynamic>>? petRef;

    for (final document in query.docs) {
      final members = List<String>.from(
        document.data()['memberIds'] as List? ?? const <String>[],
      );
      if (members.contains(friendId)) {
        petRef = document.reference;
        break;
      }
    }

    // Chatting with a friend who has no shared pet is still normal chat.
    if (petRef == null) return;

    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(petRef!);
      if (!snapshot.exists) return;

      final data = snapshot.data() ?? const <String, dynamic>{};
      final members = List<String>.from(
        data['memberIds'] as List? ?? const <String>[],
      );

      if (!members.contains(user.uid) || !members.contains(friendId)) {
        return;
      }

      final previousDate = data['lastChatDate'] as String?;
      final currentStreak = data['streakDays'] as int? ?? 0;
      final currentProgress = data['chatProgress'] as int? ?? 0;
      final contributions = Map<String, int>.from(
        data['contributions'] as Map? ?? const <String, int>{},
      );

      var nextStreak = currentStreak;
      var nextProgress = currentProgress;

      if (previousDate == today) {
        nextProgress = (currentProgress + 1).clamp(0, 10);
      } else {
        nextProgress = 1;

        if (previousDate == yesterday) {
          nextStreak = currentStreak <= 0 ? 1 : currentStreak + 1;
        } else {
          nextStreak = 1;
        }
      }

      contributions[user.uid] = (contributions[user.uid] ?? 0) + 1;

      transaction.update(petRef, {
        'chatProgress': nextProgress,
        'streakDays': nextStreak,
        'contributions': contributions,
        'lastChatDate': today,
        'lastChatAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
