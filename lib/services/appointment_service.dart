// lib/services/appointment_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/models/appointment.dart'; // Asegúrate que la ruta sea correcta
import 'package:kine_app/services/get_user_data.dart'; // Asegúrate que la ruta sea correcta
import 'package:intl/intl.dart';
// --- 👇 IMPORTA EL SERVICIO DONDE ESTÁ getUserEmailById 👇 ---
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
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'pendiente')
        .limit(1)
        .get();
    // ⚠️ Requiere índice: pacienteId (Asc), kineId (Asc), estado (Asc)
    return query.docs.isNotEmpty;
  }

  /// **NUEVO:** Revisa si el paciente YA tiene una cita CONFIRMADA con un Kine específico
  Future<bool> hasConfirmedAppointmentWithKine(
    String pacienteId,
    String kineId,
  ) async {
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'confirmada') // <-- Busca citas confirmadas
        .limit(1)
        .get();
    // ⚠️ Usa el MISMO índice que hasPendingAppointment: pacienteId(Asc), kineId(Asc), estado(Asc)
    return query.docs.isNotEmpty;
  }

  /// Revisa si un horario específico ya está ocupado (por cualquier paciente)
  Future<bool> isSlotTaken(String kineId, DateTime slot) async {
    final slotTimestamp = Timestamp.fromDate(slot);
    final query = await _citasCollection
        .where('kineId', isEqualTo: kineId)
        .where('fechaCita', isEqualTo: slotTimestamp)
        .where('estado', whereIn: ['pendiente', 'confirmada']) // Incluye ambas
        .limit(1)
        .get();
    // Requiere índice: kineId (Asc), fechaCita (Asc), estado (Asc)
    return query.docs.isNotEmpty;
  }

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

        // Escribe en 'mail' para la extensión Trigger Email
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
        print("Correo de nueva solicitud enviado (trigger) a $kineEmail");
      } else {
        print(
          "WARN: No se encontró email para Kine $kineId. No se envió correo.",
        );
      }
    } catch (e) {
      print('Error al intentar disparar correo de nueva solicitud al Kine: $e');
      // No re-lanzamos el error aquí, la cita ya se creó.
    }
    // --- Fin Envío Correo al Kine ---
  }

  /// Obtiene TODAS las citas para el Kine (para su panel)
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
    // Requiere índice: kineId (Asc), fechaCita (Asc)
  }

  /// Actualiza el estado Y ENVÍA EMAIL AL PACIENTE (Confirmación o Rechazo)
  Future<void> updateAppointmentStatus(
    Appointment appointment, // Recibe el objeto Appointment completo
    String newStatus,
  ) async {
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
    }

    // Envía correo si aplica
    if (emailSubject.isNotEmpty &&
        emailHtmlBody.isNotEmpty &&
        appointment.pacienteEmail != null) {
      try {
        // Escribe en 'mail' para la extensión Trigger Email
        await _firestore.collection('mail').add({
          'to': [appointment.pacienteEmail],
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
      // Log si no se envía (útil para depurar)
      print(
        "WARN: No se envió correo para estado '$newStatus'. Email Paciente: ${appointment.pacienteEmail}, Asunto: '$emailSubject', Cuerpo: '${emailHtmlBody.isNotEmpty}'",
      );
    }
  }

  /// Obtiene TODAS las citas para el PACIENTE
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
    // Requiere índice: pacienteId (Asc), creadaEn (Desc)
  }

  /// Elimina una cita (usado por el paciente para cancelar)
  Future<void> deleteAppointment(String appointmentId) {
    return _citasCollection.doc(appointmentId).delete();
  }

  /// Obtiene el historial de citas entre un Kine y un Paciente específico, ordenado por fecha.
  Stream<List<Appointment>> getAppointmentHistory(
    String kineId,
    String pacienteId,
  ) {
    print(
      "getAppointmentHistory: Buscando citas para Kine: $kineId, Paciente: $pacienteId",
    );
    return _citasCollection
        .where('kineId', isEqualTo: kineId) // Filtra por el Kine logueado
        .where(
          'pacienteId',
          isEqualTo: pacienteId,
        ) // Filtra por el paciente específico
        .orderBy(
          'fechaCita',
          descending: true,
        ) // Ordena por fecha de la cita (más recientes primero)
        .snapshots() // Escucha cambios en tiempo real
        .map((snapshot) {
          print(
            "getAppointmentHistory: Snapshot recibido con ${snapshot.docs.length} citas.",
          );
          // ⚠️ Firestore requerirá un índice compuesto: kineId (Asc), pacienteId (Asc), fechaCita (Desc)
          // Convierte los documentos a objetos Appointment
          return snapshot.docs
              .map((doc) => Appointment.fromFirestore(doc))
              .toList();
        });
  }
} // Fin clase
