import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Servicio encargado de registrar y eliminar tokens FCM
/// pertenecientes a un usuario autenticado.
/// Este servicio permite que Firestore mantenga una lista actualizada
/// de los dispositivos asociados a cada usuario para enviarles notificaciones.
class PushTokenService {
  // Instancia de Firebase Messaging para obtener tokens FCM.
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  // Acceso a Firestore para leer y actualizar documentos de usuarios.
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTRO DEL TOKEN FCM
  /// Obtiene el token FCM del dispositivo actual y lo almacena en el documento
  /// del usuario dentro del campo "deviceTokens".
  /// Firestore lo guarda como un array, lo que permite soportar múltiples
  /// dispositivos por usuario. FieldValue.arrayUnion garantiza que no se
  /// dupliquen valores.
  Future<void> registerTokenForUser(String uid) async {
    try {
      // Obtiene el token FCM generado por el dispositivo actual.
      final token = await _fcm.getToken();
      if (token == null) return;

      // Agrega el token en el documento del usuario.
      await _firestore.collection('usuarios').doc(uid).update({
        'deviceTokens': FieldValue.arrayUnion([token]),
      });

      print("Token FCM guardado para usuario $uid");
    } catch (e) {
      print("Error guardando token FCM: $e");
    }
  }

  // ELIMINACIÓN DEL TOKEN FCM

  /// Elimina el token FCM actual del usuario.
  /// Este proceso suele realizarse durante el cierre de sesión para evitar que
  /// un usuario que ya no está autenticado continúe recibiendo notificaciones
  /// en este mismo dispositivo.
  Future<void> removeTokenForUser(String uid) async {
    try {
      // Obtiene el token actual del dispositivo para poder eliminarlo.
      final token = await _fcm.getToken();
      if (token == null) return;

      // Remueve el token del array deviceTokens.
      await _firestore.collection('usuarios').doc(uid).update({
        'deviceTokens': FieldValue.arrayRemove([token]),
      });

      print("Token FCM eliminado para usuario $uid");
    } catch (e) {
      print("Error eliminando token FCM: $e");
    }
  }
}
