part of 'chat_pet_cubit.dart';

final class ChatPetState {
  const ChatPetState({
    this.anchor = const Offset(0.82, 0.18),
    this.visible = true,
    this.pendingInvite,
    this.sharedPet,
  });

  final Offset anchor;
  final bool visible;
  final PetInvite? pendingInvite;
  final SharedPet? sharedPet;

  ChatPetState copyWith({
    Offset? anchor,
    bool? visible,
    PetInvite? pendingInvite,
    bool clearInvite = false,
    SharedPet? sharedPet,
    bool clearSharedPet = false,
  }) {
    return ChatPetState(
      anchor: anchor ?? this.anchor,
      visible: visible ?? this.visible,
      pendingInvite: clearInvite ? null : pendingInvite ?? this.pendingInvite,
      sharedPet: clearSharedPet ? null : sharedPet ?? this.sharedPet,
    );
  }
}
