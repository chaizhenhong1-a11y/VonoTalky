import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/services/media_transfer_service.dart';

class FileMessageBubble extends StatefulWidget {
  const FileMessageBubble({super.key, required this.name, required this.url, required this.size, required this.mine});
  final String name;
  final String url;
  final int size;
  final bool mine;

  @override
  State<FileMessageBubble> createState() => _FileMessageBubbleState();
}

class _FileMessageBubbleState extends State<FileMessageBubble> {
  final transfer = MediaTransferService();
  double? progress;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: _showActions,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 240,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.insert_drive_file_rounded, size: 34, color: widget.mine ? const Color(0xFF65439B) : null),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: widget.mine ? const Color(0xFF30263D) : null, fontWeight: FontWeight.w600)),
                  Text(_size(widget.size), style: TextStyle(fontSize: 11, color: widget.mine ? const Color(0xFF716A78) : Colors.grey)),
                ]),
              ),
              Icon(Icons.more_horiz_rounded, size: 19, color: widget.mine ? const Color(0xFF7150A1) : null),
            ]),
            if (progress != null) ...[
              const SizedBox(height: 7),
              LinearProgressIndicator(value: progress == 0 ? null : progress, minHeight: 3, color: const Color(0xFFB49ADF), backgroundColor: const Color(0x22000000)),
            ],
          ]),
        ),
      );

  Future<void> _showActions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.open_in_new_rounded), title: const Text('Open online'), onTap: () => Navigator.pop(context, 'open')),
          ListTile(leading: const Icon(Icons.download_rounded), title: const Text('Download and open'), onTap: () => Navigator.pop(context, 'download')),
          ListTile(leading: const Icon(Icons.share_outlined), title: const Text('Share'), onTap: () => Navigator.pop(context, 'share')),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'open') {
      final opened = await launchUrl(Uri.parse(widget.url), mode: LaunchMode.externalApplication);
      if (!opened && mounted) _notice('Unable to open file');
    } else if (action == 'download') {
      await _download();
    } else if (action == 'share') {
      try {
        await transfer.share(url: widget.url, name: widget.name);
      } catch (_) {
        if (mounted) _notice('Unable to share file');
      }
    }
  }

  Future<void> _download() async {
    if (progress != null) return;
    setState(() => progress = 0);
    try {
      await transfer.downloadAndOpen(
        url: widget.url,
        name: widget.name,
        onProgress: (value) { if (mounted) setState(() => progress = value); },
      );
      if (mounted) _notice('Download completed');
    } catch (_) {
      if (mounted) _notice('Download failed. Tap the file to retry.');
    } finally {
      if (mounted) setState(() => progress = null);
    }
  }

  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _size(int bytes) {
    if (bytes >= 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    if (bytes >= 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '$bytes B';
  }
}
