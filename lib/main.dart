import 'dart:async';
import 'package:flutter/material.dart';

// Imports de Firebase principales
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// Notificaciones locales
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Herramientas adicionales
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// Pantallas principales de la app
import 'package:kine_app/features/home_screen.dart';
import 'package:kine_app/features/splash_screen.dart';

/// Handler que se ejecuta cuando llega una notificación
/// y la app está cerrada o en segundo plano.
/// Firebase obliga a inicializar nuevamente en este punto.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Notificación recibida en background: ${message.messageId}");
}

/// Instancia para manejar notificaciones locales dentro del teléfono.
final FlutterLocalNotificationsPlugin _localNotifs =
    FlutterLocalNotificationsPlugin();

/// Canal de notificaciones para Android.
/// Necesario para que el sistema permita mostrar alertas.
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'kine_channel',
  'Notificaciones Kine',
  description: 'Alertas de citas, ejercicios y mensajes',
  importance: Importance.defaultImportance,
);

/// Inicializa el sistema de notificaciones locales.
/// Esto configura íconos, permisos y compatibilidad iOS/Android.
Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

  // Inicialización general
  await _localNotifs.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  // Crea el canal en Android
  await _localNotifs
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_androidChannel);
}

/// Punto de inicio de toda la aplicación.
/// Se encarga de inicializar Firebase, Supabase, notificaciones
/// y cualquier servicio crítico antes de levantar la UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización de Firebase usando opciones generadas por FlutterFire.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicialización de formateo de fechas en español.
  await initializeDateFormatting('es_ES', null);

  // Inicialización de Supabase (para login social o servicios externos).
  await sb.Supabase.initialize(
    url: 'https://gwnbsjunvxiexmqpthkv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3bmJzanVudnhpZXhtcXB0aGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxOTE3NTEsImV4cCI6MjA3NDc2Nzc1MX0.ZpQIlCgkRYr7SwDY7mtWHqTsgiOzsDqciXSvqugBk8U',
  );

  // Configurar recepción de notificaciones cuando la app está cerrada.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Solicitar permisos al usuario para recibir notificaciones.
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, sound: true, badge: true);

  // iOS: permitir mostrar notificaciones con la app abierta.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // Inicialización del sistema de notificaciones locales.
  await _initLocalNotifications();

  runApp(const MyApp());
}

/// Widget principal de la aplicación.
/// Contiene listeners globales de notificaciones y define
/// la navegación dependiendo del estado de autenticación.
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Listener para notificaciones recibidas mientras la app está abierta.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;

      // Si trae contenido visible, mostrar notificación local.
      if (notif != null) {
        _localNotifs.show(
          notif.hashCode,
          notif.title,
          notif.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'kine_channel',
              'Notificaciones Kine',
              channelDescription: 'Alertas de citas, ejercicios y mensajes',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    // Listener cuando el usuario toca una notificación con la app en background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notificación abierta desde background: ${message.data}");
      _handleNotificationTap(message.data);
    });

    // Cuando la app se abre desde terminada por una notificación.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print("Notificación abrió la app desde terminada: ${message.data}");
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Manejo de navegación cuando el usuario toca una notificación.
  /// Aquí solo se imprime la información porque navegar directamente
  /// desde este contexto requiere un NavigatorKey global.
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'];
    print("Procesando notificación pulsada. Tipo: $type");

    if (type == 'mensaje') {
      final chatWith = data['chatWith'];
      print("Debería navegar al chat con: $chatWith");
    } else if (type == 'cita') {
      print("Debería navegar al módulo de citas");
    } else if (type == 'recordatorio') {
      print("Debería navegar al progreso de ejercicios");
    }
  }

  /// El build principal define si mostrar:
  /// - HomeScreen (si el usuario está logeado)
  /// - WelcomeScreen (si no ha iniciado sesión)
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Mientras Firebase revisa si hay sesión activa.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si el usuario ya está logeado, ir al home.
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // Si no hay usuario, mostrar WelcomeScreen.
          return const WelcomeScreen();
        },
      ),
    );
  }
}
