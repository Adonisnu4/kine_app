// lib/services/appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/models/appointment.dart'; // Asegúrate que la ruta sea correcta
import 'package:kine_app/services/get_user_data.dart'; // Asegúrate que la ruta sea correcta
import 'package:intl/intl.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _citasCollection = FirebaseFirestore.instance
      .collection('citas');

  /// Revisa si el paciente YA tiene una cita pendiente
  Future<bool> hasPendingAppointment(String pacienteId) async {
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('estado', isEqualTo: 'pendiente')
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Revisa si un horario específico ya está ocupado
  Future<bool> isSlotTaken(String kineId, DateTime slot) async {
    final slotTimestamp = Timestamp.fromDate(slot);
    final query = await _citasCollection
        .where('kineId', isEqualTo: kineId)
        .where('fechaCita', isEqualTo: slotTimestamp)
        .where('estado', whereIn: ['pendiente', 'confirmada'])
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Crea la solicitud de cita
  Future<void> requestAppointment({
    required String kineId,
    required String kineNombre,
    required DateTime fechaCita,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    final userData = await getUserData();
    final String pacienteNombre = userData?['nombre_completo'] ?? 'Paciente';
    final String? pacienteEmail = user.email;

    final newAppointment = {
      'pacienteId': user.uid,
      'pacienteNombre': pacienteNombre,
      'pacienteEmail': pacienteEmail,
      'kineId': kineId,
      'kineNombre': kineNombre,
      'fechaCita': Timestamp.fromDate(fechaCita),
      'estado': 'pendiente', // Estado inicial
      'creadaEn': Timestamp.now(),
    };
    await _citasCollection.add(newAppointment);
  }

  /// Obtiene TODAS las citas para el Kine (para su panel)
  Stream<List<Appointment>> getKineAppointments(String kineId) {
    return _citasCollection
        .where('kineId', isEqualTo: kineId)
        .orderBy('fechaCita', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
        });
  }

  /// Actualiza el estado y envía correo si se confirma
  Future<void> updateAppointmentStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    // Actualiza el estado en Firestore
    await _citasCollection.doc(appointment.id).update({'estado': newStatus});

    // Si se confirma, intenta enviar correo
    if (newStatus == 'confirmada') {
      try {
        final String fechaFormateada = DateFormat(
          'EEEE d de MMMM, yyyy',
          'es_ES',
        ).format(appointment.fechaCitaDT);
        final String horaFormateada = DateFormat(
          'HH:mm',
          'es_ES',
        ).format(appointment.fechaCitaDT);

        // Escribe en la colección 'mail' para la extensión Trigger Email
        await _firestore.collection('mail').add({
          'to': [appointment.pacienteEmail],
          'message': {
            'subject': '¡Tu cita ha sido confirmada!',
            'html':
                '''
              <p>Hola ${appointment.pacienteNombre},</p>
              <p>Tu cita con <b>${appointment.kineNombre}</b> ha sido <b>confirmada</b>.</p>
              <p>Te esperamos el día:</p>
              <p>
                <b>Fecha:</b> $fechaFormateada<br>
                <b>Hora:</b> $horaFormateada hrs.
              </p>
            ''',
          },
        });
      } catch (e) {
        print('Error al intentar enviar el correo de confirmación: $e');
      }
    }
  }

  /// **NUEVO:** Obtiene TODAS las citas para el PACIENTE
  Stream<List<Appointment>> getPatientAppointments(String pacienteId) {
    return _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy(
          'creadaEn',
          descending: true,
        ) // Ordena por más recientes primero
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
        });
  }

  /// **NUEVO:** Elimina una cita (usado por el paciente para cancelar)
  Future<void> deleteAppointment(String appointmentId) {
    return _citasCollection.doc(appointmentId).delete();
  }
} // Fin de la clase AppointmentService
