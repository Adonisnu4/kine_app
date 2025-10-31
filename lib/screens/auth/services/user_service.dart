// Archivo: lib/services/user_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Tu función existente ---
Future<void> updateKinePresentation({
  required String specialization,
  required String experience,
  required String presentation,
}) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    throw Exception("Usuario no autenticado.");
  }

  final userDocRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId);

  await userDocRef.update({
    'specialization': specialization,
    'experience':
        experience, // Asegúrate que el tipo coincida (String vs Number)
    'carta_presentacion': presentation,
  });
}

// --- Tu función existente ---
Future<String?> getUserEmailById(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();
    if (doc.exists && doc.data() != null) {
      return doc.data()!['email'] as String?;
    }
    print("getUserEmailById: Documento no encontrado para ID $userId");
    return null;
  } catch (e) {
    print("Error en getUserEmailById para $userId: $e");
    return null;
  }
}

// --- 👇 NUEVA FUNCIÓN AÑADIDA 👇 ---
/// Obtiene la lista de pacientes únicos que tienen o han tenido
/// al menos una cita CONFIRMADA con el Kinesiólogo actualmente logueado.
Future<List<Map<String, dynamic>>> getKinePatients() async {
  // Obtiene el ID del Kine logueado
  final String? currentKineId = FirebaseAuth.instance.currentUser?.uid;
  if (currentKineId == null) {
    print("getKinePatients: Kinesiólogo no autenticado.");
    return []; // Devuelve lista vacía si no está logueado
  }

  print(
    "getKinePatients: Buscando citas confirmadas para Kine ID: $currentKineId",
  );

  try {
    // 1. Busca citas confirmadas para este Kine
    final confirmedAppointments = await FirebaseFirestore.instance
        .collection('citas')
        .where('kineId', isEqualTo: currentKineId)
        .where('estado', isEqualTo: 'confirmada') // Solo confirmadas
        .get();
    // ⚠️ Requiere índice: kineId (Asc), estado (Asc)

    if (confirmedAppointments.docs.isEmpty) {
      print("getKinePatients: No se encontraron citas confirmadas.");
      return [];
    }
    print(
      "getKinePatients: ${confirmedAppointments.docs.length} citas confirmadas encontradas.",
    );

    // 2. Extrae IDs únicos de pacientes
    final Set<String> patientIds = confirmedAppointments.docs
        .map((doc) => doc.data()['pacienteId'] as String)
        .toSet();

    if (patientIds.isEmpty) {
      print("getKinePatients: No se pudieron extraer IDs de pacientes.");
      return [];
    }
    print("getKinePatients: IDs de pacientes únicos: ${patientIds.toList()}");

    // 3. Busca datos de esos pacientes en 'usuarios'
    final patientsSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where(FieldPath.documentId, whereIn: patientIds.toList())
        .get();

    // 4. Mapea resultados, añadiendo el ID del paciente
    final patientList = patientsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Añade el ID
      print(
        "getKinePatients: Datos encontrados para paciente ${doc.id}: ${data.keys}",
      );
      return data;
    }).toList();

    print(
      "getKinePatients: Devolviendo lista de ${patientList.length} pacientes.",
    );
    return patientList;
  } catch (e) {
    print("Error fatal en getKinePatients: $e");
    return []; // Devuelve lista vacía en caso de error
  }
}
// --- FIN NUEVA FUNCIÓN ---