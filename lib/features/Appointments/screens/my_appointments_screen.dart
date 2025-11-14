// lib/screens/my_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/models/appointment.dart';
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:kine_app/features/Chat/screens/chat_screen.dart';
import 'package:kine_app/shared/widgets/app_dialog.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late Stream<List<Appointment>> _appointmentsStream;

  @override
  void initState() {
    super.initState();
    _appointmentsStream = _appointmentService.getPatientAppointments(
      _currentUserId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas Solicitadas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar citas: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Aún no has solicitado ninguna cita.\nBusca un kinesiólogo en la sección "Servicios".',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final appointments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              return _buildAppointmentCard(appointments[index]);
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔵 TARJETA DE CADA CITA
  // ---------------------------------------------------------
  Widget _buildAppointmentCard(Appointment appointment) {
    final bool isPaciente = appointment.pacienteId == _currentUserId;
    final bool isKine = appointment.kineId == _currentUserId;

    final fecha = appointment.fechaCitaDT;
    final bool expirada = DateTime.now().isAfter(fecha);

    // ======================================================
    // 🔥 LÓGICA CORREGIDA Y FINAL DEL BOTÓN CANCELAR
    // ======================================================
    bool puedeCancelar = false;

    if (!expirada) {
      // Paciente o Kine pueden cancelar si está PENDIENTE o CONFIRMADA
      if ((appointment.estado == "pendiente" ||
              appointment.estado == "confirmada") &&
          (isPaciente || isKine)) {
        puedeCancelar = true;
      }
    }

    // ---------------------------------------------------------
    // ICONOS SEGÚN ESTADO
    // ---------------------------------------------------------
    IconData estadoIcon;
    Color estadoColor;
    String estadoTexto = appointment.estado.toUpperCase();

    switch (appointment.estado) {
      case 'confirmada':
        estadoIcon = Icons.check_circle;
        estadoColor = Colors.green;
        break;
      case 'denegada':
        estadoIcon = Icons.cancel;
        estadoColor = Colors.red;
        estadoTexto = 'RECHAZADA';
        break;
      case 'completada':
        estadoIcon = Icons.check_box;
        estadoColor = Colors.blueGrey;
        break;
      case 'cancelada':
        estadoIcon = Icons.block;
        estadoColor = Colors.red;
        break;
      default:
        estadoIcon = Icons.hourglass_top;
        estadoColor = Colors.orange;
        break;
    }

    // ---------------------------------------------------------
    // TARJETA
    // ---------------------------------------------------------
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con nombre Kine + Estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    appointment.kineNombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    children: [
                      Icon(estadoIcon, color: estadoColor, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        estadoTexto,
                        style: TextStyle(
                          color: estadoColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Divider(height: 18),

            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 16),
                const SizedBox(width: 8),
                Text(DateFormat('EEE, dd MMM yyyy', 'es_ES').format(fecha)),
              ],
            ),

            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 16),
                const SizedBox(width: 8),
                Text("${DateFormat('HH:mm').format(fecha)} hrs"),
              ],
            ),

            const SizedBox(height: 12),

            // ---------------------------------------------------------
            // 🔴 BOTÓN DE CANCELAR
            // ---------------------------------------------------------
            if (puedeCancelar)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text("Cancelar Cita"),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                  ),
                  onPressed: () async {
                    bool? confirma = await showAppConfirmationDialog(
                      context: context,
                      icon: Icons.warning,
                      title: "Cancelar cita",
                      content: "¿Deseas cancelar esta cita?",
                      confirmText: "Sí, cancelar",
                      cancelText: "No",
                      isDestructive: true,
                    );

                    if (confirma == true) {
                      try {
                        await _appointmentService.cancelAppointment(
                          appointment.id,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Cita cancelada"),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error al cancelar: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),

            // ---------------------------------------------------------
            // CHAT SI ESTÁ CONFIRMADA
            // ---------------------------------------------------------
            if (appointment.estado == "confirmada")
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Contactar Kine"),
                  style: TextButton.styleFrom(foregroundColor: Colors.teal),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverId: appointment.kineId,
                          receiverName: appointment.kineNombre,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
