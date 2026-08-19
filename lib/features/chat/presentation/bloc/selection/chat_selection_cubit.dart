import 'package:flutter_bloc/flutter_bloc.dart';

part 'chat_selection_state.dart';

class ChatSelectionCubit extends Cubit<ChatSelectionState> {
  ChatSelectionCubit() : super(const ChatSelectionState());

  void toggle(String messageId) {
    final next = Set<String>.from(state.selectedMessageIds);
    if (!next.add(messageId)) next.remove(messageId);
    emit(state.copyWith(selectionMode: true, selectedMessageIds: next));
  }

  void toggleAll(Set<String> selectableIds) {
    final allSelected =
        state.selectedMessageIds.length == selectableIds.length &&
        state.selectedMessageIds.containsAll(selectableIds);
    emit(
      state.copyWith(
        selectionMode: true,
        selectedMessageIds: allSelected ? const <String>{} : selectableIds,
      ),
    );
  }

  void clearSelection() {
    if (state.selectedMessageIds.isEmpty) return;
    emit(state.copyWith(selectedMessageIds: const <String>{}));
  }

  void exit() {
    if (!state.selectionMode && state.selectedMessageIds.isEmpty) return;
    emit(const ChatSelectionState());
  }
}
