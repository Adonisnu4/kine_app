// lib/screens/patient_appointment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/models/appointment.dart';
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientAppointmentHistoryScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

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
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;
  late Stream<List<Appointment>> _historyStream;

  @override
  void initState() {
    super.initState();
    _historyStream = _appointmentService.getAppointmentHistory(
      _currentKineId,
      widget.patientId,
    );
  }

  /// Devuelve un mapa con el ícono y color correspondiente a un estado de cita.
  Map<String, dynamic> _getStatusStyle(String status) {
    // 🚀 --- CORRECCIÓN A MAYÚSCULAS (Switch) ---
    switch (status) {
      case 'CONFIRMADA':
        return {
          'icon': Icons.check_circle_outline,
          'color': Colors.green.shade700,
        };
      case 'COMPLETADA':
        return {'icon': Icons.check_box_outlined, 'color': Colors.blueGrey};
      case 'DENEGADA':
        return {
          'icon': Icons.cancel_outlined,
          'color': Colors.red.shade700,
          'text': 'RECHAZADA', // O DENEGADA
        };
      case 'CANCELADA':
        return {'icon': Icons.close, 'color': Colors.red.shade700};
      case 'PENDIENTE':
        return {
          'icon': Icons.hourglass_empty_outlined,
          'color': Colors.orange.shade800,
        };
      default:
        return {'icon': Icons.help_outline, 'color': Colors.grey.shade600};
    }
    // 🚀 --- FIN DE CORRECCIÓN ---
  }

  String _capitalize(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de ${widget.patientName}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error en StreamBuilder de Historial: ${snapshot.error}");
            return Center(
              child: Text('Error al cargar historial: ${snapshot.error}'),
            );
          }
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

          final appointments = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: 10.0,
              horizontal: 8.0,
            ),
            itemCount: appointments.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final statusStyle = _getStatusStyle(appointment.estado);
              final statusText =
                  statusStyle['text'] ?? appointment.estado.toUpperCase();

              return ListTile(
                leading: Icon(
                  statusStyle['icon'],
                  color: statusStyle['color'],
                  size: 28,
                ),
                title: Text(
                  '${DateFormat('EEEE dd MMM yyyy - HH:mm', 'es_ES').format(appointment.fechaCitaDT)} hrs',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  'Estado: $statusText',
                  style: TextStyle(
                    color: statusStyle['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
