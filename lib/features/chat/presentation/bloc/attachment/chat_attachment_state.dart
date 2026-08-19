part of 'chat_attachment_cubit.dart';

final class ChatAttachmentState {
  const ChatAttachmentState({
    this.uploading = false,
    this.recording = false,
    this.voiceCancelArmed = false,
    this.voiceSeconds = 0,
  });

  final bool uploading;
  final bool recording;
  final bool voiceCancelArmed;
  final int voiceSeconds;

  ChatAttachmentState copyWith({
    bool? uploading,
    bool? recording,
    bool? voiceCancelArmed,
    int? voiceSeconds,
  }) {
    return ChatAttachmentState(
      uploading: uploading ?? this.uploading,
      recording: recording ?? this.recording,
      voiceCancelArmed: voiceCancelArmed ?? this.voiceCancelArmed,
      voiceSeconds: voiceSeconds ?? this.voiceSeconds,
    );
  }
}
