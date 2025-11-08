import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushTokenService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Guarda o actualiza el token FCM del usuario logueado
  Future<void> registerTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await _firestore.collection('usuarios').doc(uid).update({
        'deviceTokens': FieldValue.arrayUnion([token]),
      });

      print("✅ Token FCM guardado para usuario $uid");
    } catch (e) {
      print("❌ Error guardando token FCM: $e");
    }
  }

  // Opcional: elimina el token si el usuario cierra sesión
  Future<void> removeTokenForUser(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      await _firestore.collection('usuarios').doc(uid).update({
        'deviceTokens': FieldValue.arrayRemove([token]),
      });

      print("🧹 Token FCM eliminado para usuario $uid");
    } catch (e) {
      print("❌ Error eliminando token FCM: $e");
    }
  }
}
