import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<String, dynamic>?> getUserData() async {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    return null;
  }

  DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId)
      .get();

  if (userDoc.exists) {
    final Map<String, dynamic> userData = userDoc.data()!;

    // 1. Obtener la referencia de documento
    final dynamic tipoUsuarioRef = userData['tipo_usuario'];

    // 2. Verificar que es una referencia de documento
    if (tipoUsuarioRef is DocumentReference) {
      // 3. Obtener el documento referenciado
      DocumentSnapshot<Map<String, dynamic>> tipoUsuarioDoc = await tipoUsuarioRef.get() as DocumentSnapshot<Map<String, dynamic>>;

      // 4. Si el documento existe, agregar el nombre a los datos del usuario
      if (tipoUsuarioDoc.exists) {
        userData['tipo_usuario_nombre'] = tipoUsuarioDoc.data()?['nombre'] ?? 'No especificado';
      } else {
        userData['tipo_usuario_nombre'] = 'Desconocido';
      }
    } else {
      userData['tipo_usuario_nombre'] = 'Desconocido';
    }

    return userData;
  } else {
    return null;
  }
}