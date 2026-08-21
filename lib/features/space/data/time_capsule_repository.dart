import 'package:cloud_firestore/cloud_firestore.dart';

import '../presentation/time_capsule/models/time_capsule_item.dart';

class TimeCapsuleRepository {
  TimeCapsuleRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _capsulesRef(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('timeCapsules');
  }

  Stream<List<TimeCapsuleItem>> watchCapsules(String userId) {
    return _capsulesRef(userId).snapshots().map((snapshot) {
      final capsules = snapshot.docs.map((document) {
        final data = document.data();

        final createdAt = data['createdAt'];
        final unlockDate = data['unlockDate'];

        return TimeCapsuleItem(
          id: document.id,
          title: data['title'] as String? ?? '',
          content: data['content'] as String? ?? '',
          createdAt: createdAt is Timestamp
              ? createdAt.toDate()
              : DateTime.now(),
          unlockDate: unlockDate is Timestamp
              ? unlockDate.toDate()
              : DateTime.now(),
        );
      }).toList();

      capsules.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return capsules;
    });
  }

  Future<void> createCapsule({
    required String userId,
    required TimeCapsuleItem capsule,
  }) {
    return _capsulesRef(userId).doc(capsule.id).set({
      'title': capsule.title,
      'content': capsule.content,
      'createdAt': Timestamp.fromDate(capsule.createdAt),
      'unlockDate': Timestamp.fromDate(capsule.unlockDate),
    });
  }

  Future<void> deleteCapsule({
    required String userId,
    required String capsuleId,
  }) {
    return _capsulesRef(userId).doc(capsuleId).delete();
  }
}
