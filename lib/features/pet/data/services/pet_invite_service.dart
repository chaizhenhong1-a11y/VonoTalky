import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/pet_invite.dart';

class PetInviteService {
  PetInviteService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  User get currentUser {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to use shared pets.');
    }
    return user;
  }

  String get myId => currentUser.uid;

  CollectionReference<Map<String, dynamic>> get _invites =>
      _firestore.collection('petInvites');

  CollectionReference<Map<String, dynamic>> get _pets =>
      _firestore.collection('sharedPets');

  Stream<List<PetInvite>> watchMyPendingInvites() {
    final uid = myId;

    return _invites.where('memberIds', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final invites = snapshot.docs
          .map(PetInvite.fromDoc)
          .where((invite) => invite.isPending)
          .toList();

      invites.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return invites;
    });
  }

  Stream<PetInvite?> watchPendingInviteWith(String friendId) {
    final uid = myId;

    return _invites.where('memberIds', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final invites = snapshot.docs
          .map(PetInvite.fromDoc)
          .where(
            (invite) => invite.isPending && invite.memberIds.contains(friendId),
          )
          .toList();

      if (invites.isEmpty) return null;

      invites.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      return invites.first;
    });
  }

  Future<void> sendInvite({
    required String friendId,
    required String friendName,
    required String petName,
  }) async {
    final me = currentUser;
    final name = petName.trim().isEmpty ? 'Vono Pet' : petName.trim();

    if (friendId == me.uid) {
      throw StateError('You cannot raise a pet with yourself.');
    }

    final petSnapshot = await _pets
        .where('memberIds', arrayContains: me.uid)
        .get();

    for (final document in petSnapshot.docs) {
      final members = List<String>.from(
        document.data()['memberIds'] as List? ?? const <String>[],
      );
      if (members.contains(friendId)) {
        throw StateError('You already have a shared pet with this friend.');
      }
    }

    final inviteSnapshot = await _invites
        .where('memberIds', arrayContains: me.uid)
        .get();

    for (final document in inviteSnapshot.docs) {
      final invite = PetInvite.fromDoc(document);
      if (invite.isPending && invite.memberIds.contains(friendId)) {
        throw StateError('A pet invitation is already pending.');
      }
    }

    final myName = me.displayName?.trim().isNotEmpty == true
        ? me.displayName!.trim()
        : (me.email ?? 'Friend');

    await _invites.add({
      'memberIds': [me.uid, friendId],
      'senderId': me.uid,
      'senderName': myName,
      'receiverId': friendId,
      'receiverName': friendName.trim().isEmpty ? 'Friend' : friendName.trim(),
      'petName': name,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
      'petId': null,
    });
  }

  Future<String> acceptInvite(PetInvite invite) async {
    final uid = myId;

    if (invite.receiverId != uid) {
      throw StateError('Only the invited friend can accept this invitation.');
    }
    if (!invite.isPending) {
      throw StateError('This invitation is no longer pending.');
    }

    final existingPets = await _pets
        .where('memberIds', arrayContains: uid)
        .get();

    for (final document in existingPets.docs) {
      final members = List<String>.from(
        document.data()['memberIds'] as List? ?? const <String>[],
      );
      if (members.contains(invite.senderId)) {
        throw StateError('You already have a shared pet with this friend.');
      }
    }

    final inviteRef = _invites.doc(invite.id);
    final petRef = _pets.doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(inviteRef);
      if (!snapshot.exists) {
        throw StateError('This invitation no longer exists.');
      }

      final freshInvite = PetInvite.fromDoc(snapshot);
      if (!freshInvite.isPending) {
        throw StateError('This invitation was already answered.');
      }
      if (freshInvite.receiverId != uid) {
        throw StateError('You cannot accept this invitation.');
      }

      transaction.set(petRef, {
        'petName': freshInvite.petName,
        'memberIds': freshInvite.memberIds,
        'memberNames': {
          freshInvite.senderId: freshInvite.senderName,
          freshInvite.receiverId: freshInvite.receiverName,
        },
        'streakDays': 0,
        'level': 1,
        'xp': 0,
        'affection': 40,
        'energy': 80,
        'chatProgress': 0,
        'contributions': {freshInvite.senderId: 20, freshInvite.receiverId: 20},
        'lastInteractionAt': FieldValue.serverTimestamp(),
        'lastDailyClaimDate': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(inviteRef, {
        'status': 'accepted',
        'respondedAt': FieldValue.serverTimestamp(),
        'petId': petRef.id,
      });
    });

    return petRef.id;
  }

  Future<void> rejectInvite(PetInvite invite) async {
    final uid = myId;

    if (invite.receiverId != uid) {
      throw StateError('Only the invited friend can reject this invitation.');
    }

    final reference = _invites.doc(invite.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This invitation no longer exists.');
      }

      final freshInvite = PetInvite.fromDoc(snapshot);
      if (!freshInvite.isPending) {
        throw StateError('This invitation was already answered.');
      }
      if (freshInvite.receiverId != uid) {
        throw StateError('You cannot reject this invitation.');
      }

      transaction.update(reference, {
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
