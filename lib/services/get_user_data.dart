import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>?> getUserData() async {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return null;
  }

  DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
      .instance
      .collection('usuarios')
      .doc(userId)
      .get();

  if (userDoc.exists) {
    final Map<String, dynamic> userData = userDoc.data()!;

    final dynamic tipoUsuarioRef = userData['tipo_usuario'];

    if (tipoUsuarioRef is DocumentReference) {
      DocumentSnapshot<Map<String, dynamic>> tipoUsuarioDoc =
          await tipoUsuarioRef.get() as DocumentSnapshot<Map<String, dynamic>>;

      if (tipoUsuarioDoc.exists) {
        final tipoData = tipoUsuarioDoc.data();

        userData['tipo_usuario_nombre'] =
            tipoData?['nombre'] ?? 'No especificado';

        final id = tipoData?['id'];

        // ************************************************
        // ********** CAMBIO CLAVE DE LECTURA DE ID *******
        // ************************************************
        if (id != null) {
          // Intentamos leer el ID asegurando que sea un entero.
          if (id is num) {
            // Si es un número (int o double), lo convertimos a entero.
            userData['tipo_usuario_id'] = id.toInt();
          } else {
            // Si no es un número (ej. String por error), usamos 1.
            userData['tipo_usuario_id'] = 1;
          }
        } else {
          // Si el campo 'id' no existe en el documento de rol, usamos 1.
          userData['tipo_usuario_id'] = 1;
        }
      } else {
        userData['tipo_usuario_nombre'] = 'Desconocido (Ref no encontrada)';
        userData['tipo_usuario_id'] = 1;
      }
    } else {
      userData['tipo_usuario_nombre'] = 'Desconocido (No es Referencia)';
      userData['tipo_usuario_id'] = 1;
    }

    return userData;
  } else {
    return null;
  }
}
