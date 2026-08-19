import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shared_pet.dart';
import '../models/shared_pet_memory.dart';
import '../models/pet_care_request.dart';

class SharedPetService {
  static const int minimumPlayEnergy = 8;

  SharedPetService({FirebaseFirestore? firestore, FirebaseAuth? auth})
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

  CollectionReference<Map<String, dynamic>> get _pets =>
      _firestore.collection('sharedPets');

  Stream<List<SharedPet>> watchMyPets() {
    final uid = myId;

    return _pets.where('memberIds', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      final pets = snapshot.docs.map(SharedPet.fromDoc).toList();
      pets.sort((a, b) {
        final streak = b.streakDays.compareTo(a.streakDays);
        if (streak != 0) return streak;
        return b.level.compareTo(a.level);
      });
      return pets;
    });
  }

  Stream<SharedPet?> watchPet(String petId) {
    return _pets
        .doc(petId)
        .snapshots()
        .map(
          (document) => document.exists ? SharedPet.fromDoc(document) : null,
        );
  }

  Future<String> createSharedPet({
    required String friendId,
    required String friendName,
    required String petName,
  }) async {
    final me = currentUser;
    final normalizedName = petName.trim().isEmpty ? 'Vono Pet' : petName.trim();

    final existing = await _pets
        .where('memberIds', arrayContains: me.uid)
        .get();

    for (final document in existing.docs) {
      final data = document.data();
      final members = List<String>.from(
        data['memberIds'] as List? ?? const <String>[],
      );
      if (members.contains(friendId)) {
        throw StateError('You already have a shared pet with this friend.');
      }
    }

    final document = _pets.doc();
    await document.set({
      'petName': normalizedName,
      'memberIds': [me.uid, friendId],
      'memberNames': {
        me.uid: me.displayName?.trim().isNotEmpty == true
            ? me.displayName!.trim()
            : (me.email ?? 'You'),
        friendId: friendName.trim().isEmpty ? 'Friend' : friendName.trim(),
      },
      'streakDays': 0,
      'level': 1,
      'xp': 0,
      'affection': 40,
      'energy': 80,
      'chatProgress': 0,
      'contributions': {me.uid: 20, friendId: 20},
      'lastInteractionAt': FieldValue.serverTimestamp(),
      'lastDailyClaimDate': null,
      'claimedStreakMilestones': <int>[],
      'petTheme': 'rose',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<SharedPet?> watchSharedPetWith(String friendId) {
    final uid = myId;

    return _pets.where('memberIds', arrayContains: uid).snapshots().map((
      snapshot,
    ) {
      for (final document in snapshot.docs) {
        final pet = SharedPet.fromDoc(document);
        if (pet.memberIds.contains(friendId)) {
          return pet;
        }
      }
      return null;
    });
  }

  Stream<int> watchIncomingCareRequestCount(String petId) {
    final uid = myId;
    return watchPendingCareRequests(petId).map(
      (items) => items.where((request) => request.receiverId == uid).length,
    );
  }

  Stream<List<PetCareRequest>> watchPendingCareRequests(String petId) {
    return _pets
        .doc(petId)
        .collection('careRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final items = snapshot.docs.map(PetCareRequest.fromDoc).toList();
          items.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return items;
        });
  }

  Future<void> sendCareRequest(
    String petId, {
    required String receiverId,
    required String type,
  }) async {
    const allowedTypes = {'feed', 'play', 'pet'};
    if (!allowedTypes.contains(type)) {
      throw StateError('Unsupported care request.');
    }

    final uid = myId;
    if (receiverId == uid) {
      throw StateError('You cannot send a care request to yourself.');
    }

    final petRef = _pets.doc(petId);
    final petSnapshot = await petRef.get();
    if (!petSnapshot.exists) {
      throw StateError('This shared pet no longer exists.');
    }

    final pet = SharedPet.fromDoc(petSnapshot);
    if (!pet.memberIds.contains(uid) || !pet.memberIds.contains(receiverId)) {
      throw StateError('Both users must belong to this shared pet.');
    }

    final pending = await petRef
        .collection('careRequests')
        .where('status', isEqualTo: 'pending')
        .get();

    for (final document in pending.docs) {
      final request = PetCareRequest.fromDoc(document);
      if (request.senderId == uid &&
          request.receiverId == receiverId &&
          request.type == type) {
        throw StateError('This care request is already pending.');
      }
    }

    await petRef.collection('careRequests').add({
      'type': type,
      'senderId': uid,
      'receiverId': receiverId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });

    final actionLabel = switch (type) {
      'feed' => 'feed',
      'play' => 'play with',
      _ => 'give some love to',
    };

    await _addMemory(
      petId,
      type: 'careRequest',
      title: 'Care request sent',
      subtitle: 'Asked your friend to $actionLabel ${pet.petName}.',
    );
  }

  Future<void> completeCareRequest(String petId, PetCareRequest request) async {
    final uid = myId;
    if (request.receiverId != uid) {
      throw StateError('Only the requested friend can complete this.');
    }

    final requestRef = _pets
        .doc(petId)
        .collection('careRequests')
        .doc(request.id);

    final action = switch (request.type) {
      'feed' => SharedPetAction.feed,
      'play' => SharedPetAction.play,
      _ => SharedPetAction.pet,
    };

    await performAction(petId, action);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestRef);
      if (!snapshot.exists) return;

      final fresh = PetCareRequest.fromDoc(snapshot);
      if (!fresh.isPending || fresh.receiverId != uid) return;

      transaction.update(requestRef, {
        'status': 'completed',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });

    await _addMemory(
      petId,
      type: 'careCompleted',
      title: 'Care request completed',
      subtitle: 'A shared-pet care request was completed.',
    );
  }

  Future<void> dismissCareRequest(String petId, PetCareRequest request) async {
    final uid = myId;
    if (request.receiverId != uid) {
      throw StateError('Only the requested friend can dismiss this.');
    }

    final reference = _pets
        .doc(petId)
        .collection('careRequests')
        .doc(request.id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) return;

      final fresh = PetCareRequest.fromDoc(snapshot);
      if (!fresh.isPending || fresh.receiverId != uid) return;

      transaction.update(reference, {
        'status': 'dismissed',
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<SharedPetMemory>> watchMemories(String petId) {
    return _pets
        .doc(petId)
        .collection('memories')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(SharedPetMemory.fromDoc).toList());
  }

  Future<void> setPetSpecies(String petId, String species) async {
    const allowed = {'flame', 'mochi', 'cloud', 'star'};
    if (!allowed.contains(species)) {
      throw StateError('Unsupported pet species.');
    }

    final uid = myId;
    final reference = _pets.doc(petId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This shared pet no longer exists.');
      }

      final pet = SharedPet.fromDoc(snapshot);
      if (!pet.memberIds.contains(uid)) {
        throw StateError('You do not have access to this shared pet.');
      }

      transaction.update(reference, {
        'petSpecies': species,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _addMemory(
      petId,
      type: 'species',
      title: 'New pet form',
      subtitle: 'Your shared pet changed into a new species.',
    );
  }

  Future<void> _addMemory(
    String petId, {
    required String type,
    required String title,
    required String subtitle,
  }) async {
    await _pets.doc(petId).collection('memories').add({
      'type': type,
      'title': title,
      'subtitle': subtitle,
      'actorId': myId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> renamePet(String petId, String name) async {
    final normalized = name.trim();
    if (normalized.isEmpty) {
      throw StateError('Pet name cannot be empty.');
    }
    if (normalized.length > 24) {
      throw StateError('Pet name must be 24 characters or fewer.');
    }

    final uid = myId;
    final reference = _pets.doc(petId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This shared pet no longer exists.');
      }

      final pet = SharedPet.fromDoc(snapshot);
      if (!pet.memberIds.contains(uid)) {
        throw StateError('You do not have access to this shared pet.');
      }

      transaction.update(reference, {
        'petName': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _addMemory(
      petId,
      type: 'rename',
      title: 'Pet renamed',
      subtitle: 'Your shared pet is now called $normalized.',
    );
  }

  Future<void> setPetTheme(String petId, String theme) async {
    const allowed = {'rose', 'violet', 'sunset', 'ocean'};
    if (!allowed.contains(theme)) {
      throw StateError('Unsupported pet theme.');
    }

    final uid = myId;
    final reference = _pets.doc(petId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This shared pet no longer exists.');
      }

      final pet = SharedPet.fromDoc(snapshot);
      if (!pet.memberIds.contains(uid)) {
        throw StateError('You do not have access to this shared pet.');
      }

      transaction.update(reference, {
        'petTheme': theme,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _addMemory(
      petId,
      type: 'theme',
      title: 'New pet style',
      subtitle: 'The shared pet theme changed to $theme.',
    );
  }

  Future<void> claimStreakMilestone(String petId, int milestone) async {
    const allowed = <int>{3, 7, 14, 30};
    if (!allowed.contains(milestone)) {
      throw StateError('Unsupported streak milestone.');
    }

    final uid = myId;
    final reference = _pets.doc(petId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This shared pet no longer exists.');
      }

      final pet = SharedPet.fromDoc(snapshot);
      if (!pet.memberIds.contains(uid)) {
        throw StateError('You do not have access to this shared pet.');
      }
      if (pet.streakDays < milestone) {
        throw StateError('This streak reward is not unlocked yet.');
      }
      if (pet.claimedStreakMilestones.contains(milestone)) {
        throw StateError('This streak reward has already been claimed.');
      }

      final reward = switch (milestone) {
        3 => (xp: 30, affection: 15, contribution: 10),
        7 => (xp: 70, affection: 30, contribution: 20),
        14 => (xp: 140, affection: 50, contribution: 35),
        30 => (xp: 300, affection: 100, contribution: 70),
        _ => (xp: 0, affection: 0, contribution: 0),
      };

      var xp = pet.xp + reward.xp;
      var level = pet.level;

      while (xp >= 600) {
        xp -= 600;
        level += 1;
      }

      final contributions = Map<String, int>.from(pet.contributions);
      contributions[uid] = (contributions[uid] ?? 0) + reward.contribution;

      final claimed = List<int>.from(pet.claimedStreakMilestones)
        ..add(milestone)
        ..sort();

      transaction.update(reference, {
        'xp': xp,
        'level': level,
        'affection': (pet.affection + reward.affection).clamp(0, 500),
        'contributions': contributions,
        'claimedStreakMilestones': claimed,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    await _addMemory(
      petId,
      type: 'streak',
      title: '$milestone day streak',
      subtitle: 'A friendship streak reward was claimed.',
    );
  }

  Future<void> performAction(String petId, SharedPetAction action) async {
    final uid = myId;
    final reference = _pets.doc(petId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) {
        throw StateError('This shared pet no longer exists.');
      }

      final pet = SharedPet.fromDoc(snapshot);
      if (!pet.memberIds.contains(uid)) {
        throw StateError('You do not have access to this shared pet.');
      }

      var affection = pet.affection;
      var energy = pet.energy;
      var xp = pet.xp;
      var level = pet.level;
      var contributionGain = 0;

      switch (action) {
        case SharedPetAction.feed:
          energy = (energy + 7).clamp(0, 100);
          affection = (affection + 3).clamp(0, 500);
          xp += 5;
          contributionGain = 3;
        case SharedPetAction.play:
          if (energy < minimumPlayEnergy) {
            throw StateError(
              'Your pet is too tired to play. Feed your pet first to restore energy.',
            );
          }
          energy = (energy - 7).clamp(0, 100);
          affection = (affection + 8).clamp(0, 500);
          xp += 10;
          contributionGain = 8;
        case SharedPetAction.pet:
          affection = (affection + 5).clamp(0, 500);
          xp += 3;
          contributionGain = 5;
        case SharedPetAction.dailyReward:
          final today = _dateKey(DateTime.now());
          if (pet.lastDailyClaimDate == today) {
            throw StateError('Today\'s bond reward is already claimed.');
          }
          affection = (affection + 15).clamp(0, 500);
          energy = (energy + 10).clamp(0, 100);
          xp += 20;
          contributionGain = 15;
      }

      while (xp >= 600) {
        xp -= 600;
        level += 1;
      }

      final contributions = Map<String, int>.from(pet.contributions);
      contributions[uid] = (contributions[uid] ?? 0) + contributionGain;

      final update = <String, dynamic>{
        'affection': affection,
        'energy': energy,
        'xp': xp,
        'level': level,
        'contributions': contributions,
        'lastInteractionAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (action == SharedPetAction.dailyReward) {
        update['lastDailyClaimDate'] = _dateKey(DateTime.now());
      }

      transaction.update(reference, update);
    });

    if (action == SharedPetAction.dailyReward) {
      await _addMemory(
        petId,
        type: 'reward',
        title: 'Daily bond reward',
        subtitle: 'Today\'s shared-pet reward was claimed.',
      );
    }
  }

  static String _dateKey(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static bool claimedToday(SharedPet pet) {
    return pet.lastDailyClaimDate == _dateKey(DateTime.now());
  }
}

enum SharedPetAction { feed, play, pet, dailyReward }
