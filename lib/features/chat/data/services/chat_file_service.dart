import 'package:file_selector/file_selector.dart';
import 'package:firebase_storage/firebase_storage.dart';

class PickedChatFile {
  const PickedChatFile({required this.file, required this.name, required this.size, required this.extension});
  final XFile file;
  final String name;
  final int size;
  final String extension;
}

class UploadedChatFile {
  const UploadedChatFile({required this.url, required this.path, required this.name, required this.size, required this.extension});
  final String url;
  final String path;
  final String name;
  final int size;
  final String extension;
}

class ChatFileService {
  static const allowed = ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip'];
  static const fileTypes = XTypeGroup(label: 'Documents', extensions: allowed);

  Future<PickedChatFile?> pick() async {
    final file = await openFile(acceptedTypeGroups: const [fileTypes]);
    if (file == null) return null;
    final size = await file.length();
    final extension = _extension(file.name);
    if (!allowed.contains(extension)) throw Exception('This file type is not supported.');
    if (size > 25 * 1024 * 1024) throw Exception('File is over 25 MB.');
    return PickedChatFile(file: file, name: file.name, size: size, extension: extension);
  }

  Future<UploadedChatFile> upload({
    required PickedChatFile file,
    required String roomId,
    required String userId,
    String root = 'chat_media',
  }) async {
    final bytes = await file.file.readAsBytes();
    if (bytes.length > 25 * 1024 * 1024) throw Exception('File is over 25 MB.');
    final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_').toLowerCase();
    final path = '$root/$roomId/$userId/${DateTime.now().microsecondsSinceEpoch}_$safeName';
    final reference = FirebaseStorage.instance.ref(path);
    await reference.putData(bytes, SettableMetadata(contentType: _contentType(file.extension)));
    return UploadedChatFile(
      url: await reference.getDownloadURL(),
      path: path,
      name: file.name,
      size: file.size,
      extension: file.extension,
    );
  }

  static String _extension(String name) {
    final index = name.lastIndexOf('.');
    return index < 0 ? '' : name.substring(index + 1).toLowerCase();
  }

  static String _contentType(String extension) => switch (extension) {
        'pdf' => 'application/pdf',
        'txt' => 'text/plain',
        'zip' => 'application/zip',
        'doc' || 'docx' => 'application/msword',
        'xls' || 'xlsx' => 'application/vnd.ms-excel',
        'ppt' || 'pptx' => 'application/vnd.ms-powerpoint',
        _ => 'application/octet-stream',
      };
}
