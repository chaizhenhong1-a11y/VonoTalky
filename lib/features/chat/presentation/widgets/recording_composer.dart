import 'package:flutter/material.dart';

class RecordingComposer extends StatelessWidget {
  const RecordingComposer({
    super.key,
    required this.seconds,
    required this.uploading,
    required this.onCancel,
    required this.onSend,
  });

  final int seconds;
  final bool uploading;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remainingSeconds = (seconds % 60).toString().padLeft(2, '0');
    return Row(
      children: [
        const SizedBox(width: 8),
        const Icon(Icons.graphic_eq_rounded, color: Color(0xFFE34B62)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            'Recording  $minutes:$remainingSeconds',
            style: const TextStyle(
              color: Color(0xFF5E5665),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextButton(
          onPressed: uploading ? null : onCancel,
          child: const Text('Cancel', style: TextStyle(color: Color(0xFFE34B62))),
        ),
        IconButton.filled(
          style: IconButton.styleFrom(backgroundColor: const Color(0xFFB49ADF)),
          onPressed: uploading ? null : onSend,
          icon: uploading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded, size: 19),
        ),
      ],
    );
  }
}
