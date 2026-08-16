import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class UploadedVoice {
  const UploadedVoice({required this.url, required this.path});
  final String url;
  final String path;
}

class ChatVoiceService {
  final recorder = AudioRecorder();

  Future<bool> start() async {
    if (!await recorder.hasPermission()) return false;
    final name = 'voice_${DateTime.now().microsecondsSinceEpoch}.wav';
    final path = kIsWeb
        ? name
        : '${(await getTemporaryDirectory()).path}/$name';
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
      path: path,
    );
    return true;
  }

  Future<String?> stop() => recorder.stop();
  Future<void> cancel() => recorder.cancel();

  Future<UploadedVoice> upload({
    required String sourcePath,
    required String roomId,
    required String userId,
    String root = 'chat_media',
  }) async {
    final bytes = await XFile(sourcePath).readAsBytes();
    final path =
        '$root/$roomId/$userId/${DateTime.now().microsecondsSinceEpoch}.wav';
    final ref = FirebaseStorage.instance.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'audio/wav'));
    return UploadedVoice(url: await ref.getDownloadURL(), path: path);
  }

  void dispose() => recorder.dispose();
}
