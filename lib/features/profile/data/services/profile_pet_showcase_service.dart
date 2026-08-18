import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../pet/data/models/shared_pet.dart';

class ProfilePetShowcaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get myId => _auth.currentUser!.uid;

  Stream<List<Map<String, dynamic>>> watchUserShowcase(String uid) =>
      _db.collection('users').doc(uid).snapshots().map((snapshot) {
        final data = snapshot.data() ?? const <String, dynamic>{};
        final raw = data['profilePetShowcase'] as List? ?? const [];

        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      });

  Future<void> saveShowcase(List<SharedPet> pets) async {
    final selected = pets
        .take(3)
        .map((pet) {
          return <String, dynamic>{
            'petId': pet.id,
            'name': pet.petName,
            'level': pet.level,
          };
        })
        .toList(growable: false);

    await _db.collection('users').doc(myId).set({
      'profilePetShowcase': selected,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
