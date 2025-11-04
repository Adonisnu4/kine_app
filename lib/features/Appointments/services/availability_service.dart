import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Necesario para TimeOfDay
import 'package:intl/intl.dart'; // Para formatear fechas

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore
      .instance; // Se mantiene, aunque _availabilityCollection usa la instancia
  final CollectionReference _availabilityCollection = FirebaseFirestore.instance
      .collection('kine_availability');

  // --- Para el Kinesiólogo: Almacenamiento y Carga de Disponibilidad ---

  /// Genera el ID del documento basado en KineId y Fecha (yyyy-MM-dd).
  String _generateDocId(String kineId, DateTime dateAtMidnight) {
    return '${kineId}_${DateFormat('yyyy-MM-dd').format(dateAtMidnight)}';
  }

  /// Guarda/actualiza disponibilidad para un día específico.
  Future<void> setAvailability({
    required String kineId,
    required DateTime date,
    required List<String> availableSlots, // ej: ["09:00", "10:00"]
  }) async {
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    final dateTimestamp = Timestamp.fromDate(dateAtMidnight);
    final String docId = _generateDocId(kineId, dateAtMidnight);

    await _availabilityCollection.doc(docId).set({
      'kineId': kineId,
      'fecha': dateTimestamp,
      'slots': availableSlots,
    }, SetOptions(merge: true));
  }

  /// Obtiene los slots guardados para un día (usado por el Kine para ver su configuración).
  Future<List<String>> getSavedAvailability(
    String kineId,
    DateTime date,
  ) async {
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    final String docId = _generateDocId(kineId, dateAtMidnight);
    final doc = await _availabilityCollection.doc(docId).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      // Se utiliza una copia segura para la lista por si el valor es null
      return List<String>.from(data['slots'] ?? []);
    }
    return [];
  }

  // --- Para el Paciente: Obtener Disponibilidad y Filtrar Horarios Pasados ---

  /// Obtiene los slots disponibles para un Kine en una fecha y filtra para mostrar solo horarios futuros.
  /// Los horarios pasados del día actual son descartados.
  Future<List<TimeOfDay>> getAvailableSlotsForDay(
    String kineId,
    DateTime date,
  ) async {
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    // 🚩 CORRECCIÓN CRÍTICA: Acceso directo por docId en lugar de consulta 'where'
    final String docId = _generateDocId(kineId, dateAtMidnight);
    final doc = await _availabilityCollection.doc(docId).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      // Se utiliza una copia segura para la lista por si el valor es null
      final List<String> slotStrings = List<String>.from(data['slots'] ?? []);

      List<TimeOfDay> timeSlots = [];

      // Conversión de String ("HH:mm") a TimeOfDay
      for (String slotStr in slotStrings) {
        try {
          final parts = slotStr.split(':');
          if (parts.length == 2) {
            final hour = int.parse(parts[0]);
            final minute = int.parse(parts[1]);
            timeSlots.add(TimeOfDay(hour: hour, minute: minute));
          }
        } catch (e) {
          print("Error parseando slot '$slotStr': $e");
        }
      }

      // Ordena los slots
      timeSlots.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );

      // 2. LÓGICA DE FILTRADO PARA MOSTRAR SOLO HORARIOS FUTUROS
      final List<TimeOfDay> futureSlots = [];
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDateAtMidnight = DateTime(date.year, date.month, date.day);

      // Regla A: Si la fecha seleccionada es en el pasado (ayer o antes), devolver lista vacía.
      if (selectedDateAtMidnight.isBefore(today)) {
        return [];
      }

      for (var slot in timeSlots) {
        // Combina la fecha seleccionada con la hora del slot para crear un DateTime completo.
        final slotDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          slot.hour,
          slot.minute,
        );

        // Regla B: Si la fecha es HOY, el slot debe ser al menos 5 minutos en el futuro.
        if (selectedDateAtMidnight.isAtSameMomentAs(today)) {
          // Se añaden 5 minutos de buffer para evitar errores de exactitud temporal
          if (slotDateTime.isAfter(now.add(const Duration(minutes: 5)))) {
            futureSlots.add(slot);
          }
        } else {
          // Regla C: Si es un día futuro, todos los slots publicados son válidos.
          futureSlots.add(slot);
        }
      }

      return futureSlots;
    }

    return []; // No hay disponibilidad definida para ese día.
  }
}
