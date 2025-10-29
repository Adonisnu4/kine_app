// lib/screens/patient_appointment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/models/appointment.dart'; // Importa el modelo de cita
import 'package:kine_app/services/appointment_service.dart'; // Importa el servicio de citas
import 'package:firebase_auth/firebase_auth.dart'; // Para obtener el ID del Kine
import 'package:intl/intl.dart'; // Para formatear fechas

/// Pantalla que muestra el historial de citas entre el Kine logueado
/// y un paciente específico.
class PatientAppointmentHistoryScreen extends StatefulWidget {
  final String patientId; // ID del paciente cuyos datos se mostrarán
  final String patientName; // Nombre del paciente para mostrar en el título

  const PatientAppointmentHistoryScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientAppointmentHistoryScreen> createState() =>
      _PatientAppointmentHistoryScreenState();
}

class _PatientAppointmentHistoryScreenState
    extends State<PatientAppointmentHistoryScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final String _currentKineId =
      FirebaseAuth.instance.currentUser!.uid; // ID del Kine logueado
  late Stream<List<Appointment>>
  _historyStream; // Stream para escuchar las citas

  @override
  void initState() {
    super.initState();
    // Inicia la escucha del historial de citas al crear la pantalla
    _historyStream = _appointmentService.getAppointmentHistory(
      _currentKineId, // ID del Kine actual
      widget.patientId, // ID del paciente seleccionado
    );
  }

  /// Devuelve un mapa con el ícono y color correspondiente a un estado de cita.
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status) {
      case 'confirmada':
        return {
          'icon': Icons.check_circle_outline,
          'color': Colors.green.shade700,
        };
      case 'completada':
        return {'icon': Icons.check_box_outlined, 'color': Colors.blueGrey};
      case 'denegada':
        return {
          'icon': Icons.cancel_outlined,
          'color': Colors.red.shade700,
          'text': 'RECHAZADA',
        };
      case 'pendiente':
        return {
          'icon': Icons.hourglass_empty_outlined,
          'color': Colors.orange.shade800,
        };
      default:
        return {
          'icon': Icons.help_outline,
          'color': Colors.grey.shade600,
        }; // Estado desconocido
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de ${widget.patientName}',
        ), // Título con nombre del paciente
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _historyStream, // Escucha el stream de citas
        builder: (context, snapshot) {
          // Muestra indicador mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Muestra mensaje de error si falla
          if (snapshot.hasError) {
            print("Error en StreamBuilder de Historial: ${snapshot.error}");
            return Center(
              child: Text('Error al cargar historial: ${snapshot.error}'),
            );
          }
          // Muestra mensaje si no hay citas encontradas
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No se encontraron citas (confirmadas, pasadas o futuras) con este paciente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Si hay datos, muestra la lista
          final appointments = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 8.0,
            ),
            itemCount: appointments.length,
            // Añade un divisor entre cada cita
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final statusStyle = _getStatusStyle(
                appointment.estado,
              ); // Obtiene estilo del estado
              final statusText =
                  statusStyle['text'] ??
                  appointment.estado.toUpperCase(); // Obtiene texto del estado

              // Construye un ListTile para cada cita
              return ListTile(
                leading: Icon(
                  statusStyle['icon'],
                  color: statusStyle['color'],
                  size: 28,
                ), // Ícono de estado
                title: Text(
                  // Fecha y Hora de la cita
                  DateFormat(
                        'EEEE dd MMM yyyy - HH:mm',
                        'es_ES',
                      ).format(appointment.fechaCitaDT) +
                      ' hrs',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  // Muestra el estado
                  'Estado: $statusText',
                  style: TextStyle(
                    color: statusStyle['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Podrías añadir onTap para ver más detalles si fuera necesario
                // onTap: () { /* Navegar a detalles de la cita */ },
              );
            },
          );
        },
      ),
    );
  }
}
