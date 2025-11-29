// lib/screens/my_appointments_screen.dart

import 'package:flutter/material.dart';
// Modelo que representa una cita
import 'package:kine_app/features/Appointments/models/appointment.dart';
// Servicio que gestiona lectura, actualización y eliminación de citas
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
// Para obtener el usuario actual autenticado
import 'package:firebase_auth/firebase_auth.dart';
// Para formatear fechas y horas
import 'package:intl/intl.dart';
// Diálogos reutilizables personalizados
import 'package:kine_app/shared/widgets/app_dialog.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  // Servicio para interactuar con Firestore
  final AppointmentService _appointmentService = AppointmentService();

  // UID del paciente actual (usuario autenticado)
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Stream que escucha en tiempo real las citas del usuario
  late Stream<List<Appointment>> _appointmentsStream;

  @override
  void initState() {
    super.initState();
    // Obtiene un stream que escucha cambios en las citas del paciente
    _appointmentsStream = _appointmentService.getPatientAppointments(
      _currentUserId,
    );
  }

  // Maneja la cancelación de una cita pendiente
  void _handleCancelAppointment(Appointment appointment) async {
    // Muestra diálogo de confirmación
    bool? confirm = await showAppConfirmationDialog(
      context: context,
      icon: Icons.warning_amber_rounded,
      title: 'Cancelar Cita',
      content: '¿Estás seguro de que quieres cancelar esta solicitud de cita?',
      confirmText: 'Sí, Cancelar',
      cancelText: 'No',
      isDestructive: true, // Marca el botón confirm como acción destructiva
    );

    // Si confirma, procede
    if (confirm == true) {
      try {
        // Elimina la cita desde Firestore usando el servicio
        await _appointmentService.deleteAppointment(appointment.id);

        if (mounted) {
          // Muestra mensaje general de éxito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        // Captura errores al eliminar cita
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cancelar: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Citas Solicitadas'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),

      // Escucha el stream de citas en tiempo real
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream,
        builder: (context, snapshot) {
          // Mientras carga los datos
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Si ocurre un error en la carga
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar citas: ${snapshot.error}'),
            );
          }

          // Si no hay citas
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Aún no has solicitado ninguna cita.\nBusca un kinesiólogo en la sección "Servicios".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          // Lista de citas encontradas
          final appointments = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(appointment);
            },
          );
        },
      ),
    );
  }

  // Construye cada tarjeta de cita individual
  Widget _buildAppointmentCard(Appointment appointment) {
    // Variables para ícono, color y texto del estado
    IconData estadoIcon;
    Color estadoColor;
    String estadoTexto = appointment.estado.toUpperCase();

    // Determina el estilo según el estado de la cita
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

      case 'pendiente':
      default:
        estadoIcon = Icons.hourglass_top;
        estadoColor = Colors.orange.shade800;
        break;
    }

    // Tarjeta contenedora con la información completa de la cita
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),

      child: Padding(
        padding: const EdgeInsets.all(14.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: nombre del kine + estado de la cita
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nombre del kinesiólogo
                Flexible(
                  child: Text(
                    appointment.kineNombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Indicador visual del estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(estadoIcon, color: estadoColor, size: 16),
                      const SizedBox(width: 6),
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

            // Fecha de la cita
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat(
                    'EEE, dd MMM yyyy',
                    'es_ES',
                  ).format(appointment.fechaCitaDT),
                  style: TextStyle(color: Colors.grey[800], fontSize: 15),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // Hora de la cita
            Row(
              children: [
                Icon(
                  Icons.access_time_outlined,
                  size: 16,
                  color: Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('HH:mm', 'es_ES').format(appointment.fechaCitaDT)} hrs',
                  style: TextStyle(color: Colors.grey[800], fontSize: 15),
                ),
              ],
            ),

            // Botón para cancelar si está pendiente
            if (appointment.estado == 'pendiente') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancelar Solicitud'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _handleCancelAppointment(appointment),
                ),
              ),
            ],

            // Botón "Contactar Kine" si está confirmada
            if (appointment.estado == 'confirmada') ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Contactar Kine'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    // Aquí va la navegación real a la pantalla de chat
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Ir al chat con ${appointment.kineNombre}',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
