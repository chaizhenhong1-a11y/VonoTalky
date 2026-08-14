import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/shell/presentation/pages/main_shell_page.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page = switch (settings.name) {
      AppRoutes.register => const RegisterPage(),
      AppRoutes.home => const MainShellPage(),
      _ => const LoginPage(),
    };

    return MaterialPageRoute(
      settings: settings,
      builder: (_) => page,
    );
  }
}
