import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../data/models/call_session.dart';
import '../data/services/call_signaling_service.dart';
import '../data/services/webrtc_audio_service.dart';
import '../domain/models/call_status.dart';
import 'call_state.dart';

class IncomingCallController extends ChangeNotifier {
  IncomingCallController({
    required this.callId,
    CallSignalingService? signalingService,
    WebRtcAudioService? audioService,
  }) : _signalingService = signalingService ?? CallSignalingService(),
       _audioService = audioService ?? WebRtcAudioService();

  final String callId;
  final CallSignalingService _signalingService;
  final WebRtcAudioService _audioService;

  CallState _state = const CallState(status: CallStatus.ringing);
  StreamSubscription<CallSession>? _sessionSubscription;
  StreamSubscription<RTCIceCandidate>? _candidateSubscription;
  Timer? _timer;
  DateTime? _connectedAt;

  CallState get state => _state;

  void startWatching() {
    _sessionSubscription ??= _signalingService.watchSession(callId).listen((
      session,
    ) {
      if (session.status == CallSessionStatus.ended ||
          session.status == CallSessionStatus.rejected) {
        _setState(_state.copyWith(status: CallStatus.ended));
      } else if (session.status == CallSessionStatus.failed) {
        _setState(
          _state.copyWith(
            status: CallStatus.failed,
            errorMessage: 'The caller ended this call.',
          ),
        );
      }
    });
  }

  Future<void> accept() async {
    if (_state.status != CallStatus.ringing) return;

    _setState(_state.copyWith(status: CallStatus.connecting, clearError: true));

    try {
      await _audioService.prepare(
        onIceCandidate: (candidate) {
          _signalingService.addCalleeCandidate(
            callId: callId,
            candidate: candidate,
          );
        },
      );

      final offer = await _signalingService.readOffer(callId);
      await _audioService.applyRemoteOffer(offer);

      _candidateSubscription = _signalingService
          .watchCallerCandidates(callId)
          .listen(_audioService.addRemoteCandidate);

      final answer = await _audioService.createAnswer();
      await _signalingService.acceptCall(callId: callId, answer: answer);

      _markConnected();
    } catch (error) {
      try {
        await _signalingService.markFailed(callId);
      } catch (_) {}
      _setState(
        _state.copyWith(
          status: CallStatus.failed,
          errorMessage: 'Could not answer call: $error',
        ),
      );
    }
  }

  Future<void> reject() async {
    await _signalingService.rejectCall(callId);
    await _closeMedia();
    _setState(_state.copyWith(status: CallStatus.ended));
  }

  Future<void> hangUp() async {
    try {
      await _signalingService.endCall(callId);
    } catch (_) {}
    await _closeMedia();
    _setState(_state.copyWith(status: CallStatus.ended));
  }

  Future<void> toggleMute() async {
    final next = !_state.muted;
    await _audioService.setMuted(next);
    _setState(_state.copyWith(muted: next));
  }

  Future<void> toggleSpeaker() async {
    final next = !_state.speakerEnabled;
    await _audioService.setSpeakerEnabled(next);
    _setState(_state.copyWith(speakerEnabled: next));
  }

  void _markConnected() {
    _connectedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final start = _connectedAt;
      if (start == null) return;
      _setState(_state.copyWith(elapsed: DateTime.now().difference(start)));
    });
    _setState(_state.copyWith(status: CallStatus.connected));
  }

  Future<void> _closeMedia() async {
    _timer?.cancel();
    _timer = null;
    await _candidateSubscription?.cancel();
    _candidateSubscription = null;
    await _audioService.dispose();
  }

  void _setState(CallState next) {
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sessionSubscription?.cancel();
    _candidateSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
