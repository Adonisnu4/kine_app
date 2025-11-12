// lib/features/ejercicios/models/plan_tomado.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PlanTomado {
  final String id;
  final String nombre; // Viene de la colección 'plan'
  final String descripcion; // Viene de la colección 'plan'
  final String estado; // Viene de la colección 'plan_tomados_por_usuarios'
  final DateTime
  fechaInicio; // Viene de la colección 'plan_tomados_por_usuarios'
  final int sesionActual; // Viene de la colección 'plan_tomados_por_usuarios'

  PlanTomado({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.estado,
    required this.fechaInicio,
    required this.sesionActual,
  });
}
