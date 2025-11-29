// lib/services/get_user_data.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Obtiene los datos completos del usuario autenticado desde Firestore.
/// Incluye resolución del campo "tipo_usuario", que puede almacenarse
/// como una referencia a otro documento dentro de la colección tipo_usuario.
///
/// Retorna:
/// - Un Map<String, dynamic> con todos los datos del usuario, incluyendo:
///   * tipo_usuario_id    → ID numérico del rol (1, 2, 3)
///   * tipo_usuario_nombre → Nombre del rol según Firestore
/// - Null si el usuario no está autenticado o el documento no existe.
Future<Map<String, dynamic>?> getUserData() async {
  // Obtiene el UID del usuario autenticado actualmente
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  print('--- DEBUG getUserData (v2) ---');
  print('1. Current User ID: $userId');

  // Si no existe usuario autenticado, no es posible continuar
  if (userId == null) {
    print('ERROR: Usuario no autenticado (UID es nulo). Saliendo.');
    return null;
  }

  try {
    // Intenta leer el documento del usuario desde la colección "usuarios"
    print('2. Intentando leer documento: usuarios/$userId');
    DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
        .instance
        .collection('usuarios')
        .doc(userId)
        .get();

    // Verifica si el documento existe
    if (userDoc.exists) {
      // Se obtiene una copia mutable de los datos del usuario
      final Map<String, dynamic> userData = Map<String, dynamic>.from(
        userDoc.data()!,
      );

      print('3. Documento del usuario encontrado.');

      // Campo donde Firestore guarda la referencia al tipo de usuario
      final dynamic tipoUsuarioRef = userData['tipo_usuario'];

      print('4. Valor del campo "tipo_usuario": $tipoUsuarioRef');
      print('5. Tipo del campo "tipo_usuario": ${tipoUsuarioRef.runtimeType}');

      // Inicialización por defecto del rol en caso de error o ausencia
      int finalTipoId = 1; // Paciente
      String finalTipoNombre = 'Desconocido';

      // Verifica que el campo sea realmente una referencia a documento
      if (tipoUsuarioRef is DocumentReference) {
        print('Es una DocumentReference.');

        // Obtiene el ID del documento a partir de la ruta
        final String path = tipoUsuarioRef.path;
        final String docIdString = path.split('/').last;

        // Convierte el ID a entero o utiliza 1 si falla la conversión
        finalTipoId = int.tryParse(docIdString) ?? 1;

        print('6. Referencia apunta a: $path');
        print('7. ID de Rol extraído: $finalTipoId');

        // Intenta leer el documento del rol para obtener su nombre
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
      }
      // Si el campo no es una referencia válida
      else {
        print('ERROR: El campo "tipo_usuario" NO es una DocumentReference.');
        finalTipoId = 1;
        finalTipoNombre = 'Tipo Incorrecto';
      }

      // Inserta los datos procesados del tipo de usuario en el mapa final
      userData['tipo_usuario_id'] = finalTipoId;
      userData['tipo_usuario_nombre'] = finalTipoNombre;

      print('Preparando para devolver userData:');
      print('   -> tipo_usuario_id a devolver: ${userData['tipo_usuario_id']}');
      print(
        '   -> tipo_usuario_nombre a devolver: ${userData['tipo_usuario_nombre']}',
      );

      // Retorna el mapa del usuario con los campos adicionales
      return userData;
    }
    // El documento no existe
    else {
      print('ERROR: Documento del usuario usuarios/$userId NO existe.');
      return null;
    }
  }
  // Manejo de errores generales
  catch (e) {
    print('ERROR GENERAL en getUserData: $e');
    return null;
  }
  // Bloque que se ejecuta siempre
  finally {
    print('--- FIN DEBUG getUserData (v2) ---');
  }
}
