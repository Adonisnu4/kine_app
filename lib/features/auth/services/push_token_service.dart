import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushTokenService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // 🔥 1. Guarda o actualiza el token FCM del usuario
  // ============================================================
  Future<void> saveToken(String uid) async {
    try {
      // Pedir permisos (Android 13+)
      await _fcm.requestPermission(alert: true, badge: true, sound: true);

      final token = await _fcm.getToken();
      print("🔥 TOKEN ACTUAL: $token");

      if (token == null) return;

      await _firestore.collection('usuarios').doc(uid).update({
        "deviceTokens": FieldValue.arrayUnion([token]),
      });

      print("✅ Token guardado en Firestore");
    } catch (e) {
      print("❌ Error guardando token: $e");
    }
  }

  // ============================================================
  // ♻️ 2. Escucha cambios del token (cuando se renueva)
  // ============================================================
  void listenTokenChanges(String uid) {
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      print("♻️ TOKEN RENOVADO: $token");
      _firestore.collection("usuarios").doc(uid).update({
        "deviceTokens": FieldValue.arrayUnion([token]),
      });
    });
  }

  // ============================================================
  // 🧹 3. Eliminar token cuando el usuario cierra sesión
  // ============================================================
  Future<void> removeToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await _firestore.collection("usuarios").doc(uid).update({
        "deviceTokens": FieldValue.arrayRemove([token]),
      });

      print("🧹 Token eliminado correctamente");
    } catch (e) {
      print("❌ Error eliminando token: $e");
    }
  }
}
