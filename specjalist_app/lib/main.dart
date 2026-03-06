import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'firebase_options.dart';
import 'services/notification_services.dart';
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
// Funkcja obsługująca powiadomienia w tle
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Odebrano powiadomienie w tle: ${message.messageId}');
  print('Tytuł: ${message.notification?.title}');
  print('Treść: ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  // Inicjalizacja Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Rejestracja handlera powiadomień w tle
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService().setupInteractions(navigatorKey);
  runApp(MyApp());


}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'HealthForHome',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
