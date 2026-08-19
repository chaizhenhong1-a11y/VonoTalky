import 'package:flutter_bloc/flutter_bloc.dart';

part 'chat_attachment_state.dart';

class ChatAttachmentCubit extends Cubit<ChatAttachmentState> {
  ChatAttachmentCubit() : super(const ChatAttachmentState());

  void setUploading(bool value) {
    if (value == state.uploading) return;
    emit(state.copyWith(uploading: value));
  }

  void startRecording() {
    emit(
      state.copyWith(recording: true, voiceSeconds: 0, voiceCancelArmed: false),
    );
  }

  void stopRecording() {
    emit(state.copyWith(recording: false, voiceCancelArmed: false));
  }

  void cancelRecording() {
    emit(
      state.copyWith(
        recording: false,
        voiceCancelArmed: false,
        voiceSeconds: 0,
      ),
    );
  }

  void setVoiceCancelArmed(bool value) {
    if (value == state.voiceCancelArmed) return;
    emit(state.copyWith(voiceCancelArmed: value));
  }

  void setVoiceSeconds(int value) {
    if (value == state.voiceSeconds) return;
    emit(state.copyWith(voiceSeconds: value));
  }
}
