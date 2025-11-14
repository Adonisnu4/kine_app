// lib/services/appointment_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Ajusta rutas según tu estructura
import 'package:kine_app/features/Appointments/models/appointment.dart';
import 'package:kine_app/features/auth/services/get_user_data.dart';
import 'package:kine_app/features/auth/services/user_service.dart';

class AppointmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final CollectionReference _citasCollection = FirebaseFirestore.instance
      .collection('citas');

  // --------------------------------------------------------------
  // 1️⃣ Revisa si el paciente ya tiene cita pendiente con ese Kine
  // --------------------------------------------------------------
  Future<bool> hasPendingAppointment(String pacienteId, String kineId) async {
    final query = await _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .where('kineId', isEqualTo: kineId)
        .where('estado', isEqualTo: 'pendiente')
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  // --------------------------------------------------------------
  // 2️⃣ Revisa si ya existe una cita CONFIRMADA a futuro
  // --------------------------------------------------------------
  Future<bool> hasConfirmedAppointmentWithKine(
    String pacienteId,
    String kineId,
  ) async {
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

  // --------------------------------------------------------------
  // 3️⃣ Revisa si un horario ya está tomado
  // --------------------------------------------------------------
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

  // --------------------------------------------------------------
  // 4️⃣ Crear solicitud de cita
  // --------------------------------------------------------------
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
        'No puedes solicitar citas para un horario pasado o muy cercano.',
      );
    }

    if (await isSlotTaken(kineId, fechaCita)) {
      throw Exception('Esta hora ya fue reservada.');
    }

    final userData = await getUserData();
    final pacienteNombre = userData?['nombre_completo'] ?? 'Paciente';

    await _citasCollection.add({
      'pacienteId': user.uid,
      'pacienteNombre': pacienteNombre,
      'pacienteEmail': user.email,
      'kineId': kineId,
      'kineNombre': kineNombre,
      'fechaCita': Timestamp.fromDate(fechaCita),
      'estado': 'pendiente',
      'creadaEn': Timestamp.now(),
    });

    // correo al kine
    try {
      final emailKine = await getUserEmailById(kineId);
      if (emailKine != null) {
        final fechaFmt = DateFormat(
          "EEEE d 'de' MMMM yyyy",
          'es_ES',
        ).format(fechaCita);
        final horaFmt = DateFormat("HH:mm", 'es_ES').format(fechaCita);

        await _firestore.collection("mail").add({
          "to": [emailKine],
          "message": {
            "subject": "Nueva solicitud de cita",
            "html":
                "<p>El paciente $pacienteNombre ha solicitado una cita para el $fechaFmt a las $horaFmt.</p>",
          },
        });
      }
    } catch (_) {}
  }

  // --------------------------------------------------------------
  // 5️⃣ Citas del Kine
  // --------------------------------------------------------------
  Stream<List<Appointment>> getKineAppointments(String kineId) {
    return _citasCollection
        .where('kineId', isEqualTo: kineId)
        .orderBy('fechaCita')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Appointment.fromFirestore(d)).toList(),
        );
  }

  // --------------------------------------------------------------
  // 6️⃣ Cambiar estado CONFIRMADA / DENEGADA / CANCELADA (Kine)
  // --------------------------------------------------------------
  Future<void> updateAppointmentStatus(
    Appointment appointment,
    String newStatus,
  ) async {
    final now = DateTime.now();

    if (appointment.fechaCitaDT.isBefore(now)) {
      throw Exception("La cita ya pasó. No puedes cambiar su estado.");
    }

    await _citasCollection.doc(appointment.id).update({"estado": newStatus});

    // NOTIFICAR por correo
    final fechaFmt = DateFormat(
      "EEEE d 'de' MMMM yyyy",
      'es_ES',
    ).format(appointment.fechaCitaDT);
    final horaFmt = DateFormat(
      "HH:mm",
      'es_ES',
    ).format(appointment.fechaCitaDT);

    String asunto = "";
    String html = "";

    if (newStatus == "confirmada") {
      asunto = "Tu cita ha sido confirmada";
      html =
          "<p>Tu cita con ${appointment.kineNombre} para el $fechaFmt a las $horaFmt ha sido confirmada.</p>";
    }

    if (newStatus == "denegada") {
      asunto = "Tu cita fue rechazada";
      html =
          "<p>Tu cita con ${appointment.kineNombre} para el $fechaFmt a las $horaFmt fue rechazada.</p>";
    }

    if (newStatus == "cancelada") {
      asunto = "Tu cita fue cancelada por el profesional";
      html =
          "<p>Tu cita con ${appointment.kineNombre} programada para el $fechaFmt a las $horaFmt fue cancelada por el profesional.</p>";
    }

    if (appointment.pacienteEmail != null) {
      await _firestore.collection("mail").add({
        "to": [appointment.pacienteEmail],
        "message": {"subject": asunto, "html": html},
      });
    }
  }

  // --------------------------------------------------------------
  // 7️⃣ Citas del PACIENTE
  // --------------------------------------------------------------
  Stream<List<Appointment>> getPatientAppointments(String pacienteId) {
    return _citasCollection
        .where('pacienteId', isEqualTo: pacienteId)
        .orderBy('creadaEn', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => Appointment.fromFirestore(d)).toList(),
        );
  }

  // --------------------------------------------------------------
  // 8️⃣ Eliminar cita (evitar usar si quieres historial)
  // --------------------------------------------------------------
  Future<void> deleteAppointment(String appointmentId) async {
    await _citasCollection.doc(appointmentId).delete();
  }

  // 9️⃣ CANCELAR CITA (paciente o kine sin borrar el documento)
  Future<void> cancelAppointment(String appointmentId) async {
    try {
      final doc = await _citasCollection.doc(appointmentId).get();
      if (!doc.exists) throw Exception("La cita no existe");

      final data = doc.data() as Map<String, dynamic>;

      // Fecha segura
      final Timestamp? tsFecha = data['fechaCita'] as Timestamp?;
      final DateTime fecha = tsFecha?.toDate() ?? DateTime.now();

      final String fechaFmt = DateFormat(
        "EEEE d 'de' MMMM yyyy",
        'es_ES',
      ).format(fecha);
      final String horaFmt = DateFormat("HH:mm", 'es_ES').format(fecha);

      // Actualizar estado en Firestore (lo IMPORTANTE)
      await _citasCollection.doc(appointmentId).update({
        "estado": "cancelada",
        "canceladaEn": Timestamp.now(),
      });

      // Datos seguros (permitir null)
      final String pacienteNombre =
          (data["pacienteNombre"] ?? "Paciente") as String;
      final String? pacienteEmail = data["pacienteEmail"] as String?;
      final String kineNombre = (data["kineNombre"] ?? "Kinesiólogo") as String;
      final String kineId = data["kineId"] as String? ?? '';

      final String? kineEmail = await getUserEmailById(kineId).catchError((_) {
        return null;
      });

      final String userUid = _auth.currentUser!.uid;

      // Si cancela el PACIENTE -> correo al Kine (si tiene email)
      if (userUid == data["pacienteId"] && kineEmail != null) {
        try {
          await _firestore.collection("mail").add({
            "to": [kineEmail],
            "message": {
              "subject": "El paciente canceló su cita",
              "html":
                  "<p>El paciente <b>$pacienteNombre</b> canceló la cita del <b>$fechaFmt</b> a las <b>$horaFmt</b>.</p>",
            },
          });
        } catch (e) {
          print("Error enviando correo al kine por cancelación: $e");
        }
      }
      // Si cancela el KINE -> correo al paciente (si tiene email)
      else if (pacienteEmail != null) {
        try {
          await _firestore.collection("mail").add({
            "to": [pacienteEmail],
            "message": {
              "subject": "Tu cita fue cancelada",
              "html":
                  "<p>Tu cita con <b>$kineNombre</b> programada para el <b>$fechaFmt</b> a las <b>$horaFmt</b> fue cancelada.</p>",
            },
          });
        } catch (e) {
          print("Error enviando correo al paciente por cancelación: $e");
        }
      }
    } catch (e) {
      // Si algo falla, al menos devolvemos un error legible
      throw Exception("Error al cancelar cita: $e");
    }
  }

  // --------------------------------------------------------------
  // 🔟 Historial entre un paciente y un kine
  // --------------------------------------------------------------
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
          (snap) => snap.docs.map((d) => Appointment.fromFirestore(d)).toList(),
        );
  }
}
