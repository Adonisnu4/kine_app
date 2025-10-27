// lib/models/appointment.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String pacienteId;
  final String pacienteNombre;
  final String? pacienteEmail; // Email para contacto
  final String kineId;
  final String kineNombre;
  final Timestamp fechaCita;
  final String estado; // 'pendiente', 'confirmada', 'denegada', 'completada'
  final Timestamp creadaEn;

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

  factory Appointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      pacienteId: data['pacienteId'] ?? '',
      pacienteNombre: data['pacienteNombre'] ?? 'Paciente',
      pacienteEmail: data['pacienteEmail'],
      kineId: data['kineId'] ?? '',
      kineNombre: data['kineNombre'] ?? 'Kine',
      fechaCita: data['fechaCita'] ?? Timestamp.now(),
      estado: data['estado'] ?? 'denegada',
      creadaEn: data['creadaEn'] ?? Timestamp.now(),
    );
  }

  DateTime get fechaCitaDT => fechaCita.toDate();
}
