import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaTransferService {
  Future<void> downloadAndOpen({
    required String url,
    required String name,
    required void Function(double progress) onProgress,
  }) async {
    onProgress(.2);
    final opened = await launchUrl(Uri.parse(url));
    if (!opened) throw StateError('Unable to open download.');
    onProgress(1);
  }

  Future<void> share({required String url, required String name}) async {
    await SharePlus.instance.share(
      ShareParams(text: '$name\n$url', title: name),
    );
  }
}
