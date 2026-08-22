import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../chat/data/models/chat_user.dart';
import 'contact_service.dart';

enum ContactQrRelationship { available, pending, contact, rejected }

class ContactQrLookup {
  const ContactQrLookup({
    required this.user,
    required this.relationship,
    required this.username,
    required this.bio,
  });

  final ChatUser user;
  final ContactQrRelationship relationship;
  final String username;
  final String bio;
}

class ContactQrService {
  ContactQrService({
    ContactService? contactService,
    FirebaseFirestore? firestore,
  }) : _contactService = contactService ?? ContactService(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  final ContactService _contactService;
  final FirebaseFirestore _firestore;

  String get myId => _contactService.myId;

  String? parseUserId(String rawValue) {
    final value = rawValue.trim();
    if (value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri == null ||
        uri.scheme.toLowerCase() != 'vonotalky' ||
        uri.host.toLowerCase() != 'user' ||
        uri.pathSegments.length != 1) {
      return null;
    }

    final uid = uri.pathSegments.single.trim();
    return uid.isEmpty ? null : uid;
  }

  Future<ContactQrLookup?> lookup(String rawValue) async {
    final uid = parseUserId(rawValue);
    if (uid == null) return null;

    final document = await _firestore.collection('users').doc(uid).get();
    if (!document.exists) return null;

    final user = ChatUser.fromDoc(document);
    final data = document.data() ?? const <String, dynamic>{};
    final username = (data['username'] as String? ?? '').trim();
    final bio = (data['bio'] as String? ?? '').trim();

    if (uid == myId) {
      return ContactQrLookup(
        user: user,
        relationship: ContactQrRelationship.contact,
        username: username,
        bio: bio,
      );
    }

    final status = await _contactService.requestStatus(uid).first;

    final relationship = switch (status) {
      'pending' => ContactQrRelationship.pending,
      'accepted' => ContactQrRelationship.contact,
      'rejected' => ContactQrRelationship.rejected,
      _ => ContactQrRelationship.available,
    };

    return ContactQrLookup(
      user: user,
      relationship: relationship,
      username: username,
      bio: bio,
    );
  }

  Future<void> sendRequest(String uid) => _contactService.sendRequest(uid);
}
