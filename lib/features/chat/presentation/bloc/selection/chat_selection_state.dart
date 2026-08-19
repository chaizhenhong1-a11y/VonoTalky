part of 'chat_selection_cubit.dart';

final class ChatSelectionState {
  const ChatSelectionState({
    this.selectionMode = false,
    this.selectedMessageIds = const <String>{},
  });

  final bool selectionMode;
  final Set<String> selectedMessageIds;

  int get count => selectedMessageIds.length;
  bool get hasSelection => selectedMessageIds.isNotEmpty;

  ChatSelectionState copyWith({
    bool? selectionMode,
    Set<String>? selectedMessageIds,
  }) {
    return ChatSelectionState(
      selectionMode: selectionMode ?? this.selectionMode,
      selectedMessageIds: Set<String>.unmodifiable(
        selectedMessageIds ?? this.selectedMessageIds,
      ),
    );
  }
}
