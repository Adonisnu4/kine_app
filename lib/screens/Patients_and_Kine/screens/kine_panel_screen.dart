// lib/screens/kine_panel_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// ⚠️ Ajusta estas rutas si es necesario:
import 'package:kine_app/screens/Appointments/models/appointment.dart';
import 'package:kine_app/screens/Appointments/services/appointment_service.dart';
import 'package:kine_app/screens/Chat/screens/chat_screen.dart'; // Importación necesaria para la navegación al chat

class KinePanelScreen extends StatefulWidget {
  const KinePanelScreen({super.key});
  @override
  State<KinePanelScreen> createState() => _KinePanelScreenState();
}

class _KinePanelScreenState extends State<KinePanelScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;

  late Stream<List<Appointment>> _appointmentsStream;
  List<Appointment> _allAppointments = [];

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _appointmentsStream = _appointmentService.getKineAppointments(
      _currentKineId,
    );
  }

  // Devuelve la lista de citas (eventos) para marcar en el calendario
  List<Appointment> _getEventsForDay(DateTime day) {
    return _allAppointments.where((appointment) {
      // Solo marcar citas pendientes o confirmadas
      if (appointment.estado == 'confirmada' ||
          appointment.estado == 'pendiente') {
        return isSameDay(appointment.fechaCitaDT, day);
      }
      return false;
    }).toList();
  }

  /// Maneja la acción de Aceptar, Denegar o CANCELAR una cita.
  void _handleUpdateStatus(Appointment appointment, String newStatus) async {
    // 1. CONFIRMACIÓN (Solo para cancelación)
    if (newStatus == 'cancelada') {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmar Cancelación'),
          content: Text(
            '¿Estás seguro de cancelar esta cita confirmada con ${appointment.pacienteNombre}? Se notificará al paciente por correo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No, Mantener'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Sí, Cancelar Cita',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    // 2. ACTUALIZACIÓN DEL ESTADO (El servicio valida que no sea una cita pasada)
    try {
      await _appointmentService.updateAppointmentStatus(appointment, newStatus);
      if (mounted) {
        String message;
        Color color;

        if (newStatus == 'confirmada') {
          message = 'Cita confirmada.';
          color = Colors.green;
        } else if (newStatus == 'denegada') {
          message = 'Cita rechazada.';
          color = Colors.orange;
        } else if (newStatus == 'cancelada') {
          message = 'Cita cancelada con éxito. Se envió un correo al paciente.';
          color = Colors.red.shade700;
        } else {
          message = 'Estado actualizado.';
          color = Colors.blue;
        }

        // Muestra mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: color),
        );
      }
    } catch (e) {
      if (mounted) {
        // Muestra mensaje de error (incluye la excepción si la cita ya pasó)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Muestra el modal con los detalles del paciente y el botón de chat funcional.
  void _showPatientDetailsModal(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.pacienteNombre,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Detalles de email, fecha, estado
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.email_outlined, color: Colors.grey[600]),
                title: Text(appointment.pacienteEmail ?? 'No disponible'),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.calendar_today_outlined,
                  color: Colors.grey[600],
                ),
                title: Text(
                  'Cita: ${DateFormat('EEE, dd MMMM, HH:mm', 'es_ES').format(appointment.fechaCitaDT)}',
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.info_outline, color: Colors.grey[600]),
                title: Text('Estado: ${appointment.estado.toUpperCase()}'),
              ),
              const SizedBox(height: 20),

              // 🚀 BOTÓN DE CHAT CORREGIDO: Navegación real
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Enviar Mensaje'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Cierra el modal

                  // Inicia navegación real al chat
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        receiverId: appointment.pacienteId,
                        receiverName: appointment
                            .pacienteNombre, // Usando la ruta nombrada estática
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Citas'),
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          _allAppointments = snapshot.data ?? [];
          return _buildCalendarAndList();
        },
      ),
    );
  }

  // Construye el Calendario y la Lista de Citas debajo
  Widget _buildCalendarAndList() {
    final selectedDayAppointments = _allAppointments.where((appointment) {
      final citaDate = appointment.fechaCitaDT;
      return isSameDay(citaDate, _selectedDay!);
    }).toList()..sort((a, b) => a.fechaCita.compareTo(b.fechaCita));

    return Column(
      children: [
        // ... (TableCalendar - Lógica original) ...
        TableCalendar<Appointment>(
          locale: 'es_ES',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          startingDayOfWeek: StartingDayOfWeek.monday,
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Colors.tealAccent,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonShowsNext: false,
            titleCentered: true,
          ),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            }
          },
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Citas para: ${DateFormat('EEE, dd MMMM', 'es_ES').format(_selectedDay!)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildAppointmentList(selectedDayAppointments)),
      ],
    );
  }

  // Construye la lista de citas para el día seleccionado
  Widget _buildAppointmentList(List<Appointment> appointmentsForDay) {
    if (_allAppointments.isEmpty) {
      return const Center(child: Text('Aún no tienes ninguna cita.'));
    }
    if (appointmentsForDay.isEmpty) {
      return const Center(
        child: Text('No hay citas programadas para este día.'),
      );
    }

    final pendientes = appointmentsForDay
        .where((a) => a.estado == 'pendiente')
        .toList();
    final otras = appointmentsForDay
        .where((a) => a.estado != 'pendiente')
        .toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        if (pendientes.isNotEmpty) ...[
          Text(
            ' Pendientes de Confirmación',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.orange.shade800,
            ),
          ),
          const SizedBox(height: 8),
          ...pendientes.map((app) => _buildAppointmentCard(app)),
          if (otras.isNotEmpty)
            const Divider(height: 30, indent: 20, endIndent: 20),
        ],
        // Sección de Citas Confirmadas/Denegadas (y Canceladas)
        if (otras.isNotEmpty) ...[
          Text(
            ' Citas Programadas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          ...otras.map((app) => _buildAppointmentCard(app)),
        ],
      ],
    );
  }

  // Construye la tarjeta individual para mostrar una cita
  Widget _buildAppointmentCard(Appointment appointment) {
    final hora = DateFormat('HH:mm').format(appointment.fechaCitaDT);
    IconData estadoIcon;
    Color estadoColor;

    // CONDICIÓN DE TIEMPO: Comprueba si la cita ya ha pasado
    final bool isPastAppointment = appointment.fechaCitaDT.isBefore(
      DateTime.now(),
    );

    switch (appointment.estado) {
      case 'confirmada':
        estadoIcon = Icons.check_circle;
        estadoColor = Colors.green;
        break;
      case 'denegada':
        estadoIcon = Icons.cancel;
        estadoColor = Colors.red;
        break;
      case 'completada':
        estadoIcon = Icons.check_box;
        estadoColor = Colors.blueGrey;
        break;
      case 'cancelada': // Nuevo estado
        estadoIcon = Icons.close;
        estadoColor = Colors.red.shade700;
        break;
      case 'pendiente':
      default:
        estadoIcon = Icons.hourglass_top;
        estadoColor = Colors.orange.shade800;
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            onTap: () => _showPatientDetailsModal(
              context,
              appointment,
            ), // Abre el modal al tocar
            leading: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hora,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            title: Text(
              appointment.pacienteNombre,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Row(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 16),
                const SizedBox(width: 4),
                Text(
                  appointment.estado.toUpperCase(),
                  style: TextStyle(
                    color: estadoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Icon(Icons.info_outline, color: Colors.blue.shade700),
          ),

          // --- Sección de Botones ---
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 1. Botones para citas PENDIENTES
                if (appointment.estado == 'pendiente') ...[
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Denegar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () =>
                        _handleUpdateStatus(appointment, 'denegada'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () =>
                        _handleUpdateStatus(appointment, 'confirmada'),
                  ),
                ],

                // 2. Botón para citas CONFIRMADAS (Aparece solo si NO ha pasado la hora)
                if (appointment.estado == 'confirmada' && !isPastAppointment)
                  TextButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text(
                      'Cancelar Cita',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () => _handleUpdateStatus(
                      appointment,
                      'cancelada', // NUEVO ESTADO DE CANCELACIÓN
                    ),
                  ),

                // 3. INDICADOR para citas CONFIRMADAS PASADAS (No se pueden cancelar)
                if (appointment.estado == 'confirmada' && isPastAppointment)
                  Text(
                    'Cita Finalizada',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          // --- Fin de Sección de Botones ---
        ],
      ),
    );
  }
}
