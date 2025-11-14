import 'dart:async';
import 'package:flutter/material.dart';

// --- Firebase ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// --- Notificaciones locales ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- Otros ---
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// --- Tus pantallas ---
import 'package:kine_app/features/home_screen.dart';
import 'package:kine_app/features/splash_screen.dart';

// ===================================================================
// 🔥 1) HANDLER BACKGROUND
// ===================================================================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("📩 Mensaje recibido en background: ${message.messageId}");
}

// ===================================================================
// 🔥 2) CONFIG LOCAL NOTIFICATIONS
// ===================================================================

final FlutterLocalNotificationsPlugin _localNotifs =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'kine_channel',
  'Notificaciones Kine',
  description: 'Alertas de citas, mensajes y ejercicios',
  importance: Importance.defaultImportance,
);

Future<void> _initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();

  await _localNotifs.initialize(
    const InitializationSettings(android: android, iOS: ios),
  );

  await _localNotifs
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_androidChannel);
}

// ===================================================================
// 🔥 3) MAIN COMPLETO Y CORREGIDO
// ===================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Inicializar Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2) Localización
  await initializeDateFormatting('es_ES', null);

  // 3) Supabase
  await sb.Supabase.initialize(
    url: 'https://gwnbsjunvxiexmqpthkv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3bmJzanVudnhpZXhtcXB0aGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxOTE3NTEsImV4cCI6MjA3NDc2Nzc1MX0.ZpQIlCgkRYr7SwDY7mtWHqTsgiOzsDqciXSvqugBk8U',
  );

  // 4) Handler background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 5) 🔥 PIDE PERMISOS (Android 13 muestra popup)
  NotificationSettings settings = await FirebaseMessaging.instance
      .requestPermission(
        alert: true,
        badge: true,
        sound: true,
        criticalAlert: true,
        announcement: true,
        provisional: false,
      );

  print("🔔 Permiso de notificaciones: ${settings.authorizationStatus}");

  // 6) Notificaciones en foreground (iOS)
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 7) Notificaciones locales
  await _initLocalNotifications();

  runApp(const MyApp());
}

// ===================================================================
// 🔥 4) CLASE PRINCIPAL MyApp CON LISTENERS
// ===================================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // ────────────────────────────────────────────────
    // 🔥 NOTIFICACIONES EN FOREGROUND
    // ────────────────────────────────────────────────
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        _localNotifs.show(
          notif.hashCode,
          notif.title,
          notif.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'kine_channel',
              'Notificaciones Kine',
              channelDescription: 'Alertas de ejercicios, citas y mensajes',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    // ────────────────────────────────────────────────
    // 🔥 NOTIFICACIÓN TOCADA (APP EN BACKGROUND)
    // ────────────────────────────────────────────────
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("📲 Notificación tocada en background: ${message.data}");
      _handleNotificationTap(message.data);
    });

    // ────────────────────────────────────────────────
    // 🔥 NOTIFICACIÓN TOCADA (APP CERRADA)
    // ────────────────────────────────────────────────
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print("📲 Notificación tocada con app cerrada: ${message.data}");
        _handleNotificationTap(message.data);
      }
    });
  }

  // ===================================================================
  // 🔥 Manejo de navegación según la notificación
  // ===================================================================
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    print("➡ Navegar según notificación: $type");

    if (type == 'mensaje') {
      print("Abrir chat con: ${data['chatWith']}");
    } else if (type == 'cita') {
      print("Ir a pantalla de Citas");
    } else if (type == 'recordatorio') {
      print("Ir al progreso de ejercicios");
    }
  }

  // ===================================================================
  // 🔥 5) MATERIAL APP + AUTH STREAM
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return const HomeScreen();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
    );
  }
}
