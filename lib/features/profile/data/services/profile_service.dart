import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ProfileService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  String get uid => _auth.currentUser!.uid;

  Stream<DocumentSnapshot<Map<String, dynamic>>> profile() =>
      _db.collection('users').doc(uid).snapshots();

  Stream<int> conversationCount() => _db
      .collection('conversations')
      .where('memberIds', arrayContains: uid)
      .snapshots()
      .map((event) => event.docs.length);

  Future<AvatarUploadResult?> pickAndUploadAvatar() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1200,
    );
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    if (bytes.length > 8 * 1024 * 1024) {
      throw Exception('Avatar is too large.');
    }
    final contentType = _contentType(file);
    final extension = _extension(contentType);
    final ref = _storage.ref('avatars/$uid/profile.$extension');
    await ref.putData(bytes, SettableMetadata(contentType: contentType));
    final downloadUrl = await ref.getDownloadURL();
    final separator = downloadUrl.contains('?') ? '&' : '?';
    final url =
        '$downloadUrl${separator}v=${DateTime.now().millisecondsSinceEpoch}';
    await _auth.currentUser!.updatePhotoURL(url);
    await _db.collection('users').doc(uid).update({
      'photoUrl': url,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return AvatarUploadResult(url: url, bytes: bytes);
  }

  String _contentType(XFile file) {
    final reported = file.mimeType;
    if (reported != null && reported.startsWith('image/')) return reported;
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.heic') || path.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }

  String _extension(String contentType) => switch (contentType) {
    'image/png' => 'png',
    'image/webp' => 'webp',
    'image/gif' => 'gif',
    'image/heic' || 'image/heif' => 'heic',
    _ => 'jpg',
  };

  Future<void> update({
    required String displayName,
    required String bio,
    required String phone,
    required String birthDate,
  }) async {
    await _auth.currentUser!.updateDisplayName(displayName.trim());
    await _db.collection('users').doc(uid).update({
      'displayName': displayName.trim(),
      'displayNameLower': displayName.trim().toLowerCase(),
      'bio': bio.trim(),
      'phone': phone.trim(),
      'birthDate': birthDate.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

class AvatarUploadResult {
  const AvatarUploadResult({required this.url, required this.bytes});
  final String url;
  final Uint8List bytes;
}
