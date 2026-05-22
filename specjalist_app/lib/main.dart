import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';
import 'services/notification_services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey =
    GlobalKey<NavigatorState>();

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

/// Powiadomienia w tle
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Odebrano powiadomienie w tle: ${message.messageId}');
  print('Tytuł: ${message.notification?.title}');
  print('Treść: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  /// Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// Handler background
  FirebaseMessaging.onBackgroundMessage(
    _firebaseMessagingBackgroundHandler,
  );

  /// Pobranie FCM tokena
  final messaging = FirebaseMessaging.instance;

  /// Request permission (iOS + Android 13)
  await messaging.requestPermission();

  /// Aktualny token
  final fcmToken = await messaging.getToken();

  print("FCM TOKEN:");
  print(fcmToken);

  /// Zapis lokalny
  final prefs = await SharedPreferences.getInstance();

  if (fcmToken != null) {
    await prefs.setString('fcm_token', fcmToken);
  }

  /// Listener zmiany tokena
  FirebaseMessaging.instance.onTokenRefresh.listen(
    (newToken) async {
      print("NOWY TOKEN:");
      print(newToken);

      await prefs.setString('fcm_token', newToken);

      /// jeśli user zalogowany:
      /// await ApiService().updateFcmToken(newToken);
    },
  );

  /// Lokalne powiadomienia
  await NotificationService()
      .initializeSettings(navigatorKey);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HealthForHome',
      theme: AppTheme.lightTheme,
      locale: const Locale('pl', 'PL'),
      supportedLocales: const [
        Locale('pl', 'PL'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}