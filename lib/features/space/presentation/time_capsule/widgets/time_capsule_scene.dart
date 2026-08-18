import 'package:flutter/material.dart';

import 'time_capsule_scene_hint.dart';

class TimeCapsuleScene extends StatelessWidget {
  const TimeCapsuleScene({
    super.key,
    required this.hasCapsules,
    required this.capsuleCount,
    required this.onGroundTap,
  });

  final bool hasCapsules;
  final int capsuleCount;
  final VoidCallback onGroundTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              left: constraints.maxWidth * 0.08,
              right: constraints.maxWidth * 0.08,
              bottom: 10,
              height: constraints.maxHeight * 0.30,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: onGroundTap,
              ),
            ),
            if (hasCapsules)
              Positioned(
                left: 0,
                right: 0,
                bottom: 78,
                child: IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.eco_rounded,
                      size: 26,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: hasCapsules
                        ? TimeCapsuleSceneHint(
                            key: const ValueKey('buried'),
                            icon: '🌱',
                            title: '树下埋着 $capsuleCount 个胶囊',
                            subtitle: '点击树下查看',
                          )
                        : const TimeCapsuleSceneHint(
                            key: ValueKey('empty'),
                            icon: '🍂',
                            title: '轻点树下',
                            subtitle: '埋下第一个时间胶囊',
                          ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
