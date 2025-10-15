// Archivo: lib/services/get_user_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>?> getUserData() async {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    print('❌ DIAGNÓSTICO: Usuario no autenticado (UID es nulo).');
    return null;
  }

  print('✅ DIAGNÓSTICO: Intentando leer documento para UID: $userId');
  DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
      .instance
      .collection('usuarios')
      .doc(userId)
      .get();

  if (userDoc.exists) {
    final Map<String, dynamic> userData = userDoc.data()!;
    print(
      '✅ DIAGNÓSTICO: Documento del usuario existe. Data keys: ${userData.keys}',
    );

    final dynamic tipoUsuarioRef = userData['tipo_usuario'];

    if (tipoUsuarioRef is DocumentReference) {
      // 1. Obtener el ID del tipo de usuario de la ruta de la referencia
      final String path = tipoUsuarioRef.path;
      final String docIdString = path.split('/').last;

      final int finalTipoId =
          int.tryParse(docIdString) ??
          1; // Asignación de ID (puede ser 1 si falla el parseo)

      print(
        '✅ DIAGNÓSTICO: Campo tipo_usuario es una Referencia. Ruta: $path. ID extraído: $finalTipoId',
      );

      // 2. Intentar leer el documento de la referencia (ESTE ES EL PUNTO MÁS PROBABLE DE FALLA)
      DocumentSnapshot<Map<String, dynamic>> tipoUsuarioDoc;
      try {
        tipoUsuarioDoc =
            await tipoUsuarioRef.get()
                as DocumentSnapshot<Map<String, dynamic>>;
        print('✅ DIAGNÓSTICO: Lectura del documento de Rol/Tipo exitosa.');
      } catch (e) {
        // Esto puede capturar errores de seguridad (Reglas) o problemas de red.
        print(
          '❌ DIAGNÓSTICO: ERROR CATCHEADO AL LEER REFERENCIA (${tipoUsuarioRef.path}): $e',
        );
        userData['tipo_usuario_nombre'] =
            'Desconocido (Error de Lectura/Reglas)';
        userData['tipo_usuario_id'] = 1;
        return userData; // Retornamos temprano para ver el error
      }

      if (tipoUsuarioDoc.exists) {
        final tipoData = tipoUsuarioDoc.data();

        userData['tipo_usuario_nombre'] =
            tipoData?['nombre'] ?? 'No especificado';
        userData['tipo_usuario_id'] = finalTipoId; // Usamos el ID de la ruta
      } else {
        // La lectura fue exitosa, pero el documento 'tipo_usuario/3' NO EXISTE.
        print(
          '❌ DIAGNÓSTICO: Documento de Rol (${tipoUsuarioRef.path}) NO EXISTE en Firestore.',
        );
        userData['tipo_usuario_nombre'] = 'Desconocido (Ref no encontrada)';
        userData['tipo_usuario_id'] = 1; // 👈 ¡FALLBACK!
      }
    } else {
      // El campo 'tipo_usuario' no es una DocumentReference.
      print(
        '❌ DIAGNÓSTICO: Campo tipo_usuario NO es una DocumentReference, es: ${tipoUsuarioRef.runtimeType}',
      );
      userData['tipo_usuario_nombre'] = 'Desconocido (No es Referencia)';
      userData['tipo_usuario_id'] = 1; // 👈 ¡FALLBACK!
    }

    return userData;
  } else {
    print('❌ DIAGNÓSTICO: Documento del usuario NO existe.');
    return null;
  }
}
