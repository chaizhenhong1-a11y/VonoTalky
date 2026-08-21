import 'package:flutter/material.dart';

import '../../application/incoming_call_controller.dart';
import '../../data/models/incoming_call_invite.dart';
import '../../domain/models/call_status.dart';

class IncomingCallPage extends StatefulWidget {
  const IncomingCallPage({
    super.key,
    required this.invite,
    this.autoAccept = false,
  });

  final IncomingCallInvite invite;
  final bool autoAccept;

  @override
  State<IncomingCallPage> createState() => _IncomingCallPageState();
}

class _IncomingCallPageState extends State<IncomingCallPage> {
  late final IncomingCallController _controller;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller = IncomingCallController(callId: widget.invite.id)
      ..addListener(_refresh)
      ..startWatching();

    if (widget.autoAccept) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.accept();
      });
    }
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});

    if (_controller.state.status == CallStatus.ended && !_closing) {
      _closing = true;
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) Navigator.of(context).pop();
      });
    }
  }

  Future<void> _reject() async {
    if (_closing) return;
    _closing = true;
    await _controller.reject();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _hangUp() async {
    if (_closing) return;
    _closing = true;
    await _controller.hangUp();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  String get _statusText {
    final state = _controller.state;
    return switch (state.status) {
      CallStatus.ringing => 'Incoming voice call',
      CallStatus.connecting => 'Connecting…',
      CallStatus.connected =>
        '${state.elapsed.inMinutes.toString().padLeft(2, '0')}:'
            '${(state.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
      CallStatus.failed => state.errorMessage ?? 'Call failed',
      CallStatus.ended => 'Call ended',
      _ => 'Voice call',
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final connected = state.status == CallStatus.connected;
    final photo = widget.invite.callerPhotoUrl;

    return PopScope(
      canPop: state.status == CallStatus.ended,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          connected ? _hangUp() : _reject();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2ECFA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 42, 24, 30),
            child: Column(
              children: [
                const Spacer(),
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.white,
                  backgroundImage: photo == null ? null : NetworkImage(photo),
                  child: photo == null
                      ? Text(
                          widget.invite.callerName.isEmpty
                              ? '?'
                              : widget.invite.callerName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF76579A),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 22),
                Text(
                  widget.invite.callerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF332A3C),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: state.status == CallStatus.failed
                        ? const Color(0xFFB34B5E)
                        : const Color(0xFF746A7C),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (state.status == CallStatus.ringing)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _RoundCallButton(
                        icon: Icons.call_end_rounded,
                        label: 'Decline',
                        backgroundColor: const Color(0xFFE65A68),
                        onTap: _reject,
                      ),
                      _RoundCallButton(
                        icon: Icons.call_rounded,
                        label: 'Accept',
                        backgroundColor: const Color(0xFF65B77A),
                        onTap: _controller.accept,
                      ),
                    ],
                  )
                else ...[
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
                  const SizedBox(height: 32),
                  _RoundCallButton(
                    icon: Icons.call_end_rounded,
                    label: 'End',
                    backgroundColor: const Color(0xFFE65A68),
                    onTap: _hangUp,
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundCallButton extends StatelessWidget {
  const _RoundCallButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 70,
              height: 70,
              child: Icon(icon, color: Colors.white, size: 31),
            ),
          ),
        ),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
