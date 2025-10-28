import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/models/appointment.dart'; // Asegúrate que la ruta sea correcta
import 'package:kine_app/services/get_user_data.dart'; // Asegúrate que la ruta sea correcta
import 'package:intl/intl.dart';
import 'package:kine_app/services/user_service.dart'; // Ajusta la ruta si es necesario

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference _citasCollection = FirebaseFirestore.instance
      .collection('citas');

  /// Revisa si el paciente YA tiene una cita pendiente CON UN KINE ESPECÍFICO
  Future<bool> hasPendingAppointment(String pacienteId, String kineId) async {
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId) // Filtra por Kine específico
        .where('estado', isEqualTo: 'pendiente') // Filtra por estado pendiente
        .limit(1)
        .get();
    // ⚠️ Requiere índice: pacienteId (Asc), kineId (Asc), estado (Asc)
    return query.docs.isNotEmpty;
  }

  /// Revisa si un horario específico ya está ocupado
  Future<bool> isSlotTaken(String kineId, DateTime slot) async {
    final slotTimestamp = Timestamp.fromDate(slot);
    final query = await _citasCollection
        .where('kineId', isEqualTo: kineId)
        .where('fechaCita', isEqualTo: slotTimestamp)
        .where(
          'estado',
          whereIn: ['pendiente', 'confirmada'],
        ) // Incluye confirmadas también
        .limit(1)
        .get();
    // Requiere índice: kineId (Asc), fechaCita (Asc), estado (Asc)
    return query.docs.isNotEmpty;
  }

  /// --- 👇 2. FUNCIÓN requestAppointment MODIFICADA (Añade email al Kine) 👇 ---
  /// Crea la solicitud de cita Y ENVÍA EMAIL AL KINE
  Future<void> requestAppointment({
    required String kineId,
    required String kineNombre,
    required DateTime fechaCita,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Usuario no autenticado');

    // Datos del Paciente
    final userData = await getUserData();
    final String pacienteNombre = userData?['nombre_completo'] ?? 'Paciente';
    final String? pacienteEmail = user.email;

    // Crea objeto de cita
    final newAppointmentData = {
      'pacienteId': user.uid,
      'pacienteNombre': pacienteNombre,
      'pacienteEmail': pacienteEmail,
      'kineId': kineId,
      'kineNombre': kineNombre,
      'fechaCita': Timestamp.fromDate(fechaCita),
      'estado': 'pendiente',
      'creadaEn': Timestamp.now(),
    };

    // Guarda cita en Firestore
    await _citasCollection.add(newAppointmentData);

    // --- Envía Correo al Kine ---
    try {
      final String? kineEmail = await getUserEmailById(
        kineId,
      ); // Usa la función importada

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
          // Escribe en 'mail'
          'to': [kineEmail], // Destinatario: Kine
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
        print("Correo de nueva solicitud enviado (trigger) a $kineEmail");
      } else {
        print(
          "WARN: No se encontró email para Kine $kineId. No se envió correo.",
        );
      }
    } catch (e) {
      print('Error al intentar disparar correo de nueva solicitud al Kine: $e');
    }
    // --- Fin Envío Correo al Kine ---
  }
  // --- FIN requestAppointment MODIFICADO ---

  /// Obtiene TODAS las citas para el Kine (para su panel)
  Stream<List<Appointment>> getKineAppointments(String kineId) {
    return _citasCollection
        .where('kineId', isEqualTo: kineId)
        .orderBy('fechaCita', descending: false)
        .snapshots()
        .map((snapshot) {
          // Requiere índice: kineId (Asc), fechaCita (Asc)
          return snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
        });
  }

  /// --- 👇 3. FUNCIÓN updateAppointmentStatus MODIFICADA (Añade email de Rechazo) 👇 ---
  /// Actualiza el estado Y ENVÍA EMAIL AL PACIENTE (Confirmación o Rechazo)
  Future<void> updateAppointmentStatus(
    Appointment appointment, // Recibe el objeto Appointment completo
    String newStatus,
  ) async {
    // Actualiza el estado en Firestore
    await _citasCollection.doc(appointment.id).update({'estado': newStatus});

    // Prepara datos comunes para ambos tipos de correo
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

    // Define contenido según el nuevo estado
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
    }
    // --- NUEVO BLOQUE para RECHAZO ---
    else if (newStatus == 'denegada') {
      // 'denegada' es el estado usado para rechazar
      emailSubject = 'Actualización sobre tu solicitud de cita';
      emailHtmlBody =
          '''
        <p>Hola ${appointment.pacienteNombre},</p>
        <p>Te informamos que tu solicitud de cita con <b>${appointment.kineNombre}</b> para el día $fechaFormateada a las $horaFormateada hrs. ha sido <b>rechazada</b>.</p>
        <p>Esto puede deberse a la disponibilidad del profesional u otros motivos. Te recomendamos intentar solicitar otro horario disponible o contactar directamente al kinesiólogo a través del chat en la aplicación si tienes alguna consulta.</p>
        <p>Lamentamos cualquier inconveniente,<br>Equipo KineApp</p>
      ''';
    }
    // --- FIN NUEVO BLOQUE ---

    // Envía el correo si se preparó un asunto y cuerpo, y si hay email del paciente
    if (emailSubject.isNotEmpty &&
        emailHtmlBody.isNotEmpty &&
        appointment.pacienteEmail != null) {
      try {
        await _firestore.collection('mail').add({
          'to': [appointment.pacienteEmail], // Destinatario: Paciente
          'message': {'subject': emailSubject, 'html': emailHtmlBody},
        });
        print(
          "Correo de estado '$newStatus' enviado (trigger) a ${appointment.pacienteEmail}",
        );
      } catch (e) {
        print(
          'Error al intentar disparar correo de estado ($newStatus) al Paciente: $e',
        );
      }
    } else if (newStatus == 'confirmada' || newStatus == 'denegada') {
      // Log si no se envía correo (útil para depurar)
      print(
        "WARN: No se envió correo para estado '$newStatus'. Email Paciente: ${appointment.pacienteEmail}, Asunto: '$emailSubject', Cuerpo: '${emailHtmlBody.isNotEmpty}'",
      );
    }
  }
  // --- FIN updateAppointmentStatus MODIFICADO ---

  /// Obtiene TODAS las citas para el PACIENTE
  Stream<List<Appointment>> getPatientAppointments(String pacienteId) {
    return _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('creadaEn', descending: true)
        .snapshots()
        .map((snapshot) {
          // Requiere índice: pacienteId (Asc), creadaEn (Desc)
          return snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
        });
  }

  /// Elimina una cita (usado por el paciente para cancelar)
  Future<void> deleteAppointment(String appointmentId) {
    return _citasCollection.doc(appointmentId).delete();
  }
} // Fin de la clase AppointmentService
