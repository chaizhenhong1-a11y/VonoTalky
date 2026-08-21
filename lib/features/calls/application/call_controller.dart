import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../chat/data/models/chat_user.dart';
import '../data/models/call_session.dart';
import '../data/services/call_signaling_service.dart';
import '../data/services/webrtc_audio_service.dart';
import '../domain/models/call_status.dart';
import 'call_state.dart';

class CallController extends ChangeNotifier {
  CallController({
    WebRtcAudioService? audioService,
    CallSignalingService? signalingService,
  }) : _audioService = audioService ?? WebRtcAudioService(),
       _signalingService = signalingService ?? CallSignalingService();

  final WebRtcAudioService _audioService;
  final CallSignalingService _signalingService;

  CallState _state = const CallState();
  Timer? _timer;
  DateTime? _connectedAt;
  String? _callId;

  StreamSubscription<CallSession>? _sessionSubscription;
  StreamSubscription<RTCSessionDescription?>? _answerSubscription;
  StreamSubscription<RTCIceCandidate>? _candidateSubscription;
  bool _answerApplied = false;
  bool _disposed = false;

  CallState get state => _state;
  String? get callId => _callId;

  Future<void> startOutgoingCall(ChatUser callee) async {
    if (_state.status != CallStatus.idle) return;

    _setState(_state.copyWith(status: CallStatus.preparing, clearError: true));

    try {
      await _audioService.prepare(
        onIceCandidate: (candidate) {
          final id = _callId;
          if (id == null) return;

          _signalingService.addCallerCandidate(
            callId: id,
            candidate: candidate,
          );
        },
      );

      final offer = await _audioService.createOffer();
      final reference = await _signalingService.createOutgoingCall(
        callee: callee,
        offer: offer,
      );

      _callId = reference.id;
      _listenForRemoteSignaling(reference.id);
      _setState(_state.copyWith(status: CallStatus.ringing));
    } catch (error) {
      final id = _callId;
      if (id != null) {
        try {
          await _signalingService.markFailed(id);
        } catch (_) {
          // Keep the original call error.
        }
      }

      _setState(
        _state.copyWith(
          status: CallStatus.failed,
          errorMessage: 'Call could not be started: $error',
        ),
      );
    }
  }

  void _listenForRemoteSignaling(String callId) {
    _sessionSubscription?.cancel();
    _answerSubscription?.cancel();
    _candidateSubscription?.cancel();

    _sessionSubscription = _signalingService.watchSession(callId).listen((
      session,
    ) {
      if (_disposed) return;
      if (session.status == CallSessionStatus.accepted) {
        if (_state.status != CallStatus.connected) {
          _setState(_state.copyWith(status: CallStatus.connecting));
        }
        return;
      }

      if (session.status == CallSessionStatus.rejected ||
          session.status == CallSessionStatus.ended) {
        if (_state.status != CallStatus.ended) {
          _setState(_state.copyWith(status: CallStatus.ended));
        }
        return;
      }

      if (session.status == CallSessionStatus.failed) {
        _setState(
          _state.copyWith(
            status: CallStatus.failed,
            errorMessage: 'The call could not be connected.',
          ),
        );
      }
    });

    _answerSubscription = _signalingService.watchAnswer(callId).listen((
      answer,
    ) async {
      if (_disposed) return;
      if (answer == null || _answerApplied) return;

      _answerApplied = true;
      await _audioService.applyRemoteAnswer(answer);
      markConnected();
    });

    _candidateSubscription = _signalingService
        .watchCalleeCandidates(callId)
        .listen(_audioService.addRemoteCandidate);
  }

  void markConnected() {
    if (_state.status == CallStatus.ended) return;

    _connectedAt = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final startedAt = _connectedAt;
      if (startedAt == null) return;

      _setState(_state.copyWith(elapsed: DateTime.now().difference(startedAt)));
    });

    _setState(_state.copyWith(status: CallStatus.connected));
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

  Future<void> endCall() async {
    _timer?.cancel();
    _timer = null;

    final id = _callId;
    if (id != null) {
      try {
        await _signalingService.endCall(id);
      } catch (_) {
        // Local media still closes if Firestore is unavailable.
      }
    }

    await _disposeSubscriptions();
    await _audioService.dispose();
    _setState(_state.copyWith(status: CallStatus.ended));
  }

  Future<void> _disposeSubscriptions() async {
    await _sessionSubscription?.cancel();
    await _answerSubscription?.cancel();
    await _candidateSubscription?.cancel();

    _sessionSubscription = null;
    _answerSubscription = null;
    _candidateSubscription = null;
  }

  void _setState(CallState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _disposeSubscriptions();
    _audioService.dispose();
    super.dispose();
  }
}
