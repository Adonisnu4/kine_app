// Archivo: lib/services/user_service.dart (o el archivo que contiene esta función)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> updateKinePresentation({
  required String specialization,
  required String experience,
  required String presentation,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    throw Exception("Usuario no autenticado.");
  }

  // ⭐️ CAMBIO CRUCIAL: Apuntamos a la colección 'usuarios'
  final userDocRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId);

  // NOTA: 'experience' debe guardarse como el mismo tipo de dato que se lee (String o Number).
  // En tu base de datos (imagen) aparece como String ("5").
  await userDocRef.update({
    'specialization': specialization,
    'experience': experience,
    'carta_presentacion': presentation,
  });
}

Future<String?> getUserEmailById(String userId) async {
  try {
    // Lee el documento del usuario desde la colección 'usuarios'
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    if (doc.exists && doc.data() != null) {
      // Devuelve el valor del campo 'email'
      return doc.data()!['email'] as String?;
    }
    return null; // Retorna null si el usuario o el email no existen
  } catch (e) {
    print("Error obteniendo email para $userId: $e");
    return null; // Retorna null en caso de error
  }
}
