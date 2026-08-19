part of 'chat_background_cubit.dart';

enum ChatBackgroundViewMode { mine, other }

final class ChatBackgroundState {
  const ChatBackgroundState({
    this.mine,
    this.other,
    this.viewMode = ChatBackgroundViewMode.mine,
    this.fallbackColorKey = 'blue',
    this.errorMessage,
  });

  final ChatBackgroundInfo? mine;
  final SharedChatBackground? other;
  final ChatBackgroundViewMode viewMode;
  final String fallbackColorKey;
  final String? errorMessage;

  bool get otherAvailable => other != null;

  String? get activeImageUrl {
    if (viewMode == ChatBackgroundViewMode.other) {
      final value = other?.imageUrl;
      if (value != null && value.isNotEmpty) return value;
    }
    final value = mine?.imageUrl;
    return value != null && value.isNotEmpty ? value : null;
  }

  ChatBackgroundState copyWith({
    ChatBackgroundInfo? mine,
    bool clearMine = false,
    SharedChatBackground? other,
    bool clearOther = false,
    ChatBackgroundViewMode? viewMode,
    String? fallbackColorKey,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatBackgroundState(
      mine: clearMine ? null : mine ?? this.mine,
      other: clearOther ? null : other ?? this.other,
      viewMode: viewMode ?? this.viewMode,
      fallbackColorKey: fallbackColorKey ?? this.fallbackColorKey,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
