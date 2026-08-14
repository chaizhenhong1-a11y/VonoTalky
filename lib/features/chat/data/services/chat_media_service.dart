import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UploadedChatImage {
  const UploadedChatImage({required this.url, required this.storagePath});
  final String url;
  final String storagePath;
}

class ChatMediaService {
  final _picker = ImagePicker();
  final _storage = FirebaseStorage.instance;

  Future<XFile?> pick(ImageSource source) => _picker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1920,
      );

  Future<UploadedChatImage> upload({
    required XFile file,
    required String roomId,
    required String userId,
    String root = 'chat_media',
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      throw Exception('Image must be smaller than 10 MB.');
    }
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final path =
        '$root/$roomId/$userId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: file.mimeType ?? 'image/jpeg'),
    );
    return UploadedChatImage(
      url: await ref.getDownloadURL(),
      storagePath: path,
    );
  }
}
