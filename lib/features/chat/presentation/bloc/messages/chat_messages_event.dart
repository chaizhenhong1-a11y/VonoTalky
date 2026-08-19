part of 'chat_messages_bloc.dart';

sealed class ChatMessagesEvent {
  const ChatMessagesEvent();
}

final class ChatMessagesStarted extends ChatMessagesEvent {
  const ChatMessagesStarted();
}

final class _ChatMessagesSnapshotReceived extends ChatMessagesEvent {
  const _ChatMessagesSnapshotReceived(this.docs);
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
}

final class ChatMessagesLoadOlderRequested extends ChatMessagesEvent {
  ChatMessagesLoadOlderRequested({this.completer});
  final Completer<void>? completer;
}

final class ChatMessagesViewportChanged extends ChatMessagesEvent {
  const ChatMessagesViewportChanged(this.awayFromLatest);
  final bool awayFromLatest;
}

final class ChatMessagesNewerCleared extends ChatMessagesEvent {
  const ChatMessagesNewerCleared();
}

final class ChatMessagesPagingReset extends ChatMessagesEvent {
  const ChatMessagesPagingReset();
}

final class ChatMessagesHistoryTargetChanged extends ChatMessagesEvent {
  const ChatMessagesHistoryTargetChanged(this.messageId);
  final String? messageId;
}

final class ChatMessagesHighlightChanged extends ChatMessagesEvent {
  const ChatMessagesHighlightChanged(this.messageId);
  final String? messageId;
}

final class ChatMessagesHeartChanged extends ChatMessagesEvent {
  const ChatMessagesHeartChanged(this.messageId, this.visible);
  final String messageId;
  final bool visible;
}
