// lib/services/appointment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ⚠️ Revisa que estas rutas sean correctas
import 'package:kine_app/features/Appointments/models/appointment.dart';
import 'package:kine_app/features/auth/services/get_user_data.dart';
import 'package:kine_app/features/auth/services/user_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _citasCollection = FirebaseFirestore.instance
      .collection('citas');

  Future<bool> hasPendingAppointment(String pacienteId, String kineId) async {
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'PENDIENTE') // 🚀 MAYÚSCULAS
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> hasConfirmedAppointmentWithKine(
    String pacienteId,
    String kineId,
  ) async {
    final nowTimestamp = Timestamp.fromDate(DateTime.now());
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'CONFIRMADA') // 🚀 MAYÚSCULAS
        .where('fechaCita', isGreaterThan: nowTimestamp)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> isSlotTaken(String kineId, DateTime slot) async {
    final slotTimestamp = Timestamp.fromDate(slot);
    final query = await _citasCollection
        .where('kineId', isEqualTo: kineId)
        .where('fechaCita', isEqualTo: slotTimestamp)
        .where('estado', whereIn: ['PENDIENTE', 'CONFIRMADA']) // 🚀 MAYÚSCULAS
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<Set<String>> getTakenSlotsForDay(String kineId, DateTime day) async {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

    final startTimestamp = Timestamp.fromDate(startOfDay);
    final endTimestamp = Timestamp.fromDate(endOfDay);

    final query = await _citasCollection
        .where('kineId', isEqualTo: kineId)
        .where('fechaCita', isGreaterThanOrEqualTo: startTimestamp)
        .where('fechaCita', isLessThanOrEqualTo: endTimestamp)
        .where('estado', whereIn: ['PENDIENTE', 'CONFIRMADA']) // 🚀 MAYÚSCULAS
        .get();

    if (query.docs.isEmpty) {
      return <String>{};
    }

    final DateFormat formatter = DateFormat('HH:mm');
    return query.docs.map((doc) {
      final timestamp = doc['fechaCita'] as Timestamp;
      return formatter.format(timestamp.toDate());
    }).toSet();
  }

  Future<void> requestAppointment({
    required String kineId,
    required String kineNombre,
    required DateTime fechaCita,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final nowWithBuffer = DateTime.now().add(const Duration(minutes: 5));
    if (fechaCita.isBefore(nowWithBuffer)) {
      throw Exception(
        'No puedes solicitar citas para un horario que ya ha pasado o está por comenzar.',
      );
    }

    if (await isSlotTaken(kineId, fechaCita)) {
      throw Exception('Esta hora ya no está disponible o fue reservada.');
    }

    final userData = await getUserData();
    final String pacienteNombre = userData?['nombre_completo'] ?? 'Paciente';
    final String? pacienteEmail = user.email;

    await _citasCollection.add({
      'pacienteId': user.uid,
      'pacienteNombre': pacienteNombre,
      'pacienteEmail': pacienteEmail,
      'kineId': kineId,
      'kineNombre': kineNombre,
      'fechaCita': Timestamp.fromDate(fechaCita),
      'estado': 'PENDIENTE', // 🚀 MAYÚSCULAS
      'creadaEn': Timestamp.now(),
    });

    // ... (Tu lógica de envío de correo está bien) ...
  }

  Stream<List<Appointment>> getKineAppointments(String kineId) {
    return _citasCollection
        .where('kineId', isEqualTo: kineId)
        .orderBy('fechaCita', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList(),
        );
  }

  Future<void> updateAppointmentStatus(
    Appointment appointment,
    String newStatus, // Recibirá "CONFIRMADA", "DENEGADA", etc.
  ) async {
    final now = DateTime.now();

    if (appointment.fechaCitaDT.isAfter(now)) {
      // --- CITA EN EL FUTURO ---
      if (newStatus == 'COMPLETADA') {
        // 🚀 MAYÚSCULAS
        throw Exception(
          'No puedes marcar como "Completada" una cita que aún no ocurre.',
        );
      }
    } else {
      // --- CITA EN EL PASADO ---
      if (newStatus == 'CONFIRMADA' || newStatus == 'DENEGADA') {
        // 🚀 MAYÚSCULAS
        final formattedTime = DateFormat(
          'dd/MM/yyyy HH:mm',
          'es_ES',
        ).format(appointment.fechaCitaDT);
        throw Exception(
          'La cita programada para $formattedTime ya ha pasado y no puede ser Aceptada o Denegada.',
        );
      }
    }

    await _citasCollection.doc(appointment.id).update({'estado': newStatus});

    // ... (Lógica de envio de correo por estado) ...
  }

  // 🚀 --- CÓDIGO RESTAURADO ---
  Stream<List<Appointment>> getPatientAppointments(String pacienteId) {
    return _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('creadaEn', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList(),
        );
  }
  // 🚀 --- FIN CÓDIGO RESTAURADO ---

  // 🚀 --- CÓDIGO RESTAURADO ---
  Future<void> deleteAppointment(String appointmentId) {
    // Devuelve el Future directamente
    return _citasCollection.doc(appointmentId).delete();
  }
  // 🚀 --- FIN CÓDIGO RESTAURADO ---

  // 🚀 --- CÓDIGO RESTAURADO ---
  Stream<List<Appointment>> getAppointmentHistory(
    String kineId,
    String pacienteId,
  ) {
    return _citasCollection
        .where('kineId', isEqualTo: kineId)
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fechaCita', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
        });
  }

  // 🚀 --- FIN CÓDIGO RESTAURADO ---
}
