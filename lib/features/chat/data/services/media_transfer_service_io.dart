import 'dart:io';

import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class MediaTransferService {
  final Dio _dio = Dio();

  Future<void> downloadAndOpen({
    required String url,
    required String name,
    required void Function(double progress) onProgress,
  }) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/VonoTalky');
    await directory.create(recursive: true);
    final safeName = _safeName(name);
    final path = '${directory.path}/$safeName';
    await _dio.download(
      url,
      path,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress(received / total);
      },
    );
    onProgress(1);
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done) {
      throw StateError(result.message);
    }
  }

  Future<void> share({required String url, required String name}) async {
    await SharePlus.instance.share(
      ShareParams(text: '$name\n$url', title: name),
    );
  }

  String _safeName(String name) {
    final value = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return value.isEmpty
        ? 'download_${DateTime.now().millisecondsSinceEpoch}'
        : value;
  }
}
