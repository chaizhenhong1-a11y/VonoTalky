import '../domain/models/call_status.dart';

class CallState {
  const CallState({
    this.status = CallStatus.idle,
    this.muted = false,
    this.speakerEnabled = false,
    this.elapsed = Duration.zero,
    this.errorMessage,
  });

  final CallStatus status;
  final bool muted;
  final bool speakerEnabled;
  final Duration elapsed;
  final String? errorMessage;

  CallState copyWith({
    CallStatus? status,
    bool? muted,
    bool? speakerEnabled,
    Duration? elapsed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CallState(
      status: status ?? this.status,
      muted: muted ?? this.muted,
      speakerEnabled: speakerEnabled ?? this.speakerEnabled,
      elapsed: elapsed ?? this.elapsed,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
