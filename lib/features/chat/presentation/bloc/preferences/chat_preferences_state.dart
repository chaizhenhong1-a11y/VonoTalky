part of 'chat_preferences_cubit.dart';

final class ChatPreferencesState {
  const ChatPreferencesState({this.muted = false, this.pinned = false});

  final bool muted;
  final bool pinned;
}
