import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Servicio encargado de administrar tokens de Firebase Cloud Messaging (FCM)
/// asociados a cada usuario.
/// Este servicio permite:
/// - Registrar un token FCM del usuario.
/// - Mantener sincronizados los tokens cuando se actualizan.
/// - Eliminar el token del usuario al cerrar sesión.
/// Los tokens se almacenan dentro del documento del usuario en el campo:
///    usuarios/{uid}/deviceTokens: [token1, token2, ...]
/// Esto permite soportar múltiples dispositivos por usuario.
class PushTokenService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Registra el token FCM del usuario indicado.
  /// Este método realiza las siguientes operaciones:
  /// Solicita permisos de notificaciones (iOS y Android 13+).
  /// Obtiene el token FCM actual del dispositivo.
  /// Guarda el token dentro del documento del usuario en Firestore.
  /// Registra un listener que actualiza automáticamente el token cuando Firebase lo renueva.
  Future<void> registerTokenForUser(String userId) async {
    try {
      // Solicita permisos para recibir notificaciones.
      // Esto es obligatorio en iOS y Android 13 o superior.
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Si el usuario deniega permisos, no es posible registrar el token.
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('Permisos de notificación denegados por el usuario.');
        return;
      }

      // Obtiene el token único del dispositivo generado por FCM.
      final token = await _fcm.getToken();
      if (token == null) {
        print('No se pudo obtener un token FCM válido.');
        return;
      }

      print('Token FCM obtenido correctamente: $token');

      final ref = _firestore.collection('usuarios').doc(userId);

      // Agrega el token dentro del array "deviceTokens" del usuario.
      // arrayUnion evita duplicados y permite múltiples dispositivos.
      await ref.set({
        'deviceTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

      // Escucha cambios futuros del token.
      // Firebase puede renovar el token en cualquier momento por motivos de seguridad,
      // por lo que esta suscripción garantiza que los tokens nuevos también se almacenen.
      _fcm.onTokenRefresh.listen((newToken) async {
        print('Token FCM actualizado automáticamente: $newToken');
        await ref.update({
          'deviceTokens': FieldValue.arrayUnion([newToken]),
        });
      });
    } catch (e) {
      print('Error al registrar el token FCM: $e');
    }
  }

  /// Elimina el token FCM actual del usuario.
  /// Se utiliza normalmente durante el cierre de sesión para evitar que un usuario
  /// que ya no está autenticado siga recibiendo notificaciones en ese dispositivo.
  Future<void> removeTokenForUser(String userId) async {
    try {
      // Obtiene el token del dispositivo actual para poder eliminarlo.
      final token = await _fcm.getToken();
      if (token == null) return;

      final ref = _firestore.collection('usuarios').doc(userId);

      // Elimina el token de la lista almacenada en Firestore.
      await ref.update({
        'deviceTokens': FieldValue.arrayRemove([token]),
      });

      print('Token FCM eliminado para el usuario $userId');
    } catch (e) {
      print('Error al eliminar el token FCM: $e');
    }
  }
}
