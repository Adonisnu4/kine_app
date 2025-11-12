// lib/services/get_user_data.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>?> getUserData() async {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  print('--- DEBUG getUserData (v2) ---');
  print('1. Current User ID: $userId');

  if (userId == null) {
    print('ERROR: Usuario no autenticado (UID es nulo). Saliendo.');
    return null;
  }

  try {
    print('2. Intentando leer documento: usuarios/$userId');
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('usuarios')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      // Get a mutable copy of the data
      final Map<String, dynamic> userData = Map<String, dynamic>.from(
        userDoc.data()!,
      );
      print('3. Documento del usuario encontrado.');

      final dynamic tipoUsuarioRef = userData['tipo_usuario'];
      print('4. Valor del campo "tipo_usuario": $tipoUsuarioRef');
      print('5. Tipo del campo "tipo_usuario": ${tipoUsuarioRef.runtimeType}');

      int finalTipoId = 1; // Default to 1 (Patient)
      String finalTipoNombre = 'Desconocido';

      if (tipoUsuarioRef is DocumentReference) {
        print('Es una DocumentReference.');
        final String path = tipoUsuarioRef.path;
        final String docIdString = path.split('/').last;
        finalTipoId =
            int.tryParse(docIdString) ?? 1; // Extract ID, fallback to 1

        print('6. Referencia apunta a: $path');
        print('7. ID de Rol extraído: $finalTipoId');

        // Try to read the role name (secondary)
        try {
          print('8. Intentando leer documento de Rol: $path');
          DocumentSnapshot tipoUsuarioDoc = await tipoUsuarioRef.get();
          if (tipoUsuarioDoc.exists) {
            final tipoData = tipoUsuarioDoc.data() as Map<String, dynamic>?;
            print('Documento de Rol encontrado.');
            finalTipoNombre = tipoData?['nombre'] ?? 'Nombre no encontrado';
          } else {
            print('Documento de Rol ($path) NO EXISTE en Firestore.');
            finalTipoNombre = 'Rol no existe';
          }
        } catch (e) {
          print('ERROR al leer el documento de Rol ($path): $e');
          finalTipoNombre = 'Error al leer rol';
        }
      } else {
        // Field is NOT a reference
        print('ERROR: El campo "tipo_usuario" NO es una DocumentReference.');
        finalTipoId = 1; // Explicitly set fallback ID
        finalTipoNombre = 'Tipo Incorrecto';
      }

      // *** CRITICAL STEP: Add/Overwrite the ID and Name *before* returning ***
      userData['tipo_usuario_id'] = finalTipoId;
      userData['tipo_usuario_nombre'] = finalTipoNombre;

      print('Preparando para devolver userData:');
      print('   -> tipo_usuario_id a devolver: ${userData['tipo_usuario_id']}');
      print(
        '   -> tipo_usuario_nombre a devolver: ${userData['tipo_usuario_nombre']}',
      );
      return userData; // Return the modified map
    } else {
      print('ERROR: Documento del usuario usuarios/$userId NO existe.');
      return null;
    }
  } catch (e) {
    print('ERROR GENERAL en getUserData: $e');
    return null;
  } finally {
    print('--- FIN DEBUG getUserData (v2) ---');
  }
}
