// lib/screens/kine_panel_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/models/appointment.dart';
import 'package:kine_app/services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// Importa tu pantalla de chat si ya la tienes
// import 'package:kine_app/screens/chat_screen.dart';

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

  // Maneja la acción de Aceptar o Denegar una cita
  void _handleUpdateStatus(Appointment appointment, String newStatus) async {
    try {
      await _appointmentService.updateAppointmentStatus(appointment, newStatus);
      if (mounted) {
        // Muestra mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // <-- CÓDIGO RESTAURADO
            content: Text(
              'Cita ${newStatus == 'confirmada' ? 'confirmada' : 'rechazada'}.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Muestra mensaje de error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // <-- CÓDIGO RESTAURADO
            content: Text('Error al actualizar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Muestra el modal con los detalles del paciente y botón de chat
  void _showPatientDetailsModal(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      // <-- CÓDIGO RESTAURADO
      context: context, // <-- Parámetro 'context' restaurado
      isScrollControlled: true,
      builder: (ctx) {
        // Contenido del Modal (igual que antes)
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
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Enviar Mensaje'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Cierra el modal
                  // Navega al chat (debes implementar ChatScreen)
                  /*
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => ChatScreen(
                       receiverId: appointment.pacienteId,
                       receiverName: appointment.pacienteNombre,
                     ),
                   ),
                 );
                 */
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Navegando al chat con ${appointment.pacienteNombre}...',
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
          // Guarda la lista completa (o una lista vacía si no hay datos)
          _allAppointments = snapshot.data ?? [];

          // Construye siempre la UI, el filtrado se hace después
          return _buildCalendarAndList();
        },
      ),
    );
  }

  // Construye el Calendario y la Lista de Citas debajo
  Widget _buildCalendarAndList() {
    // Filtra las citas para el día seleccionado AHORA, dentro del build
    final selectedDayAppointments = _allAppointments.where((appointment) {
      final citaDate = appointment.fechaCitaDT;
      return isSameDay(citaDate, _selectedDay!); // Usa el _selectedDay actual
    }).toList()..sort((a, b) => a.fechaCita.compareTo(b.fechaCita));

    return Column(
      children: [
        TableCalendar<Appointment>(
          locale: 'es_ES',
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay, // Carga los marcadores
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
          // Cuando el usuario selecciona un día diferente
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              // Actualiza el estado (_selectedDay) y redibuja
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
                // No filtramos aquí, el rebuild lo hará
              });
            }
          },
          // Cuando cambia el formato (mes/semana)
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          // Cuando cambia la página del calendario
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay; // Solo actualiza el día enfocado
          },
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            // Muestra la fecha seleccionada
            'Citas para: ${DateFormat('EEE, dd MMMM', 'es_ES').format(_selectedDay!)}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          // Pasa la lista YA FILTRADA al widget que dibuja la lista
          child: _buildAppointmentList(selectedDayAppointments),
        ),
      ],
    );
  }

  // Construye la lista de citas para el día seleccionado
  Widget _buildAppointmentList(List<Appointment> appointmentsForDay) {
    // Mensaje si el Kine no tiene NINGUNA cita en total
    if (_allAppointments.isEmpty) {
      return const Center(child: Text('Aún no tienes ninguna cita.'));
    }
    // Mensaje si no hay citas PARA ESE DÍA específico
    if (appointmentsForDay.isEmpty) {
      return const Center(
        child: Text('No hay citas programadas para este día.'),
      );
    }

    // Separa las citas pendientes de las otras
    final pendientes = appointmentsForDay
        .where((a) => a.estado == 'pendiente')
        .toList();
    final otras = appointmentsForDay
        .where((a) => a.estado != 'pendiente')
        .toList();

    // Dibuja la lista
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        // Sección de Citas Pendientes
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
          ...pendientes.map(
            (app) => _buildAppointmentCard(app),
          ), // Dibuja una tarjeta por cada cita pendiente
          if (otras.isNotEmpty)
            const Divider(height: 30, indent: 20, endIndent: 20),
        ],
        // Sección de Citas Confirmadas/Denegadas
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
          ...otras.map(
            (app) => _buildAppointmentCard(app),
          ), // Dibuja una tarjeta por cada otra cita
        ],
      ],
    );
  }

  // Construye la tarjeta individual para mostrar una cita
  Widget _buildAppointmentCard(Appointment appointment) {
    final hora = DateFormat('HH:mm').format(appointment.fechaCitaDT);
    IconData estadoIcon;
    Color estadoColor;

    // Elige ícono y color según el estado
    switch (appointment.estado) {
      case 'confirmada':
        estadoIcon = Icons.check_circle;
        estadoColor = Colors.green;
        break;
      case 'denegada':
        estadoIcon = Icons.cancel;
        estadoColor = Colors.red;
        break;
      case 'completada': // Podrías añadir este estado si lo necesitas
        estadoIcon = Icons.check_box;
        estadoColor = Colors.blueGrey;
        break;
      case 'pendiente':
      default:
        estadoIcon = Icons.hourglass_top;
        estadoColor = Colors.orange.shade800;
        break;
    }

    // Dibuja la tarjeta
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
            trailing: Icon(
              Icons.info_outline,
              color: Colors.blue.shade700,
            ), // Ícono para indicar que se puede tocar
          ),
          // Muestra los botones solo si la cita está pendiente
          if (appointment.estado == 'pendiente')
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text(
                      'Denegar',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: () => _handleUpdateStatus(
                      appointment,
                      'denegada',
                    ), // Llama a la función al presionar
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text('Aceptar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _handleUpdateStatus(
                      appointment,
                      'confirmada',
                    ), // Llama a la función al presionar
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
