import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../app/theme/theme_controller.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.showBackButton = false,
  });

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final preferences = VonoThemeController.instance.value;
    final themeColor = preferences.color;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            themeColor.authAssetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: .02),
                  themeColor.authOverlay.withValues(alpha: .05),
                  const Color(0x30000000),
                ],
                stops: const [0, .46, 1],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 38,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _TopBar(
                        showBackButton: showBackButton,
                        themeColor: themeColor,
                      ),
                      const SizedBox(height: 110),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: 4.5,
                                sigmaY: 4.5,
                              ),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  22,
                                  22,
                                  18,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x14100B1A),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .42),
                                    width: 2.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: themeColor.seed.withValues(
                                        alpha: .10,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showBackButton, required this.themeColor});

  final bool showBackButton;
  final VonoThemeColor themeColor;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (showBackButton)
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x30000000),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        )
      else
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [themeColor.seed, themeColor.secondary],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: themeColor.seed.withValues(alpha: .4),
                blurRadius: 16,
              ),
            ],
          ),
          child: const Icon(Icons.forum_rounded, color: Colors.white),
        ),
      const SizedBox(width: 10),
      const Text(
        'VonoTalky',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          shadows: [Shadow(color: Color(0x88000000), blurRadius: 10)],
        ),
      ),
    ],
  );
}
