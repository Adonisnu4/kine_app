import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Servicio encargado de registrar, actualizar y eliminar tokens FCM
/// para recibir notificaciones push.
class PushTokenService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registra el token FCM del usuario actual en Firestore
  Future<void> registerTokenForUser(String userId) async {
    try {
      // 🔹 1. Solicita permisos (importante en Android 13+ e iOS)
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('🚫 Usuario denegó permisos de notificaciones');
        return;
      }

      // 🔹 2. Obtiene el token del dispositivo
      final token = await _fcm.getToken();
      if (token == null) {
        print('⚠️ No se pudo obtener el token FCM');
        return;
      }

      print('✅ Token FCM obtenido: $token');

      final ref = _firestore.collection('usuarios').doc(userId);

      // 🔹 3. Guarda el token en Firestore (array para soportar varios dispositivos)
      await ref.set({
        'deviceTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      // 🔹 4. Escucha cambios del token (renovación automática)
      _fcm.onTokenRefresh.listen((newToken) async {
        print('🔄 Token FCM actualizado: $newToken');
        await ref.update({
          'deviceTokens': FieldValue.arrayUnion([newToken]),
        });
      });
    } catch (e) {
      print('❌ Error registrando token FCM: $e');
    }
  }

  /// Elimina el token FCM del usuario (por ejemplo, al cerrar sesión)
  Future<void> removeTokenForUser(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token == null) return;

      final ref = _firestore.collection('usuarios').doc(userId);
      await ref.update({
        'deviceTokens': FieldValue.arrayRemove([token]),
      });

      print('🧹 Token FCM eliminado para usuario $userId');
    } catch (e) {
      print('❌ Error eliminando token FCM: $e');
    }
  }
}
