// lib/services/appointment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// ⚠️ Ajusta estas rutas a tu estructura actual:
import 'package:kine_app/screens/Appointments/models/appointment.dart';
import 'package:kine_app/screens/auth/services/get_user_data.dart';
import 'package:kine_app/screens/auth/services/user_service.dart'; // Contiene getUserEmailById

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _citasCollection = FirebaseFirestore.instance
      .collection('citas');

  /// Revisa si el paciente YA tiene una cita pendiente.
  Future<bool> hasPendingAppointment(String pacienteId, String kineId) async {
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'pendiente')
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  /// Revisa si el paciente YA tiene una cita CONFIRMADA (futura).
  Future<bool> hasConfirmedAppointmentWithKine(
    String pacienteId,
    String kineId,
  ) async {
    // 🚀 LÓGICA AGREGADA: Solo considera citas confirmadas que están en el futuro.
    // La conversión a Timestamp es necesaria para usarla en la consulta de Firestore.
    final nowTimestamp = Timestamp.fromDate(DateTime.now());

    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'confirmada')
        .where(
          'fechaCita',
          isGreaterThan: nowTimestamp,
        ) // <--- ¡FILTRO CLAVE AGREGADO AQUÍ!
        .limit(1)
        .get();

    // NOTA: Esta consulta requiere un índice compuesto en Firestore:
    // (pacienteId ASC, kineId ASC, estado ASC, fechaCita ASC)

    return query.docs.isNotEmpty;
  }

  /// Revisa si un horario específico ya está ocupado.
  // ... (Esta función se mantiene igual) ...
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

  /// Crea la solicitud de cita e incluye la validación de tiempo.
  // ... (Esta función se mantiene igual, ya tiene la validación requestAppointment) ...
  Future<void> requestAppointment({
    required String kineId,
    required String kineNombre,
    required DateTime fechaCita,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Validación de tiempo: No se puede solicitar en el pasado.
    final nowWithBuffer = DateTime.now().add(const Duration(minutes: 5));
    if (fechaCita.isBefore(nowWithBuffer)) {
      throw Exception(
        'No puedes solicitar citas para un horario que ya ha pasado o está por comenzar.',
      );
    }

    // Validación de slot ocupado.
    if (await isSlotTaken(kineId, fechaCita)) {
      throw Exception('Esta hora ya no está disponible o fue reservada.');
    }

    // Datos del Paciente (usando las funciones importadas)
    final userData = await getUserData();
    final String pacienteNombre = userData?['nombre_completo'] ?? 'Paciente';
    final String? pacienteEmail = user.email;

    // Guarda cita en Firestore
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

    // Envía Correo al Kine (Lógica original)
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
              <p>Hola ${kineNombre},</p>
              <p>Has recibido una nueva solicitud de cita:</p>
              <p>
                <b>Paciente:</b> ${pacienteNombre} (${pacienteEmail ?? 'email no disponible'})<br>
                <b>Fecha Solicitada:</b> $fechaFormateada<br>
                <b>Hora Solicitada:</b> $horaFormateada hrs.
              </p>
              <p>Por favor, revisa tu panel de citas en la aplicación KineApp para gestionar esta solicitud.</p>
            ''',
          },
        });
      }
    } catch (e) {
      print('Error al intentar disparar correo de nueva solicitud al Kine: $e');
    }
  }

  /// Obtiene TODAS las citas para el Kine (para su panel).
  // ... (Esta función se mantiene igual) ...
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

  /// Actualiza el estado (confirmada, denegada, cancelada) Y ENVÍA EMAIL AL PACIENTE.
  // ... (Esta función se mantiene igual, ya tiene la validación updateAppointmentStatus) ...
  Future<void> updateAppointmentStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    // VALIDACIÓN AÑADIDA: Evitar cambiar el estado de citas que ya pasaron.
    final now = DateTime.now();
    if (appointment.fechaCitaDT.isBefore(now)) {
      final formattedTime = DateFormat(
        'dd/MM/yyyy HH:mm',
        'es_ES',
      ).format(appointment.fechaCitaDT);
      throw Exception(
        'La cita programada para $formattedTime ya ha pasado y no puede cambiar su estado (aceptar, denegar o cancelar).',
      );
    }

    // Actualiza el estado en Firestore
    await _citasCollection.doc(appointment.id).update({'estado': newStatus});

    // Prepara datos comunes para correo
    final String fechaFormateada = DateFormat(
      'EEEE d \'de\' MMMM, yyyy',
      'es_ES',
    ).format(appointment.fechaCitaDT);
    final String horaFormateada = DateFormat(
      'HH:mm',
      'es_ES',
    ).format(appointment.fechaCitaDT);
    String emailSubject = '';
    String emailHtmlBody = '';

    // Define contenido según estado
    if (newStatus == 'confirmada') {
      emailSubject = '¡Tu cita ha sido confirmada!';
      emailHtmlBody =
          '''
        <p>Hola ${appointment.pacienteNombre},</p>
        <p>¡Buenas noticias! Tu cita con <b>${appointment.kineNombre}</b> ha sido <b>confirmada</b>.</p>
        <p>Te esperamos el día:</p>
        <p>
          <b>Fecha:</b> $fechaFormateada<br>
          <b>Hora:</b> $horaFormateada hrs.
        </p>
        <p>Nos vemos pronto,<br>Equipo KineApp</p>
      ''';
    } else if (newStatus == 'denegada') {
      emailSubject = 'Actualización sobre tu solicitud de cita';
      emailHtmlBody =
          '''
        <p>Hola ${appointment.pacienteNombre},</p>
        <p>Te informamos que tu solicitud de cita con <b>${appointment.kineNombre}</b> para el día $fechaFormateada a las $horaFormateada hrs. ha sido <b>rechazada</b>.</p>
        <p>Esto puede deberse a la disponibilidad del profesional u otros motivos. Te recomendamos intentar solicitar otro horario disponible o contactar directamente al kinesiólogo a través del chat en la aplicación si tienes alguna consulta.</p>
        <p>Lamentamos cualquier inconveniente,<br>Equipo KineApp</p>
      ''';
    } else if (newStatus == 'cancelada') {
      emailSubject = 'Importante: Cancelación de tu Cita Programada';
      emailHtmlBody =
          '''
          <p>Hola ${appointment.pacienteNombre},</p>
          <p>Lamentamos informarte que tu cita con <b>${appointment.kineNombre}</b>, programada para el día $fechaFormateada a las $horaFormateada hrs., ha sido <b>cancelada por el profesional</b>.</p>
          <p>Esto se debe a problemas de fuerza mayor o disponibilidad. Por favor, revisa la aplicación para reagendar con el mismo o con otro kinesiólogo.</p>
          <p>Lamentamos cualquier inconveniente que esto pueda causarte,<br>Equipo KineApp</p>
        ''';
    }

    // Envía correo si aplica
    if (emailSubject.isNotEmpty &&
        emailHtmlBody.isNotEmpty &&
        appointment.pacienteEmail != null) {
      try {
        await _firestore.collection('mail').add({
          'to': [appointment.pacienteEmail],
          'message': {'subject': emailSubject, 'html': emailHtmlBody},
        });
      } catch (e) {
        print(
          'Error al intentar disparar correo de estado ($newStatus) al Paciente: $e',
        );
      }
    }
  }

  /// Obtiene TODAS las citas para el PACIENTE.
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

  /// Elimina una cita (usado por el paciente para cancelar).
  Future<void> deleteAppointment(String appointmentId) {
    return _citasCollection.doc(appointmentId).delete();
  }

  /// Obtiene el historial de citas entre un Kine y un Paciente específico.
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
}
