import 'dart:convert'; // KROK 1: Potrzebne do jsonEncode / jsonDecode
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:specjalist_app/screens/home_screen.dart';
import 'package:specjalist_app/screens/main_screens/upcoming_screen.dart';
import '../screens/offer_from_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'user_profile.dart';
import 'app_refresh_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  late GlobalKey<NavigatorState> _navigatorKey;

  Future<void> initializeSettings(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'healthforhome_channel',
      'Health for Home',
      description: 'Powiadomienia o nowych ofertach',
      importance: Importance.max,
    );

    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/aaa');
  
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
      
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // KROK 2: Odbieramy pełny JSON i zamieniamy go z powrotem na Mapę
        if (details.payload != null) {
          try {
            final Map<String, dynamic> data = jsonDecode(details.payload!);
            _handleMessageData(data);
          } catch (e) {
            print("Błąd parsowania payloadu lokalnego powiadomienia: $e");
          }
        }
      },
    );

    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
    
    _initialized = true;
  }

  Future<void> requestPermissionsAndToken() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, 
      badge: true, 
      sound: true
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await _messaging.getToken();
      await uploadTokenToServer(token);
      _messaging.onTokenRefresh.listen(uploadTokenToServer);
    }
  }
  
  Future<void> uploadTokenToServer([String? existingToken]) async {
    try {
      final token = existingToken ?? await _messaging.getToken();
      if (token != null) {
        if (UserSession.token != null) { 
           await ApiService().sendDeviceToken(token);
           print("Token FCM wysłany pomyślnie.");
        }
      }
    } catch (e) {
      print("Nie udało się wysłać tokenu: $e");
    }
  }

  void _handleForeground(RemoteMessage message) {
    print("=== PUSH ODEBRANY ===");
    print(message.notification?.title);
    print(message.notification?.body);
    print(message.data);

    // KROK 3: Zamieniamy całą mapę `message.data` na String (JSON)
    // Dzięki temu nie zgubimy danych pacjenta i dat!
    final String jsonPayload = jsonEncode(message.data);

    _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Health for Home',
      message.notification?.body ?? 'Masz nowe powiadomienie',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'healthforhome_channel',
          'Health for Home',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'aaa',
        ),
      ),
      payload: jsonPayload, // <--- Przekazujemy pełny JSON
    );

    AppRefreshService().refresh();
  }

  void _handleMessageClick(RemoteMessage message) {
    _handleMessageData(message.data);
  }

 void _handleMessageData(Map<String, dynamic> data) {
  print("=== OBSŁUGA DANYCH PUSH ===");
  print(data);

  final screen = data['screen'];

  // Jeśli to ekran 'offer', potrzebujemy appointmentId
  if (screen == 'offer') {
    final appointmentId = data['appointmentId'];
    if (appointmentId == null) return;

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => OfferFormScreen(
          appointmentId: appointmentId,
          patientName: data['patientName'] ?? 'Nieznany pacjent',
          startDate: data['startDate'] ?? '',
          endDate: data['endDate'] ?? '',
          description: data['description'] ?? '',
        ),
      ),
    );
  } 
  // KROK DODATKOWY: Obsługa powiadomienia o weryfikacji konta (ekran Home)
  else if (screen == 'home') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }
  else if (screen == 'rating') {
    _navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const UpcomingScreen()),
    );
  }
}
}