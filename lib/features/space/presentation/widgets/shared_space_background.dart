import 'package:flutter/material.dart';

import '../time_capsule/painters/time_capsule_scene_painter.dart';

class SharedSpaceBackground extends StatefulWidget {
  const SharedSpaceBackground({super.key, required this.pageAnimation});

  final Animation<double> pageAnimation;

  @override
  State<SharedSpaceBackground> createState() => _SharedSpaceBackgroundState();
}

class _SharedSpaceBackgroundState extends State<SharedSpaceBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _windController;

  @override
  void initState() {
    super.initState();

    _windController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNight = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final viewportHeight = constraints.maxHeight;

        // One continuous world spanning all 3 Tab pages.
        final worldWidth = viewportWidth * 3;

        return ClipRect(
          child: AnimatedBuilder(
            animation: Listenable.merge([
              widget.pageAnimation,
              _windController,
            ]),
            builder: (context, child) {
              final page = widget.pageAnimation.value;

              // Page 0: show world x = 0 .. 1 screen
              // Page 1: show world x = 1 .. 2 screens
              // Page 2: show world x = 2 .. 3 screens
              //
              // Because the tree is painted at worldWidth * 0.5,
              // it sits at 1.5 screens — exactly the middle Tab.
              final worldLeft = -page * viewportWidth;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: worldLeft,
                    top: 50,
                    width: worldWidth,
                    height: viewportHeight + 50,
                    child: CustomPaint(
                      painter: TimeCapsuleScenePainter(
                        animationValue: _windController.value,
                        hasCapsules: false,
                        isNight: isNight,
                        viewportWidth: viewportWidth,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
