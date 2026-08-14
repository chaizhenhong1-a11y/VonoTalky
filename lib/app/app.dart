import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/auth_gate.dart';
import 'router/app_router.dart';
import 'navigation/app_navigator.dart';
import 'theme/app_theme.dart';

class VonoTalkyApp extends StatelessWidget {
  const VonoTalkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigator.key,
      debugShowCheckedModeBanner: false,
      title: 'VonoTalky',
      theme: AppTheme.light,
      home: const AuthGate(),
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
