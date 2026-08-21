import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';

import '../../data/models/incoming_call_invite.dart';
import '../../data/services/android_callkit_service.dart';
import '../../data/services/call_signaling_service.dart';
import '../pages/incoming_call_page.dart';

class IncomingCallListener extends StatefulWidget {
  const IncomingCallListener({super.key, required this.child});

  final Widget child;

  @override
  State<IncomingCallListener> createState() => _IncomingCallListenerState();
}

class _IncomingCallListenerState extends State<IncomingCallListener> {
  bool get _supportsIncomingCalls =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  final CallSignalingService _service = CallSignalingService();
  StreamSubscription<List<IncomingCallInvite>>? _subscription;
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;
  StreamSubscription<CallEvent?>? _callkitSubscription;
  String? _presentedCallId;

  @override
  void initState() {
    super.initState();

    if (!_supportsIncomingCalls) {
      return;
    }

    _subscription = _service.watchIncomingCalls().listen(
      _onIncomingCalls,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Incoming call listener error: $error');
      },
    );
    _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      _onNotificationOpened,
    );

    AndroidCallkitService.registerBackgroundHandler();
    if (AndroidCallkitService.supported) {
      _callkitSubscription = AndroidCallkitService.events.listen(
        _onCallkitEvent,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AndroidCallkitService.ensurePermissions();
      });
    }

    _routeInitialNotification();
  }

  Future<void> _onCallkitEvent(CallEvent? event) async {
    if (!mounted || event == null) return;

    final callId = AndroidCallkitService.callIdFromEvent(event);
    if (callId == null || callId.isEmpty) return;

    if (event is CallEventActionCallAccept) {
      final invite = await _service.readIncomingInvite(callId);
      if (!mounted || invite == null) return;

      await _presentInvite(invite, autoAccept: true);
      return;
    }

    if (event is CallEventActionCallDecline) {
      try {
        await _service.rejectCall(callId);
      } finally {
        await AndroidCallkitService.endNativeCall(callId);
      }
      return;
    }

    if (event is CallEventActionCallTimeout ||
        event is CallEventActionCallEnded) {
      try {
        await _service.endCall(callId);
      } catch (_) {
        // The remote side may have already ended the Firestore session.
      }
    }
  }

  Future<void> _routeInitialNotification() async {
    if (!_supportsIncomingCalls) return;

    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (!mounted || message == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _onNotificationOpened(message);
    });
  }

  Future<void> _onNotificationOpened(RemoteMessage message) async {
    if (!mounted || message.data['type'] != 'incoming_call') return;

    final callId = message.data['callId']?.toString() ?? '';
    if (callId.isEmpty || _presentedCallId == callId) return;

    final invite = await _service.readIncomingInvite(callId);
    if (!mounted || invite == null) return;

    await _presentInvite(invite);
  }

  Future<void> _onIncomingCalls(List<IncomingCallInvite> invites) async {
    if (!mounted || invites.isEmpty) return;

    final invite = invites.first;
    if (_presentedCallId == invite.id) return;

    if (AndroidCallkitService.supported) {
      await AndroidCallkitService.showIncomingFromData({
        'type': 'incoming_call',
        'callId': invite.id,
        'callerId': invite.callerId,
        'callerName': invite.callerName,
        'callerPhotoUrl': invite.callerPhotoUrl ?? '',
      });
      return;
    }

    await _presentInvite(invite);
  }

  Future<void> _presentInvite(
    IncomingCallInvite invite, {
    bool autoAccept = false,
  }) async {
    if (!mounted || _presentedCallId == invite.id) return;

    _presentedCallId = invite.id;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) =>
            IncomingCallPage(invite: invite, autoAccept: autoAccept),
      ),
    );

    if (_presentedCallId == invite.id) {
      _presentedCallId = null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageOpenedSubscription?.cancel();
    _callkitSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
