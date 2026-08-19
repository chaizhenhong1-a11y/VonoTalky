import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/chat_service.dart';

part 'chat_presence_state.dart';

class ChatPresenceCubit extends Cubit<ChatPresenceState> {
  ChatPresenceCubit({required this.otherId, ChatService? service})
    : _service = service ?? ChatService(),
      super(const ChatPresenceState());

  final String otherId;
  final ChatService _service;
  StreamSubscription<bool>? _typingSubscription;

  void start() {
    _typingSubscription?.cancel();
    _typingSubscription = _service
        .typing(otherId)
        .listen(
          (typing) => emit(ChatPresenceState(typing: typing)),
          onError: (_) => emit(const ChatPresenceState()),
        );
  }

  @override
  Future<void> close() async {
    await _typingSubscription?.cancel();
    return super.close();
  }
}
