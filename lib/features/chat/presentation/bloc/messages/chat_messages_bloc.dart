import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/chat_service.dart';

part 'chat_messages_event.dart';
part 'chat_messages_state.dart';

class ChatMessagesBloc extends Bloc<ChatMessagesEvent, ChatMessagesState> {
  ChatMessagesBloc({
    required this.otherId,
    ChatService? service,
    FirebaseFirestore? firestore,
    this.pageSize = 40,
  }) : _service = service ?? ChatService(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       super(const ChatMessagesState()) {
    on<ChatMessagesStarted>(_onStarted);
    on<_ChatMessagesSnapshotReceived>(_onSnapshotReceived);
    on<ChatMessagesLoadOlderRequested>(_onLoadOlder);
    on<ChatMessagesViewportChanged>(_onViewportChanged);
    on<ChatMessagesNewerCleared>(_onNewerCleared);
    on<ChatMessagesPagingReset>(_onPagingReset);
    on<ChatMessagesHistoryTargetChanged>(_onHistoryTargetChanged);
    on<ChatMessagesHighlightChanged>(_onHighlightChanged);
    on<ChatMessagesHeartChanged>(_onHeartChanged);
  }

  final String otherId;
  final int pageSize;
  final ChatService _service;
  final FirebaseFirestore _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Set<String> _knownRecentIds = <String>{};
  bool _snapshotInitialized = false;
  bool _awayFromLatest = false;

  String get conversationId => _service.roomId(otherId);

  Future<void> _onStarted(
    ChatMessagesStarted event,
    Emitter<ChatMessagesState> emit,
  ) async {
    await _subscription?.cancel();
    await _service.ensureConversation(otherId);
    _subscription = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(pageSize)
        .snapshots()
        .listen(
          (snapshot) => add(_ChatMessagesSnapshotReceived(snapshot.docs)),
          onError: (_) => add(const _ChatMessagesSnapshotReceived([])),
        );
  }

  Future<void> _onSnapshotReceived(
    _ChatMessagesSnapshotReceived event,
    Emitter<ChatMessagesState> emit,
  ) async {
    final recentDocs = event.docs;
    final recentIds = recentDocs.map((doc) => doc.id).toSet();
    final newIds = _snapshotInitialized
        ? recentIds.difference(_knownRecentIds)
        : <String>{};

    _knownRecentIds = recentIds;
    _snapshotInitialized = true;

    final merged = _mergeVisible(
      recentDocs: recentDocs,
      olderDocs: state.olderMessages,
    );

    emit(
      state.copyWith(
        messages: merged,
        loadingInitial: false,
        hasMoreOlder:
            state.olderMessages.isEmpty && recentDocs.length < pageSize
            ? false
            : state.hasMoreOlder,
        showJumpToLatest: _awayFromLatest && newIds.isNotEmpty
            ? true
            : state.showJumpToLatest,
        newerMessagesBelow: _awayFromLatest && newIds.isNotEmpty
            ? state.newerMessagesBelow + newIds.length
            : state.newerMessagesBelow,
        newMessageIds: newIds,
        clearError: true,
      ),
    );

    await _service.markRead(otherId);
  }

  Future<void> _onLoadOlder(
    ChatMessagesLoadOlderRequested event,
    Emitter<ChatMessagesState> emit,
  ) async {
    if (state.loadingOlder || !state.hasMoreOlder || state.messages.isEmpty) {
      event.completer?.complete();
      return;
    }

    emit(state.copyWith(loadingOlder: true, clearError: true));

    try {
      final allLoaded = <QueryDocumentSnapshot<Map<String, dynamic>>>[
        ...state.messages,
      ]..sort(_newestFirst);
      final oldest = allLoaded.last;
      final snapshot = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .startAfterDocument(oldest)
          .limit(pageSize)
          .get();

      final existing = state.olderMessages.map((doc) => doc.id).toSet();
      final additions = snapshot.docs.where(
        (doc) => !existing.contains(doc.id),
      );
      final older = <QueryDocumentSnapshot<Map<String, dynamic>>>[
        ...state.olderMessages,
        ...additions,
      ];
      final recent = state.messages
          .where((doc) => !state.olderMessages.any((old) => old.id == doc.id))
          .toList();

      emit(
        state.copyWith(
          olderMessages: older,
          messages: _mergeVisible(recentDocs: recent, olderDocs: older),
          loadingOlder: false,
          hasMoreOlder: snapshot.docs.length >= pageSize,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          loadingOlder: false,
          errorMessage: 'Older messages could not be loaded',
        ),
      );
    } finally {
      if (event.completer?.isCompleted == false) event.completer!.complete();
    }
  }

  void _onViewportChanged(
    ChatMessagesViewportChanged event,
    Emitter<ChatMessagesState> emit,
  ) {
    _awayFromLatest = event.awayFromLatest;
    if (event.awayFromLatest == state.showJumpToLatest) return;
    emit(
      state.copyWith(
        showJumpToLatest: event.awayFromLatest,
        newerMessagesBelow: event.awayFromLatest ? state.newerMessagesBelow : 0,
      ),
    );
  }

  void _onNewerCleared(
    ChatMessagesNewerCleared event,
    Emitter<ChatMessagesState> emit,
  ) {
    _awayFromLatest = false;
    emit(state.copyWith(showJumpToLatest: false, newerMessagesBelow: 0));
  }

  void _onPagingReset(
    ChatMessagesPagingReset event,
    Emitter<ChatMessagesState> emit,
  ) {
    emit(
      state.copyWith(
        olderMessages: const [],
        hasMoreOlder: true,
        newMessageIds: const <String>{},
      ),
    );
  }

  void _onHistoryTargetChanged(
    ChatMessagesHistoryTargetChanged event,
    Emitter<ChatMessagesState> emit,
  ) {
    emit(
      event.messageId == null
          ? state.copyWith(clearHistoryJumpTarget: true)
          : state.copyWith(historyJumpTargetId: event.messageId),
    );
  }

  void _onHighlightChanged(
    ChatMessagesHighlightChanged event,
    Emitter<ChatMessagesState> emit,
  ) {
    emit(
      event.messageId == null
          ? state.copyWith(clearHighlight: true)
          : state.copyWith(highlightedMessageId: event.messageId),
    );
  }

  void _onHeartChanged(
    ChatMessagesHeartChanged event,
    Emitter<ChatMessagesState> emit,
  ) {
    final next = Set<String>.from(state.heartAnimations);
    event.visible ? next.add(event.messageId) : next.remove(event.messageId);
    emit(state.copyWith(heartAnimations: next));
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _mergeVisible({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> recentDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> olderDocs,
  }) {
    final merged = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (final doc in olderDocs) {
      merged[doc.id] = doc;
    }
    for (final doc in recentDocs) {
      merged[doc.id] = doc;
    }
    final docs = merged.values.where((document) {
      final hiddenFor = List<String>.from(
        document.data()['hiddenFor'] as List? ?? const [],
      );
      return !hiddenFor.contains(_service.myId);
    }).toList()..sort(_newestFirst);
    return docs;
  }

  static int _newestFirst(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final aTime = a.data()['sentAt'] as Timestamp?;
    final bTime = b.data()['sentAt'] as Timestamp?;
    if (aTime == null && bTime == null) return 0;
    if (aTime == null) return 1;
    if (bTime == null) return -1;
    return bTime.compareTo(aTime);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
