// lib/services/appointment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Importa el modelo de Cita
import 'package:kine_app/features/Appointments/models/appointment.dart';

// Servicios auxiliares para obtener información del usuario
import 'package:kine_app/features/auth/services/get_user_data.dart';
import 'package:kine_app/features/auth/services/user_service.dart';

class AppointmentService {
  // Instancia de Firestore para consultas y escritura
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Instancia de FirebaseAuth para obtener el usuario autenticado
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Referencia directa a la colección "citas"
  final CollectionReference _citasCollection = FirebaseFirestore.instance
      .collection('citas');

  /// Verifica si un paciente ya tiene una cita PENDIENTE con un kinesiólogo.
  Future<bool> hasPendingAppointment(String pacienteId, String kineId) async {
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'pendiente')
        .limit(1)
        .get();

    // Retorna true si existe al menos un documento
    return query.docs.isNotEmpty;
  }

  /// Verifica si un paciente ya tiene una cita CONFIRMADA con un kinesiólogo.
  /// Solo considera citas que están en el futuro.
  Future<bool> hasConfirmedAppointmentWithKine(
    String pacienteId,
    String kineId,
  ) async {
    // Convierte el DateTime actual a Timestamp para Firestore
    final nowTimestamp = Timestamp.fromDate(DateTime.now());

    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'confirmada')
        .where('fechaCita', isGreaterThan: nowTimestamp)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  /// Verifica si un horario específico ya está ocupado.
  /// Se considera ocupado si hay una cita pendiente o confirmada en esa misma hora.
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

  /// Envía una solicitud de cita:
  /// - Valida fecha futura
  /// - Verifica que no esté tomada
  /// - Guarda en Firestore
  /// - Envía correo al kinesiólogo
  Future<void> requestAppointment({
    required String kineId,
    required String kineNombre,
    required DateTime fechaCita,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Valida que la cita no sea en el pasado ni a minutos del horario actual
    final nowWithBuffer = DateTime.now().add(const Duration(minutes: 5));
    if (fechaCita.isBefore(nowWithBuffer)) {
      throw Exception(
        'No puedes solicitar citas para un horario que ya ha pasado o está por comenzar.',
      );
    }

    // Valida que la hora no esté tomada
    if (await isSlotTaken(kineId, fechaCita)) {
      throw Exception('Esta hora ya no está disponible o fue reservada.');
    }

    // Obtiene datos del paciente
    final userData = await getUserData();
    final String pacienteNombre = userData?['nombre_completo'] ?? 'Paciente';
    final String? pacienteEmail = user.email;

    // Crea el documento en Firestore
    await _citasCollection.add({
      'pacienteId': user.uid,
      'pacienteNombre': pacienteNombre,
      'pacienteEmail': pacienteEmail,
      'kineId': kineId,
      'kineNombre': kineNombre,
      'fechaCita': Timestamp.fromDate(fechaCita),
      'estado': 'pendiente',
      'creadaEn': Timestamp.now(),
    });

    // Intenta enviar correo al kinesiólogo usando la colección "mail"
    try {
      final String? kineEmail = await getUserEmailById(kineId);

      if (kineEmail != null) {
        final String fechaFormateada = DateFormat(
          'EEEE d \'de\' MMMM, yyyy',
          'es_ES',
        ).format(fechaCita);

        final String horaFormateada = DateFormat(
          'HH:mm',
          'es_ES',
        ).format(fechaCita);

        await _firestore.collection('mail').add({
          'to': [kineEmail],
          'message': {
            'subject': 'Nueva Solicitud de Cita Recibida',
            'html':
                '''
              <p>Hola $kineNombre,</p>
              <p>Has recibido una nueva solicitud de cita:</p>
              <p>
                <b>Paciente:</b> $pacienteNombre (${pacienteEmail ?? 'email no disponible'})<br>
                <b>Fecha Solicitada:</b> $fechaFormateada<br>
                <b>Hora Solicitada:</b> $horaFormateada hrs.
              </p>
              <p>Revisa tu panel de citas para gestionarla.</p>
            ''',
          },
        });
      }
    } catch (e) {
      print('Error al intentar enviar correo al Kine: $e');
    }
  }

  /// Obtiene todas las citas para un kinesiólogo.
  /// Ordenadas por fecha de manera ascendente.
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

  /// Actualiza el estado de una cita (confirmada, denegada, cancelada)
  /// y envía correo de notificación al paciente.
  Future<void> updateAppointmentStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    // Valida que la cita aún no haya pasado
    final now = DateTime.now();
    if (appointment.fechaCitaDT.isBefore(now)) {
      final formattedTime = DateFormat(
        'dd/MM/yyyy HH:mm',
        'es_ES',
      ).format(appointment.fechaCitaDT);

      throw Exception(
        'La cita programada para $formattedTime ya ha pasado y no puede cambiar su estado.',
      );
    }

    // Actualiza el estado en Firestore
    await _citasCollection.doc(appointment.id).update({'estado': newStatus});

    // Prepara textos comunes
    final fechaFormateada = DateFormat(
      'EEEE d \'de\' MMMM, yyyy',
      'es_ES',
    ).format(appointment.fechaCitaDT);
    final horaFormateada = DateFormat(
      'HH:mm',
      'es_ES',
    ).format(appointment.fechaCitaDT);

    String emailSubject = '';
    String emailHtmlBody = '';

    // Construye el contenido del correo según el nuevo estado
    if (newStatus == 'confirmada') {
      emailSubject = '¡Tu cita ha sido confirmada!';
      emailHtmlBody =
          '''
        <p>Hola ${appointment.pacienteNombre},</p>
        <p>Tu cita con <b>${appointment.kineNombre}</b> ha sido confirmada.</p>
        <p>
          <b>Fecha:</b> $fechaFormateada<br>
          <b>Hora:</b> $horaFormateada hrs.
        </p>
      ''';
    } else if (newStatus == 'denegada') {
      emailSubject = 'Actualización sobre tu solicitud de cita';
      emailHtmlBody =
          '''
        <p>Hola ${appointment.pacienteNombre},</p>
        <p>Tu solicitud de cita fue rechazada.</p>
        <p>
          <b>Fecha:</b> $fechaFormateada<br>
          <b>Hora:</b> $horaFormateada hrs.
        </p>
      ''';
    } else if (newStatus == 'cancelada') {
      emailSubject = 'Importante: Cancelación de tu Cita';
      emailHtmlBody =
          '''
        <p>Hola ${appointment.pacienteNombre},</p>
        <p>Tu cita fue cancelada por el profesional.</p>
        <p>
          <b>Fecha:</b> $fechaFormateada<br>
          <b>Hora:</b> $horaFormateada hrs.
        </p>
      ''';
    }

    // Envía correo al paciente si corresponde
    if (emailSubject.isNotEmpty &&
        emailHtmlBody.isNotEmpty &&
        appointment.pacienteEmail != null) {
      try {
        await _firestore.collection('mail').add({
          'to': [appointment.pacienteEmail],
          'message': {'subject': emailSubject, 'html': emailHtmlBody},
        });
      } catch (e) {
        print('Error al enviar correo de estado ($newStatus) al paciente: $e');
      }
    }
  }

  /// Obtiene todas las citas del paciente actual.
  /// Ordenadas por fecha de creación de manera descendente.
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

  /// Elimina una cita según su ID.
  Future<void> deleteAppointment(String appointmentId) {
    return _citasCollection.doc(appointmentId).delete();
  }

  /// Obtiene el historial de citas entre un kinesiólogo y un paciente específico.
  Stream<List<Appointment>> getAppointmentHistory(
    String kineId,
    String pacienteId,
  ) {
    return _citasCollection
        .where('kineId', isEqualTo: kineId)
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('fechaCita', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList(),
        );
  }
}
