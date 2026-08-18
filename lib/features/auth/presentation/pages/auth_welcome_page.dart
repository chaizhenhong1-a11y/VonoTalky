import 'package:flutter/material.dart';

import '../../../../app/theme/theme_controller.dart';

import '../widgets/auth_background.dart';
import 'login_page.dart';
import 'register_page.dart';

class AuthWelcomePage extends StatelessWidget {
  const AuthWelcomePage({super.key});

  @override
  Widget build(BuildContext context) => AuthBackground(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0x24FFFFFF),
              border: Border.all(color: const Color(0xB3FFFFFF), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Color(0x40FFFFFF), blurRadius: 18),
              ],
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: Colors.white,
              size: 37,
            ),
          ),
        ),
        const SizedBox(height: 17),
        const Text(
          'Welcome to VonoTalky',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            shadows: [Shadow(color: Color(0x55000000), blurRadius: 8)],
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Closer conversations start here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterPage()),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: VonoThemeController.instance.value.color.seed
                  .withValues(alpha: .24),
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xE6FFFFFF), width: 1.25),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text(
              'Sign Up',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: 13),
        SizedBox(
          height: 54,
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: const Color(0x08FFFFFF),
              side: const BorderSide(color: Color(0xE6FFFFFF), width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
              ),
            ),
            child: const Text(
              'Log In',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    ),
  );
}
