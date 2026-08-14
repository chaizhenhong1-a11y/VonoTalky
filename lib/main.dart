import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'app/app.dart';
import 'firebase_options.dart';
import 'features/notifications/data/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VonoTalkyApp());

  // Do not block the first frame while notification permissions and tokens are
  // being prepared. Web push needs its own VAPID/service-worker setup, so it is
  // intentionally disabled until that configuration is available.
  if (!kIsWeb) {
    unawaited(
      NotificationService.instance.initialize().catchError((error, stackTrace) {
        debugPrint('Notification initialization failed: $error');
      }),
    );
  }
}
