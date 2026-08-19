import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/services/chat_background_service.dart';

part 'chat_background_state.dart';

class ChatBackgroundCubit extends Cubit<ChatBackgroundState> {
  ChatBackgroundCubit({required this.otherId, ChatBackgroundService? service})
    : _service = service ?? ChatBackgroundService(),
      super(const ChatBackgroundState());

  final String otherId;
  final ChatBackgroundService _service;
  StreamSubscription<ChatBackgroundInfo>? _mineSubscription;
  StreamSubscription<SharedChatBackground?>? _otherSubscription;

  void start() {
    _mineSubscription?.cancel();
    _otherSubscription?.cancel();
    _mineSubscription = _service
        .watchMine(otherId)
        .listen(
          (background) =>
              emit(state.copyWith(mine: background, clearError: true)),
          onError: (_) => emit(
            state.copyWith(
              errorMessage: 'My chat background could not be loaded.',
            ),
          ),
        );
    _otherSubscription = _service.watchOther(otherId).listen(
      (background) {
        final fallBack =
            background == null &&
            state.viewMode == ChatBackgroundViewMode.other;
        emit(
          state.copyWith(
            other: background,
            clearOther: background == null,
            viewMode: fallBack ? ChatBackgroundViewMode.mine : state.viewMode,
            clearError: true,
          ),
        );
      },
      onError: (_) => emit(
        state.copyWith(
          clearOther: true,
          viewMode: ChatBackgroundViewMode.mine,
          errorMessage: 'Shared chat background could not be loaded.',
        ),
      ),
    );
  }

  void restoreFallbackColor(String value) {
    if (value == state.fallbackColorKey) return;
    emit(state.copyWith(fallbackColorKey: value));
  }

  void setFallbackColor(String value) => restoreFallbackColor(value);

  void showMine() {
    if (state.viewMode != ChatBackgroundViewMode.mine) {
      emit(state.copyWith(viewMode: ChatBackgroundViewMode.mine));
    }
  }

  void showOther() {
    if (state.otherAvailable &&
        state.viewMode != ChatBackgroundViewMode.other) {
      emit(state.copyWith(viewMode: ChatBackgroundViewMode.other));
    }
  }

  @override
  Future<void> close() async {
    await _mineSubscription?.cancel();
    await _otherSubscription?.cancel();
    return super.close();
  }
}
