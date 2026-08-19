import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/message_reply.dart';

part 'chat_composer_state.dart';

class ChatComposerCubit extends Cubit<ChatComposerState> {
  ChatComposerCubit() : super(const ChatComposerState());

  void textChanged(String value) {
    if (value == state.text) return;
    emit(state.copyWith(text: value));
  }

  void setReply(MessageReply reply) {
    emit(state.copyWith(replyingTo: reply, showEmojiPicker: false));
  }

  void clearReply() {
    if (state.replyingTo == null) return;
    emit(state.copyWith(clearReply: true));
  }

  void beginSending({bool clearFailure = false}) {
    emit(
      state.copyWith(
        sending: true,
        clearReply: true,
        clearFailure: clearFailure,
        showEmojiPicker: false,
      ),
    );
  }

  void finishSending() {
    if (!state.sending) return;
    emit(state.copyWith(sending: false));
  }

  void setFailure(String text, MessageReply? reply) {
    emit(state.copyWith(failedMessageText: text, failedMessageReply: reply));
  }

  void clearFailure() {
    if (state.failedMessageText == null && state.failedMessageReply == null) {
      return;
    }
    emit(state.copyWith(clearFailure: true));
  }

  void setEmojiPicker(bool value) {
    if (value == state.showEmojiPicker) return;
    emit(state.copyWith(showEmojiPicker: value));
  }

  void toggleEmojiPicker() {
    emit(state.copyWith(showEmojiPicker: !state.showEmojiPicker));
  }

  void setVoiceInputMode(bool value) {
    if (value == state.voiceInputMode) return;
    emit(
      state.copyWith(
        voiceInputMode: value,
        showEmojiPicker: value ? false : state.showEmojiPicker,
      ),
    );
  }
}
