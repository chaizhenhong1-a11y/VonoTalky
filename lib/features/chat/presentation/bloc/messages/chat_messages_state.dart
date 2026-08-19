part of 'chat_messages_bloc.dart';

final class ChatMessagesState {
  const ChatMessagesState({
    this.messages = const [],
    this.olderMessages = const [],
    this.loadingInitial = true,
    this.loadingOlder = false,
    this.hasMoreOlder = true,
    this.historyJumpTargetId,
    this.showJumpToLatest = false,
    this.newerMessagesBelow = 0,
    this.newMessageIds = const <String>{},
    this.heartAnimations = const <String>{},
    this.highlightedMessageId,
    this.errorMessage,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> messages;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> olderMessages;
  final bool loadingInitial;
  final bool loadingOlder;
  final bool hasMoreOlder;
  final String? historyJumpTargetId;
  final bool showJumpToLatest;
  final int newerMessagesBelow;
  final Set<String> newMessageIds;
  final Set<String> heartAnimations;
  final String? highlightedMessageId;
  final String? errorMessage;

  ChatMessagesState copyWith({
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? messages,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? olderMessages,
    bool? loadingInitial,
    bool? loadingOlder,
    bool? hasMoreOlder,
    String? historyJumpTargetId,
    bool clearHistoryJumpTarget = false,
    bool? showJumpToLatest,
    int? newerMessagesBelow,
    Set<String>? newMessageIds,
    Set<String>? heartAnimations,
    String? highlightedMessageId,
    bool clearHighlight = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChatMessagesState(
      messages: List.unmodifiable(messages ?? this.messages),
      olderMessages: List.unmodifiable(olderMessages ?? this.olderMessages),
      loadingInitial: loadingInitial ?? this.loadingInitial,
      loadingOlder: loadingOlder ?? this.loadingOlder,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      historyJumpTargetId: clearHistoryJumpTarget
          ? null
          : historyJumpTargetId ?? this.historyJumpTargetId,
      showJumpToLatest: showJumpToLatest ?? this.showJumpToLatest,
      newerMessagesBelow: newerMessagesBelow ?? this.newerMessagesBelow,
      newMessageIds: Set.unmodifiable(newMessageIds ?? this.newMessageIds),
      heartAnimations: Set.unmodifiable(
        heartAnimations ?? this.heartAnimations,
      ),
      highlightedMessageId: clearHighlight
          ? null
          : highlightedMessageId ?? this.highlightedMessageId,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
