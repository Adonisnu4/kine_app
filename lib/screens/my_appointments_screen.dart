// lib/screens/my_appointments_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import necesario si usas el placeholder
import 'package:kine_app/models/appointment.dart'; // Asegúrate que la ruta sea correcta
import 'package:kine_app/services/appointment_service.dart'; // Asegúrate que la ruta sea correcta
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// Puedes importar estas si quieres añadir navegación al perfil del Kine o al chat
// import 'kine_presentation_screen.dart';
// import 'chat_screen.dart';

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
    // Obtiene el stream de citas para el usuario actual
    _appointmentsStream = _appointmentService.getPatientAppointments(
      _currentUserId,
    );
  }

  // Función para manejar la cancelación de una cita pendiente
  void _handleCancelAppointment(Appointment appointment) async {
    // Pide confirmación al usuario
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Cita'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar esta solicitud de cita?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // No cancelar
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), // Sí cancelar
            child: const Text('Sí, Cancelar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    // Si el usuario confirmó
    if (confirm == true) {
      try {
        // Llama a la función del servicio para eliminar la cita
        await _appointmentService.deleteAppointment(appointment.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
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
      body: StreamBuilder<List<Appointment>>(
        stream: _appointmentsStream, // Escucha el stream de citas
        builder: (context, snapshot) {
          // Muestra indicador mientras carga
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Muestra error si falla la carga
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar citas: ${snapshot.error}'),
            );
          }
          // Muestra mensaje si no hay citas
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

          // Si hay datos, muestra la lista
          final appointments = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              // Construye una tarjeta por cada cita
              return _buildAppointmentCard(appointment);
            },
          );
        },
      ),
    );
  }

  // Widget para construir la tarjeta de una cita
  Widget _buildAppointmentCard(Appointment appointment) {
    IconData estadoIcon;
    Color estadoColor;
    String estadoTexto = appointment.estado.toUpperCase();

    // Determina ícono, color y texto según el estado
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nombre del Kine
                Flexible(
                  // Evita overflow si el nombre es largo
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
                // Estado
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
            // Fecha y Hora
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

            // Botones de acción condicionales
            // Botón Cancelar (si está pendiente)
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
            // Botón Contactar (si está confirmada)
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
                    // Aquí iría la navegación a tu pantalla de chat
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
