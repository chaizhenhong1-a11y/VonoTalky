import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/services/media_transfer_service.dart';

class MediaViewerPage extends StatefulWidget {
  const MediaViewerPage({
    super.key,
    required this.url,
    this.name = 'VonoTalky image.jpg',
  });

  final String url;
  final String name;

  @override
  State<MediaViewerPage> createState() => _MediaViewerPageState();
}

class _MediaViewerPageState extends State<MediaViewerPage> {
  final transfer = MediaTransferService();
  final viewerController = TransformationController();
  var retry = 0;
  double? progress;

  @override
  void dispose() {
    viewerController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    viewerController.value = Matrix4.identity();
    _notice('Zoom reset');
  }

  Future<void> _download() async {
    if (progress != null) return;
    setState(() => progress = 0);
    try {
      await transfer.downloadAndOpen(
        url: widget.url,
        name: widget.name,
        onProgress: (value) {
          if (mounted) setState(() => progress = value);
        },
      );
      if (mounted) _notice('Saved and opened');
    } catch (_) {
      if (mounted) _notice('Download failed. Please try again.');
    } finally {
      if (mounted) setState(() => progress = null);
    }
  }

  Future<void> _share() async {
    try {
      await transfer.share(url: widget.url, name: widget.name);
    } catch (_) {
      if (mounted) _notice('Unable to share this image');
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: widget.url));
    if (mounted) _notice('Image link copied');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        tooltip: 'Close image',
        icon: const Icon(Icons.close_rounded),
      ),
      title: Text(widget.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          onPressed: _resetZoom,
          tooltip: 'Reset zoom',
          icon: const Icon(Icons.center_focus_weak_rounded),
        ),
        IconButton(
          onPressed: _copyLink,
          tooltip: 'Copy image link',
          icon: const Icon(Icons.link_rounded),
        ),
        IconButton(
          onPressed: _share,
          tooltip: 'Share image',
          icon: const Icon(Icons.share_outlined),
        ),
        IconButton(
          onPressed: progress == null ? _download : null,
          tooltip: progress == null ? 'Download image' : 'Downloading',
          icon: progress == null
              ? const Icon(Icons.download_rounded)
              : const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
        ),
      ],
      bottom: progress == null
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: LinearProgressIndicator(
                value: progress == 0 ? null : progress,
              ),
            ),
    ),
    body: Center(
      child: InteractiveViewer(
        transformationController: viewerController,
        minScale: .8,
        maxScale: 5,
        boundaryMargin: const EdgeInsets.all(80),
        child: Image.network(
          widget.url,
          key: ValueKey(retry),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loading) => loading == null
              ? child
              : const SizedBox(
                  width: 34,
                  height: 34,
                  child: CircularProgressIndicator(color: Color(0xFFB49ADF)),
                ),
          errorBuilder: (_, _, _) =>
              _LoadFailure(onRetry: () => setState(() => retry++)),
        ),
      ),
    ),
  );

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.broken_image_outlined, color: Colors.white70, size: 52),
      const SizedBox(height: 10),
      const Text(
        'Unable to load image',
        style: TextStyle(color: Colors.white70),
      ),
      TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry'),
      ),
    ],
  );
}
