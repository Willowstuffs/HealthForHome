import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../screens/offer_from_screen.dart';
import 'api_service.dart';
import 'user_profile.dart';
import 'app_refresh_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  late GlobalKey<NavigatorState> _navigatorKey;
  // Ta metoda tylko konfiguruje nasłuchiwanie - wywołaj ją w main lub na początku app
  Future<void> setupInteractions(
    GlobalKey<NavigatorState> navigatorKey) async {
  if (_initialized) return;

  _initialized = true;
  _navigatorKey = navigatorKey;

  await _messaging.requestPermission(
      alert: true, badge: true, sound: true);

  final token = await _messaging.getToken();
  await uploadTokenToServer(token);

  _messaging.onTokenRefresh.listen(uploadTokenToServer);

  FirebaseMessaging.onMessage.listen(_handleForeground);
  FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
}

  // Osobna metoda do wysyłki, którą wywołasz PO ZALOGOWANIU
  Future<void> uploadTokenToServer([String? existingToken]) async {
    try {
      // Pobierz token jeśli nie został przekazany
      final token = existingToken ?? await _messaging.getToken();
      
      if (token != null) {
        // Tu warto dodać sprawdzenie w UserSession czy mamy JWT
        if (UserSession.token != null) { 
           await ApiService().sendDeviceToken(token);
           print("Token FCM wysłany pomyślnie.");
        }
      }
    } catch (e) {
      print("Nie udało się wysłać tokenu (prawdopodobnie brak autoryzacji): $e");
    }
  }

  void _handleForeground(RemoteMessage message) {
    print('Foreground: ${message.notification?.title}');
    AppRefreshService().refresh();
  }

  void _handleMessageClick(RemoteMessage message) {
  final appointmentId = message.data['appointmentId'];
  final screen = message.data['screen'];

  if (appointmentId == null) return;

  if (screen == 'offer') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => OfferFormScreen(
          appointmentId: appointmentId,
          patientName: message.data['patientName'] ?? '',
          startDate: message.data['startDate'] ?? '',
          endDate: message.data['endDate'] ?? '',
          description: message.data['description'] ?? '',
        ),
      ),
    );
  }
}
}
