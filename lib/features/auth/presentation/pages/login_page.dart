import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../data/services/auth_service.dart';
import '../widgets/auth_background.dart';
import '../widgets/auth_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await AuthService().signIn(
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

  Future<void> _resetPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _notice('Enter your email address first.');
      return;
    }
    try {
      await AuthService().sendPasswordReset(email);
      if (mounted) _notice('Password reset email sent.');
    } on AuthFailure catch (error) {
      if (mounted) _notice(error.message);
    }
  }

  @override
  Widget build(BuildContext context) => AuthBackground(
    showBackButton: true,
    child: AutofillGroup(
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0x33FFFFFF),
                  border: Border.all(color: const Color(0x99FFFFFF)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x55FFFFFF), blurRadius: 15),
                  ],
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [Shadow(color: Color(0x44000000), blurRadius: 6)],
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sign in and continue your conversations.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xE6FFFFFF)),
            ),
            const SizedBox(height: 22),
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
            const SizedBox(height: 13),
            AuthTextField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              textInputAction: TextInputAction.done,
              validator: (value) => (value?.length ?? 0) < 6
                  ? 'Password must be at least 6 characters'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                onPressed: loading ? null : _resetPassword,
                child: const Text('Forgot password?'),
              ),
            ),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: loading ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0x66B49ADF),
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xB3FFFFFF)),
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
                        'Sign in',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 13),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'New to VonoTalky?',
                  style: TextStyle(color: Color(0xE6FFFFFF)),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(AppRoutes.register),
                  child: const Text('Create account'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  void _notice(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
