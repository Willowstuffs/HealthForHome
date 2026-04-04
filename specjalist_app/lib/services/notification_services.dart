import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
  // Ta metoda tylko konfiguruje nasłuchiwanie - wywołaj ją w main lub na początku app
  Future<void> initializeSettings(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'healthforhome_channel', // id
      'Health for Home',       // nazwa widoczna w ustawieniach
      description: 'Powiadomienia o nowych ofertach',
      importance: Importance.max,
    );
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  // Konfiguracja lokalnych powiadomień
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/aaa'); // Użyj nazwy zasobu, nie ścieżki pliku!
  
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
      
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleMessageData({'appointmentId': details.payload, 'screen': 'offer'});
        }
      },
    );

    // Nasłuchiwanie na wiadomości (nie prosi o uprawnienia)
    FirebaseMessaging.onMessage.listen(_handleForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageClick);
    
    _initialized = true;
}
Future<void> requestPermissionsAndToken() async {
  // Dopiero tutaj wyskoczy systemowe okno
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
      // Pobierz token jeśli nie został przekazany
      final token = existingToken ?? await _messaging.getToken();
      
      if (token != null) {
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
    // Show local notification so user sees it while app is open
    _localNotifications.show(
      message.hashCode,
      'Health for Home',  // stały tytuł
      'Nowa oferta',       // stała treść
      NotificationDetails(
        android: AndroidNotificationDetails(
          'healthforhome_channel',
          'Health for Home',
          importance: Importance.max,
          priority: Priority.high,
          icon: 'aaa', // własna ikona
        ),
      ),
      payload: message.data['appointmentId'], // backendowe dane dalej w payloadzie
    );

    AppRefreshService().refresh();
  }

  void _handleMessageClick(RemoteMessage message) {
    _handleMessageData(message.data);
  }

  void _handleMessageData(Map<String, dynamic> data) {
    final appointmentId = data['appointmentId'];
    final screen = data['screen'];

    if (appointmentId == null) return;

    if (screen == 'offer') {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => OfferFormScreen(
            appointmentId: appointmentId,
            patientName: data['patientName'] ?? '',
            startDate: data['startDate'] ?? '',
            endDate: data['endDate'] ?? '',
            description: data['description'] ?? '',
          ),
        ),
      );
    }
  }
}
