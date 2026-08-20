import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Keeps the root navigation stack consistent with authentication state.
///
/// Feature pages only perform authentication actions (for example sign out).
/// This coordinator owns the cross-cutting responsibility of removing
/// authenticated routes after the session ends.
class AuthNavigationCoordinator {
  AuthNavigationCoordinator({
    required this.authStateChanges,
    required this.navigatorKey,
  });

  final Stream<User?> authStateChanges;
  final GlobalKey<NavigatorState> navigatorKey;

  StreamSubscription<User?>? _subscription;
  bool _disposed = false;

  void start() {
    _subscription ??= authStateChanges.listen(_handleAuthStateChanged);
  }

  void _handleAuthStateChanged(User? user) {
    if (_disposed || user != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_disposed) return;

      final navigator = navigatorKey.currentState;
      if (navigator == null || !navigator.mounted) return;

      navigator.popUntil((route) => route.isFirst);
    });
  }

  Future<void> dispose() async {
    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
  }
}
