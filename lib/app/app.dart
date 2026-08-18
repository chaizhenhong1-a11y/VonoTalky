import 'package:flutter/material.dart';

import '../features/auth/presentation/pages/auth_gate.dart';
import 'router/app_router.dart';
import 'navigation/app_navigator.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

class VonoTalkyApp extends StatelessWidget {
  const VonoTalkyApp({super.key});

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<VonoThemePreferences>(
        valueListenable: VonoThemeController.instance,
        builder: (context, preferences, _) => MaterialApp(
          navigatorKey: AppNavigator.key,
          debugShowCheckedModeBanner: false,
          title: 'VonoTalky',
          themeMode: preferences.mode,
          theme: AppTheme.light(preferences.color),
          darkTheme: AppTheme.dark(preferences.color),
          home: const AuthGate(),
          onGenerateRoute: AppRouter.onGenerateRoute,
        ),
      );
}
