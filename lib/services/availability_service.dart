// lib/services/availability_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Para TimeOfDay
import 'package:intl/intl.dart'; // Para formatear fechas

class AvailabilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _availabilityCollection = FirebaseFirestore.instance
      .collection('kine_availability');

  // --- Para el Kinesiólogo ---

  /// Guarda/actualiza disponibilidad para un día.
  Future<void> setAvailability({
    required String kineId,
    required DateTime date,
    required List<String> availableSlots, // ej: ["09:00", "10:00"]
  }) async {
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    final dateTimestamp = Timestamp.fromDate(dateAtMidnight);
    final String docId =
        '${kineId}_${DateFormat('yyyy-MM-dd').format(dateAtMidnight)}';

    await _availabilityCollection.doc(docId).set({
      'kineId': kineId,
      'fecha': dateTimestamp,
      'slots': availableSlots,
    }, SetOptions(merge: true));
  }

  /// Obtiene los slots guardados para un día (para el Kine).
  Future<List<String>> getSavedAvailability(
    String kineId,
    DateTime date,
  ) async {
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    final String docId =
        '${kineId}_${DateFormat('yyyy-MM-dd').format(dateAtMidnight)}';
    final doc = await _availabilityCollection.doc(docId).get();

    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['slots'] ?? []);
    }
    return [];
  }

  // --- Para el Paciente ---

  /// Obtiene los slots disponibles para un Kine en una fecha (para Paciente).
  Future<List<TimeOfDay>> getAvailableSlotsForDay(
    String kineId,
    DateTime date,
  ) async {
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    final dateTimestamp = Timestamp.fromDate(dateAtMidnight);

    final querySnapshot = await _availabilityCollection
        .where('kineId', isEqualTo: kineId)
        .where('fecha', isEqualTo: dateTimestamp)
        .limit(1)
        .get();
    // ⚠️ Firestore requerirá un índice: kineId (Asc), fecha (Asc)

    if (querySnapshot.docs.isNotEmpty) {
      final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
      final List<String> slotStrings = List<String>.from(data['slots'] ?? []);
      List<TimeOfDay> timeSlots = [];
      // Convierte "HH:mm" a TimeOfDay
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
      return timeSlots;
    }
    return []; // No hay disponibilidad definida
  }
}
