import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../contacts/data/services/contact_detail_service.dart';

part 'chat_preferences_state.dart';

class ChatPreferencesCubit extends Cubit<ChatPreferencesState> {
  ChatPreferencesCubit({required this.otherId, ContactDetailService? service})
    : _service = service ?? ContactDetailService(),
      super(const ChatPreferencesState());

  final String otherId;
  final ContactDetailService _service;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  void start() {
    _subscription?.cancel();
    _subscription = _service
        .preferences(otherId)
        .listen(
          (data) => emit(
            ChatPreferencesState(
              muted: data['muted'] as bool? ?? false,
              pinned: data['pinned'] as bool? ?? false,
            ),
          ),
          onError: (_) {},
        );
  }

  Future<void> setMuted(bool value) =>
      _service.setPreference(otherId, 'muted', value);

  Future<void> setPinned(bool value) =>
      _service.setPreference(otherId, 'pinned', value);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
