import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final StreamController<Map<String, dynamic>> _notificationStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStreamController.stream;

  final StreamController<Map<String, dynamic>>
  _foregroundMessageStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get foregroundMessageStream =>
      _foregroundMessageStreamController.stream;

  void initialize() {
    // handle notification received when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        _foregroundMessageStreamController.add(message.data);
      }
    });

    // handle notification tapped when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data.isNotEmpty) {
        _notificationStreamController.add(message.data);
      }
    });

    // handle notification tapped when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && message.data.isNotEmpty) {
        // delay slightly to ensure HomeScreen has time to initialize and listen
        Future.delayed(const Duration(milliseconds: 1500), () {
          _notificationStreamController.add(message.data);
        });
      }
    });
  }
}
