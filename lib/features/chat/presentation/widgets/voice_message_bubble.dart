import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class VoiceMessageBubble extends StatefulWidget {
  const VoiceMessageBubble({
    super.key,
    required this.url,
    required this.durationMs,
    required this.mine,
  });
  final String url;
  final int durationMs;
  final bool mine;

  @override
  State<VoiceMessageBubble> createState() => _VoiceMessageBubbleState();
}

class _VoiceMessageBubbleState extends State<VoiceMessageBubble> {
  final player = AudioPlayer();
  bool loaded = false;

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> toggle() async {
    if (player.playing) {
      await player.pause();
    } else {
      if (player.processingState == ProcessingState.completed) {
        await player.seek(Duration.zero);
      }
      if (!loaded) {
        await player.setUrl(widget.url);
        loaded = true;
      }
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Duration>(
    stream: player.positionStream,
    builder: (_, snapshot) {
      final position = snapshot.data ?? Duration.zero;
      final total =
          player.duration ??
          Duration(milliseconds: widget.durationMs.clamp(1, 3600000).toInt());
      final progress = total.inMilliseconds == 0
          ? 0.0
          : (position.inMilliseconds / total.inMilliseconds)
                .clamp(0.0, 1.0)
                .toDouble();
      return SizedBox(
        width: 220,
        child: Row(
          children: [
            StreamBuilder<bool>(
              stream: player.playingStream,
              builder: (_, playing) => IconButton(
                onPressed: toggle,
                color: widget.mine ? const Color(0xFF65439B) : null,
                icon: Icon(
                  playing.data == true
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
              ),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: progress,
                color: widget.mine ? const Color(0xFF7150A1) : null,
                backgroundColor: widget.mine ? const Color(0x337150A1) : null,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${total.inSeconds}s',
              style: TextStyle(
                fontSize: 11,
                color: widget.mine ? const Color(0xFF716A78) : null,
              ),
            ),
          ],
        ),
      );
    },
  );
}
