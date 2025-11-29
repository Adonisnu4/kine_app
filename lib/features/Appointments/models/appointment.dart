import 'package:cloud_firestore/cloud_firestore.dart';

// Modelo que representa una cita dentro de la aplicación
class Appointment {
  final String id; // ID del documento en Firestore
  final String pacienteId; // ID del paciente
  final String pacienteNombre; // Nombre del paciente
  final String? pacienteEmail; // Email del paciente (opcional)
  final String kineId; // ID del kinesiólogo
  final String kineNombre; // Nombre del kinesiólogo
  final Timestamp fechaCita; // Fecha y hora de la cita
  final String estado; // Estado actual de la cita (pendiente, aceptada, etc.)
  final Timestamp creadaEn; // Fecha en que se creó el registro

  // Constructor principal
  Appointment({
    required this.id,
    required this.pacienteId,
    required this.pacienteNombre,
    this.pacienteEmail,
    required this.kineId,
    required this.kineNombre,
    required this.fechaCita,
    required this.estado,
    required this.creadaEn,
  });

  // Constructor factory que crea un Appointment desde un documento Firestore
  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Appointment(
      id: doc.id, // ID tomado del documento
      pacienteId: data['pacienteId'] ?? '', // ID paciente
      pacienteNombre: data['pacienteNombre'] ?? 'Paciente',
      pacienteEmail: data['pacienteEmail'], // Puede ser null
      kineId: data['kineId'] ?? '',
      kineNombre: data['kineNombre'] ?? 'Kine',
      fechaCita: data['fechaCita'] ?? Timestamp.now(),
      estado: data['estado'] ?? 'denegada',
      creadaEn: data['creadaEn'] ?? Timestamp.now(),
    );
  }

  // Convierte el Timestamp a DateTime (más fácil de usar en Flutter)
  DateTime get fechaCitaDT => fechaCita.toDate();
}
