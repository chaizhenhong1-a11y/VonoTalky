import 'package:flutter/material.dart';

import '../../animation/pet_actor.dart';

class FloatingPetActor extends StatelessWidget {
  const FloatingPetActor({
    super.key,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
    this.visualSize = 92,
    this.hitSize = 108,
  });

  final ValueChanged<Offset> onDragUpdate;
  final VoidCallback onDragEnd;
  final VoidCallback onTap;
  final double visualSize;
  final double hitSize;

  @override
  Widget build(BuildContext context) => PetActor(
    visualSize: visualSize,
    hitSize: hitSize,
    onDragUpdate: onDragUpdate,
    onDragEnd: onDragEnd,
    onTap: onTap,
  );
}
