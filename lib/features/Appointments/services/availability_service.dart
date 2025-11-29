import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // Necesario para TimeOfDay
import 'package:intl/intl.dart'; // Para formatear fechas

class AvailabilityService {
  // Instancia principal de Firestore para ejecutar consultas
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Referencia a la colección donde se almacena la disponibilidad del kinesiólogo
  final CollectionReference _availabilityCollection = FirebaseFirestore.instance
      .collection('kine_availability');

  // MÉTODOS PARA EL KINESIÓLOGO
  /// Genera un ID único para el documento de disponibilidad.
  /// Se construye a partir del KineId + fecha en formato yyyy-MM-dd.
  /// Esto permite almacenar 1 documento por día por kinesiólogo.
  String _generateDocId(String kineId, DateTime dateAtMidnight) {
    return '${kineId}_${DateFormat('yyyy-MM-dd').format(dateAtMidnight)}';
  }

  /// Guarda o actualiza la disponibilidad de un kinesiólogo para un día.
  /// `availableSlots` es una lista de strings como ["09:00", "10:00"].
  Future<void> setAvailability({
    required String kineId,
    required DateTime date,
    required List<String> availableSlots,
  }) async {
    // Normaliza la fecha a medianoche para evitar problemas con horas
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    final dateTimestamp = Timestamp.fromDate(dateAtMidnight);

    // Genera el ID único del documento
    final String docId = _generateDocId(kineId, dateAtMidnight);

    // Guarda o actualiza el documento de disponibilidad
    await _availabilityCollection.doc(docId).set({
      'kineId': kineId,
      'fecha': dateTimestamp,
      'slots': availableSlots,
    }, SetOptions(merge: true));
  }

  /// Obtiene los horarios guardados para un día dado.
  /// Retorna una lista de strings con formato "HH:mm".
  Future<List<String>> getSavedAvailability(
    String kineId,
    DateTime date,
  ) async {
    final dateAtMidnight = DateTime(date.year, date.month, date.day);
    final String docId = _generateDocId(kineId, dateAtMidnight);

    final doc = await _availabilityCollection.doc(docId).get();

    // Si existe la disponibilidad, devuelve los horarios guardados.
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      return List<String>.from(data['slots'] ?? []);
    }

    // Si no existe disponibilidad configurada, devuelve una lista vacía.
    return [];
  }

  //MÉTODOS PARA EL PACIENTE
  /// Obtiene y devuelve los horarios disponibles para un kinesiólogo en una fecha.
  /// Filtra automáticamente horarios que ya pasaron si la fecha es HOY.
  Future<List<TimeOfDay>> getAvailableSlotsForDay(
    String kineId,
    DateTime date,
  ) async {
    // Normaliza la fecha seleccionada
    final dateAtMidnight = DateTime(date.year, date.month, date.day);

    // Acceso directo al documento del día
    final String docId = _generateDocId(kineId, dateAtMidnight);
    final doc = await _availabilityCollection.doc(docId).get();

    // Si existe disponibilidad almacenada
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      final List<String> slotStrings = List<String>.from(data['slots'] ?? []);

      List<TimeOfDay> timeSlots = [];

      // Convierte los textos "HH:mm" a objetos TimeOfDay
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

      // Ordena los horarios en orden creciente
      timeSlots.sort(
        (a, b) => (a.hour * 60 + a.minute).compareTo(b.hour * 60 + b.minute),
      );

      // Lista final de horarios válidos para mostrar
      final List<TimeOfDay> futureSlots = [];

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selectedDateAtMidnight = DateTime(date.year, date.month, date.day);

      // Si la fecha seleccionada es pasada, retorna lista vacía
      if (selectedDateAtMidnight.isBefore(today)) {
        return [];
      }

      // Revisamos cada horario para ver si es válido
      for (var slot in timeSlots) {
        // Construye un DateTime completo combinando fecha + hora
        final slotDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          slot.hour,
          slot.minute,
        );

        // Si la fecha es HOY, solo muestra los horarios que aún no han pasado
        if (selectedDateAtMidnight.isAtSameMomentAs(today)) {
          if (slotDateTime.isAfter(now.add(const Duration(minutes: 5)))) {
            futureSlots.add(slot);
          }
        } else {
          // Si es un día futuro, todos los horarios son válidos
          futureSlots.add(slot);
        }
      }

      return futureSlots;
    }

    // Si no hay disponibilidad configurada, regresa lista vacía
    return [];
  }
}
