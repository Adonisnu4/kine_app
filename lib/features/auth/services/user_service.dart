// Archivo: lib/services/user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ACTUALIZA LOS DATOS PROFESIONALES DEL KINESIÓLOGO
/*
  Esta función permite que un kinesiólogo actualice la información
  relacionada con su perfil profesional:
  - Especialización
  - Años de experiencia (o texto equivalente)
  - Carta de presentación para pacientes
  Los datos se guardan directamente en el documento del usuario en Firestore.
*/
Future<void> updateKinePresentation({
  required String specialization,
  required String experience,
  required String presentation,
}) async {
  // Obtiene el ID del usuario autenticado
  final userId = FirebaseAuth.instance.currentUser?.uid;

  if (userId == null) {
    throw Exception("Usuario no autenticado.");
  }

  // Referencia al documento del usuario en Firestore
  final userDocRef = FirebaseFirestore.instance
      .collection('usuarios')
      .doc(userId);

  // Actualiza los campos indicados
  await userDocRef.update({
    'specialization': specialization,
    'experience': experience,
    'carta_presentacion': presentation,
  });
}

// OBTIENE EL CORREO ELECTRÓNICO DE UN USUARIO POR SU ID
/*
  Retorna el correo electrónico del usuario cuyo ID es entregado.
  Se usa cuando otras funciones necesitan obtener el email de un usuario,
  por ejemplo: envío de notificaciones, mensajes o verificación.
  Si el usuario no existe, retorna null.
*/
Future<String?> getUserEmailById(String userId) async {
  try {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(userId)
        .get();

    // Verifica que exista y tenga datos
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

// NUEVA FUNCIÓN: OBTENER LISTA DE PACIENTES DE UN KINESIÓLOGO
/*
  Obtiene una lista de todos los pacientes que tienen o han tenido
  al menos una cita "confirmada" con el kinesiólogo actualmente autenticado.

  Uso principal:
  - Llenar listas de pacientes en la app del kine.
  - Filtrar pacientes reales con interacción previa.
  - Construir pantallas como "Mis pacientes".

  Flujo:
    1. Obtiene el ID del kine autenticado.
    2. Busca citas donde el campo "kineId" coincida con ese ID y el estado sea "confirmada".
    3. Extrae los IDs únicos de pacientes desde las citas.
    4. Busca los documentos de esos pacientes en Firestore.
    5. Devuelve una lista detallada con todos sus datos.
*/
Future<List<Map<String, dynamic>>> getKinePatients() async {
  // Obtiene el ID del kinesiólogo actualmente autenticado
  final String? currentKineId = FirebaseAuth.instance.currentUser?.uid;

  if (currentKineId == null) {
    print("getKinePatients: Kinesiólogo no autenticado.");
    return [];
  }

  print(
    "getKinePatients: Buscando citas confirmadas para Kine ID: $currentKineId",
  );

  try {
    // Buscar citas confirmadas asignadas al kinesiólogo
    final confirmedAppointments = await FirebaseFirestore.instance
        .collection('citas')
        .where('kineId', isEqualTo: currentKineId)
        .where('estado', isEqualTo: 'confirmada')
        .get();

    if (confirmedAppointments.docs.isEmpty) {
      print("getKinePatients: No se encontraron citas confirmadas.");
      return [];
    }

    print(
      "getKinePatients: ${confirmedAppointments.docs.length} citas confirmadas encontradas.",
    );

    // Obtiene IDs únicos de pacientes
    final Set<String> patientIds = confirmedAppointments.docs
        .map((doc) => doc.data()['pacienteId'] as String)
        .toSet();

    if (patientIds.isEmpty) {
      print("getKinePatients: No se pudieron extraer IDs de pacientes.");
      return [];
    }

    print("getKinePatients: IDs de pacientes únicos: ${patientIds.toList()}");

    // Consulta los documentos de los pacientes en Firestore
    final patientsSnapshot = await FirebaseFirestore.instance
        .collection('usuarios')
        .where(FieldPath.documentId, whereIn: patientIds.toList())
        .get();

    // Mapea los resultados y añade el ID de cada paciente
    final patientList = patientsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] =
          doc.id; // Se agrega el ID del documento para uso en UI o lógica

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
    return [];
  }
}
