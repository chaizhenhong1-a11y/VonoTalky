import 'package:flutter/material.dart';

import '../../../../app/theme/theme_controller.dart';

import '../../data/services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await AuthService().register(
        displayName: nameController.text,
        email: emailController.text,
        password: passwordController.text,
      );
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on AuthFailure catch (error) {
      if (mounted) _notice(error.message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => AuthBackground(
    showBackButton: true,
    child: Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.person_add_alt_1_rounded,
            color: Colors.white,
            size: 35,
          ),
          const SizedBox(height: 8),
          const Text(
            'Create account',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [Shadow(color: Color(0x44000000), blurRadius: 6)],
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Join VonoTalky and start meaningful conversations.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xE6FFFFFF)),
          ),
          const SizedBox(height: 20),
          AuthTextField(
            controller: nameController,
            label: 'Display name',
            icon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            validator: (value) => (value?.trim().length ?? 0) < 2
                ? 'Enter your display name'
                : null,
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: emailController,
            label: 'Email address',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) return 'Enter your email address';
              if (!email.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 12),
          AuthTextField(
            controller: passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (value) =>
                (value?.length ?? 0) < 6 ? 'Use at least 6 characters' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: VonoThemeController.instance.value.color.seed
                    .withValues(alpha: .24),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Color(0xD9FFFFFF), width: 1.15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: loading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Create account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'By continuing, you agree to the Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: Color(0xD9FFFFFF),
            ),
          ),
        ],
      ),
    ),
  );

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}
