import 'dart:async';
import 'package:flutter/material.dart';

// --- Imports de Firebase (comunes y de Notificaciones) ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart'; // Importante para Firebase

// --- Imports de Notificaciones Locales ---
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// --- Imports de Utilidades (intl) y Supabase ---
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

// --- Imports de tus pantallas ---
// (Asegúrate de que estos archivos existan en tu proyecto)
import 'package:kine_app/features/home_screen.dart';
import 'package:kine_app/features/splash_screen.dart'; // Asumo que WelcomeScreen está aquí

// ===================================================================
// 1. CONFIGURACIÓN DE NOTIFICACIONES (del Archivo 1)
// ===================================================================

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Asegúrate de inicializar Firebase aquí también, usando las options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling a background message: ${message.messageId}");
}

// Plugin de notificaciones locales
final FlutterLocalNotificationsPlugin _localNotifs =
    FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'kine_channel', // id
  'Notificaciones Kine', // nombre visible
  description: 'Alertas de ejercicios, citas y mensajes',
  importance: Importance.defaultImportance,
);

// Función de inicialización para notificaciones locales
Future<void> _initLocalNotifications() async {
  const AndroidInitializationSettings androidInit =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosInit = DarwinInitializationSettings();

  await _localNotifs.initialize(
    const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  // Crear canal en Android
  await _localNotifs
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(_androidChannel);
}

// ===================================================================
// 2. FUNCIÓN main() FUSIONADA
// ===================================================================

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Inicialización de Firebase (del Archivo 2, con options) ---
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // --- Inicialización de intl (del Archivo 2) ---
  await initializeDateFormatting('es_ES', null);

  // --- Inicialización de Supabase (del Archivo 2) ---
  await sb.Supabase.initialize(
    url: 'https://gwnbsjunvxiexmqpthkv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd3bmJzanVudnhpZXhtcXB0aGt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxOTE3NTEsImV4cCI6MjA3NDc2Nzc1MX0.ZpQIlCgkRYr7SwDY7mtWHqTsgiOzsDqciXSvqugBk8U',
  );
  // Nota: La segunda llamada a initializeDateFormatting en tu Archivo 2 era redundante.

  // --- Configuración de Notificaciones (del Archivo 1) ---

  // 3) Background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 4) Permisos de notificación
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, sound: true, badge: true);

  // 5) iOS: mostrar notificaciones cuando la app está en foreground
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  // 6) Init locales
  await _initLocalNotifications();

  runApp(const MyApp());
}

// ===================================================================
// 3. WIDGET MyApp FUSIONADO (Stateful + Listeners + Auth Stream)
// ===================================================================

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // --- Lógica de Listeners de Notificaciones (del Archivo 1) ---
  @override
  void initState() {
    super.initState();

    // 7) Listener para notificaciones en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notif = message.notification;
      if (notif != null) {
        _localNotifs.show(
          notif.hashCode,
          notif.title,
          notif.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'kine_channel', // Mismo ID de canal que el creado arriba
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

    // 8) Tocar notificación cuando la app está en background y se abre
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notificación tocada (background): ${message.data}");
      _handleNotificationTap(message.data);
    });

    // 9) Si la app se abrió desde terminada por una notificación
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        print("Notificación tocada (terminada): ${message.data}");
        _handleNotificationTap(message.data);
      }
    });
  }

  // --- Lógica de Navegación por Notificación (del Archivo 1) ---
  void _handleNotificationTap(Map<String, dynamic> data) {
    // IMPORTANTE:
    // Desde aquí no puedes navegar directamente con `Navigator.push(context, ...)`
    // porque este `context` es el raíz de la app (el de MaterialApp).
    // Necesitarás un GlobalKey<NavigatorState> o un sistema de manejo de
    // estado (como Riverpod/Bloc) para gestionar la navegación globalmente.
    // Por ahora, solo imprimiré los datos para que veas que funciona.

    final type = data['type'];
    print("Manejando toque de notificación. Tipo: $type, Data: $data");

    if (type == 'mensaje') {
      final chatWith = data['chatWith']; // id del otro usuario
      print("Navegar a ChatScreen con $chatWith");
      // Ejemplo con GlobalKey: navigatorKey.currentState?.push(...)
    } else if (type == 'cita') {
      print("Navegar a CitasScreen");
    } else if (type == 'recordatorio') {
      print("Navegar a ProgresoEjerciciosScreen");
    }
  }

  // --- Lógica de UI (del Archivo 2) ---
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // (Opcional) Aquí deberías poner tu GlobalKey si quieres navegar
      // navigatorKey: tuGlobalKey,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Puedes mostrar un splash screen más bonito aquí
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            // Usuario logeado
            return const HomeScreen();
          } else {
            // Usuario no logeado
            return const WelcomeScreen(); // Asegúrate de que este Widget exista
          }
        },
      ),
    );
  }
}

// --- CLASES DE EJEMPLO ---
// Si no tienes estas clases, el código fallará.
// Asegúrate de importarlas correctamente desde tus archivos.
// (Las comento porque tú las estás importando arriba)
/*
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Welcome Screen (Login/Register)')));
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Home')), body: Center(child: Text('Home Screen')));
  }
}
*/
