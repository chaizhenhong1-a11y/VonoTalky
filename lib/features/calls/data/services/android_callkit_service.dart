import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AndroidCallkitService {
  const AndroidCallkitService._();

  static const _fullScreenPromptKey =
      'vonotalky.calls.android.full_screen_prompted';

  static bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Stream<CallEvent?> get events => FlutterCallkitIncoming.onEvent;

  static void registerBackgroundHandler() {
    if (!supported) return;
    FirebaseMessaging.onBackgroundMessage(vonoCallBackgroundHandler);
  }

  static Future<void> ensurePermissions() async {
    if (!supported) return;

    await FlutterCallkitIncoming.requestNotificationPermission({
      'title': 'Allow call notifications',
      'rationaleMessagePermission':
          'VonoTalky needs notification permission to show incoming calls.',
      'postNotificationMessageRequired':
          'Allow notifications in Settings to receive incoming calls.',
    });

    final canUseFullScreen =
        await FlutterCallkitIncoming.canUseFullScreenIntent();
    if (canUseFullScreen == true) return;

    final preferences = await SharedPreferences.getInstance();
    final alreadyPrompted = preferences.getBool(_fullScreenPromptKey) ?? false;
    if (alreadyPrompted) return;

    await preferences.setBool(_fullScreenPromptKey, true);
    await FlutterCallkitIncoming.requestFullIntentPermission();
  }

  static Future<void> showIncomingFromMessage(RemoteMessage message) async {
    await showIncomingFromData(message.data);
  }

  static Future<void> showIncomingFromData(Map<String, dynamic> data) async {
    if (!supported || data['type']?.toString() != 'incoming_call') return;

    final callId = data['callId']?.toString() ?? '';
    if (callId.isEmpty) return;

    final callerName = data['callerName']?.toString().trim();
    final callerId = data['callerId']?.toString() ?? '';
    final callerPhotoUrl = data['callerPhotoUrl']?.toString() ?? '';

    final params = CallKitParams(
      id: callId,
      nameCaller: callerName == null || callerName.isEmpty
          ? 'VonoTalky user'
          : callerName,
      appName: 'VonoTalky',
      avatar: callerPhotoUrl,
      handle: callerId.isEmpty ? 'Voice call' : callerId,
      type: 0,
      duration: 45000,
      extra: <String, dynamic>{
        'type': 'incoming_call',
        'callId': callId,
        'callerId': callerId,
        'callerName': callerName ?? '',
        'callerPhotoUrl': callerPhotoUrl,
      },
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: false,
        subtitle: 'Missed voice call',
      ),
      android: const AndroidParams(
        isCustomNotification: false,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#6F52A2',
        actionColor: '#8B6DC1',
        textColor: '#FFFFFF',
        textAccept: 'Accept',
        textDecline: 'Decline',
        incomingCallNotificationChannelName: 'Incoming voice calls',
        missedCallNotificationChannelName: 'Missed voice calls',
        isShowCallID: false,
        isShowFullLockedScreen: true,
      ),
    );

    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  static String? callIdFromEvent(CallEvent? event) {
    if (event == null) return null;

    final params = switch (event) {
      CallEventActionCallAccept(:final callKitParams) => callKitParams,
      CallEventActionCallDecline(:final callKitParams) => callKitParams,
      CallEventActionCallEnded(:final callKitParams) => callKitParams,
      CallEventActionCallIncoming(:final callKitParams) => callKitParams,
      _ => null,
    };

    if (params == null) return null;

    final extra = params.extra;
    final extraCallId = extra?['callId']?.toString();
    if (extraCallId != null && extraCallId.isNotEmpty) {
      return extraCallId;
    }

    final id = params.id;
    if (id.isNotEmpty) return id;

    return null;
  }

  static Future<void> endNativeCall(String callId) async {
    if (!supported || callId.isEmpty) return;
    await FlutterCallkitIncoming.endCall(callId);
  }
}

@pragma('vm:entry-point')
Future<void> vonoCallBackgroundHandler(RemoteMessage message) async {
  if (message.data['type']?.toString() != 'incoming_call') return;
  await AndroidCallkitService.showIncomingFromMessage(message);
}
