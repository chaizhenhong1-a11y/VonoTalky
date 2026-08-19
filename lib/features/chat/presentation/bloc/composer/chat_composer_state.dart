part of 'chat_composer_cubit.dart';

final class ChatComposerState {
  const ChatComposerState({
    this.text = '',
    this.sending = false,
    this.replyingTo,
    this.failedMessageText,
    this.failedMessageReply,
    this.showEmojiPicker = false,
    this.voiceInputMode = false,
  });

  final String text;
  final bool sending;
  final MessageReply? replyingTo;
  final String? failedMessageText;
  final MessageReply? failedMessageReply;
  final bool showEmojiPicker;
  final bool voiceInputMode;

  bool get canSend => text.trim().isNotEmpty && !sending;

  ChatComposerState copyWith({
    String? text,
    bool? sending,
    MessageReply? replyingTo,
    bool clearReply = false,
    String? failedMessageText,
    MessageReply? failedMessageReply,
    bool clearFailure = false,
    bool? showEmojiPicker,
    bool? voiceInputMode,
  }) {
    return ChatComposerState(
      text: text ?? this.text,
      sending: sending ?? this.sending,
      replyingTo: clearReply ? null : replyingTo ?? this.replyingTo,
      failedMessageText: clearFailure
          ? null
          : failedMessageText ?? this.failedMessageText,
      failedMessageReply: clearFailure
          ? null
          : failedMessageReply ?? this.failedMessageReply,
      showEmojiPicker: showEmojiPicker ?? this.showEmojiPicker,
      voiceInputMode: voiceInputMode ?? this.voiceInputMode,
    );
  }
}
