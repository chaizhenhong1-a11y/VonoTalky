import 'package:flutter/material.dart';

import '../../../chat/data/models/chat_user.dart';
import '../../application/call_controller.dart';
import '../../domain/models/call_status.dart';

class AudioCallPage extends StatefulWidget {
  const AudioCallPage({super.key, required this.user});

  final ChatUser user;

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  late final CallController _controller;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = CallController()..addListener(_refresh);
    _controller.startOutgoingCall(widget.user);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});

    if (_controller.state.status == CallStatus.ended && !_closing) {
      _closing = true;
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _hangUp() async {
    if (_closing) return;
    _closing = true;

    await _controller.endCall();
    if (mounted) Navigator.of(context).pop();
  }

  String get _statusText {
    final state = _controller.state;

    switch (state.status) {
      case CallStatus.idle:
        return 'Ready';
      case CallStatus.preparing:
        return 'Preparing call…';
      case CallStatus.ringing:
        return 'Calling…';
      case CallStatus.connecting:
        return 'Connecting…';
      case CallStatus.connected:
        final minutes = state.elapsed.inMinutes.toString().padLeft(2, '0');
        final seconds = (state.elapsed.inSeconds % 60).toString().padLeft(
          2,
          '0',
        );
        return '$minutes:$seconds';
      case CallStatus.ended:
        return 'Call ended';
      case CallStatus.failed:
        return state.errorMessage ?? 'Call failed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final photoUrl = widget.user.photoUrl;

    return PopScope(
      canPop: state.status == CallStatus.ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _hangUp();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2ECFA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
            child: Column(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 58,
                  backgroundColor: Colors.white,
                  backgroundImage: photoUrl == null
                      ? null
                      : NetworkImage(photoUrl),
                  child: photoUrl == null
                      ? Text(
                          widget.user.name.isEmpty
                              ? '?'
                              : widget.user.name[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF76579A),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 22),
                Text(
                  widget.user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF332A3C),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: state.status == CallStatus.failed ? 13 : 15,
                    fontWeight: FontWeight.w600,
                    color: state.status == CallStatus.failed
                        ? const Color(0xFFB34B5E)
                        : const Color(0xFF746A7C),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _CallAction(
                      icon: state.muted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      label: state.muted ? 'Unmute' : 'Mute',
                      active: state.muted,
                      onTap: _controller.toggleMute,
                    ),
                    _CallAction(
                      icon: state.speakerEnabled
                          ? Icons.volume_up_rounded
                          : Icons.hearing_rounded,
                      label: 'Speaker',
                      active: state.speakerEnabled,
                      onTap: _controller.toggleSpeaker,
                    ),
                  ],
                ),
                const SizedBox(height: 34),
                Semantics(
                  button: true,
                  label: 'End call',
                  child: InkWell(
                    onTap: _hangUp,
                    customBorder: const CircleBorder(),
                    child: const CircleAvatar(
                      radius: 34,
                      backgroundColor: Color(0xFFE65A68),
                      child: Icon(
                        Icons.call_end_rounded,
                        size: 31,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallAction extends StatelessWidget {
  const _CallAction({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: active ? const Color(0xFFD8C7EF) : Colors.white,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 64,
              height: 64,
              child: Icon(icon, color: const Color(0xFF654A84), size: 27),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF62596A),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
