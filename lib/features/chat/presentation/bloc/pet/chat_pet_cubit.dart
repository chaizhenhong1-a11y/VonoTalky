import 'dart:async';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../pet/data/models/pet_invite.dart';
import '../../../../pet/data/models/shared_pet.dart';
import '../../../../pet/data/services/pet_invite_service.dart';
import '../../../../pet/data/services/shared_pet_service.dart';

part 'chat_pet_state.dart';

class ChatPetCubit extends Cubit<ChatPetState> {
  ChatPetCubit({
    required this.otherId,
    PetInviteService? petInviteService,
    SharedPetService? sharedPetService,
  }) : _petInviteService = petInviteService ?? PetInviteService(),
       _sharedPetService = sharedPetService ?? SharedPetService(),
       super(const ChatPetState());

  final String otherId;
  final PetInviteService _petInviteService;
  final SharedPetService _sharedPetService;
  StreamSubscription<PetInvite?>? _inviteSubscription;
  StreamSubscription<SharedPet?>? _petSubscription;

  void start() {
    _inviteSubscription?.cancel();
    _petSubscription?.cancel();
    _inviteSubscription = _petInviteService
        .watchPendingInviteWith(otherId)
        .listen(
          (invite) => emit(
            state.copyWith(pendingInvite: invite, clearInvite: invite == null),
          ),
        );
    _petSubscription = _sharedPetService
        .watchSharedPetWith(otherId)
        .listen(
          (pet) =>
              emit(state.copyWith(sharedPet: pet, clearSharedPet: pet == null)),
        );
  }

  void restore({required bool visible, double? x, double? y}) {
    emit(
      state.copyWith(
        visible: visible,
        anchor: x != null && y != null
            ? Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0))
            : state.anchor,
      ),
    );
  }

  void updateAnchor(Offset anchor) => emit(state.copyWith(anchor: anchor));
  void setVisible(bool value) => emit(state.copyWith(visible: value));

  @override
  Future<void> close() async {
    await _inviteSubscription?.cancel();
    await _petSubscription?.cancel();
    return super.close();
  }
}
