import 'dart:ui';

import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.showBackButton = false,
  });

  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/auth_mountain.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
          errorBuilder: (_, _, _) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFB8A3DB), Color(0xFFF0DCEB)],
              ),
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
                    _TopBar(showBackButton: showBackButton),
                    const SizedBox(height: 110),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                22,
                                22,
                                22,
                                18,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0x03FFFFFF),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xCCFFFFFF),
                                  width: 1.2,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x120E0717),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showBackButton});
  final bool showBackButton;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (showBackButton)
        IconButton.filledTonal(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: const Color(0x40FFFFFF),
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.arrow_back_rounded),
        )
      else
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFB49ADF),
            borderRadius: BorderRadius.circular(14),
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
          shadows: [Shadow(color: Color(0x55000000), blurRadius: 8)],
        ),
      ),
    ],
  );
}
