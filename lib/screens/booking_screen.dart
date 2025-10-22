// lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/services/appointment_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 👈 IMPORTA TU PANTALLA DE CHAT (Ajusta la ruta si es necesario)
// import 'package:kine_app/screens/chat_screen.dart';

class BookingScreen extends StatefulWidget {
  final String kineId;
  final String kineNombre;

  const BookingScreen({
    super.key,
    required this.kineId,
    required this.kineNombre,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _selectedDate = DateTime.now();
  int? _selectedTimeSlot;
  bool _isCheckingPending = true;
  bool _isBooking = false;
  bool _hasPending = false;

  List<TimeOfDay> _getAvailableSlots(DateTime date) {
    if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
      return [];
    }
    return [
      const TimeOfDay(hour: 9, minute: 0),
      const TimeOfDay(hour: 10, minute: 0),
      const TimeOfDay(hour: 11, minute: 0),
      const TimeOfDay(hour: 12, minute: 0),
      const TimeOfDay(hour: 14, minute: 0),
      const TimeOfDay(hour: 15, minute: 0),
      const TimeOfDay(hour: 16, minute: 0),
    ];
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = _findNextAvailableDay(DateTime.now());
    _checkPendingAppointments();
  }

  DateTime _findNextAvailableDay(DateTime date) {
    DateTime tempDate = date;
    if (date.isAfter(DateTime(date.year, date.month, date.day, 16, 0))) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    if (tempDate.weekday == DateTime.saturday) {
      tempDate = tempDate.add(const Duration(days: 2));
    } else if (tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return tempDate;
  }

  void _checkPendingAppointments() async {
    try {
      final hasPending = await _appointmentService.hasPendingAppointment(
        _currentUserId,
      );
      if (mounted) {
        setState(() {
          _hasPending = hasPending;
        });
      }
    } catch (e) {
      print('Error al verificar citas pendientes: $e');
      if (mounted) {
        setState(() {
          _hasPending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar historial: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPending = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
      selectableDayPredicate: (DateTime day) {
        if (day.weekday == DateTime.saturday ||
            day.weekday == DateTime.sunday) {
          return false;
        }
        return true;
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null;
      });
    }
  }

  void _handleBooking() async {
    if (_selectedTimeSlot == null) return;
    setState(() {
      _isBooking = true;
    });

    try {
      final slotTime = _getAvailableSlots(_selectedDate)[_selectedTimeSlot!];
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slotTime.hour,
        slotTime.minute,
      );

      final hasPendingNow = await _appointmentService.hasPendingAppointment(
        _currentUserId,
      );
      if (hasPendingNow) {
        setState(() {
          _hasPending = true;
        });
        throw Exception(
          'Ya tienes una cita pendiente. Espera a que sea gestionada.',
        );
      }

      final isTaken = await _appointmentService.isSlotTaken(
        widget.kineId,
        fullDateTime,
      );
      if (isTaken) {
        throw Exception(
          'Este horario acaba de ser reservado. Por favor, selecciona otro.',
        );
      }

      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud de cita enviada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  void _navigateToChat() {
    /* // CÓDIGO REAL (debes crear ChatScreen)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: widget.kineId,
          receiverName: widget.kineNombre,
        ),
      ),
    );
    */
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando al chat con ${widget.kineNombre}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPending) {
      return const Scaffold(
        appBar: null,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hasPending) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agendar Cita')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 60),
                const SizedBox(height: 20),
                Text(
                  'Ya tienes una cita pendiente',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Por favor, espera a que el kinesiólogo confirme o deniegue tu solicitud actual antes de agendar una nueva.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Entendido'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Agendar con ${widget.kineNombre}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '1. Selecciona el día',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  DateFormat(
                    'EEE, dd MMMM yyyy',
                    'es_ES',
                  ).format(_selectedDate),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.blue),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Cambiar'),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const Divider(height: 30),

            Text(
              '2. Selecciona la hora',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            _buildTimeSlotGrid(),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text('Mandar Mensaje a ${widget.kineNombre}'),
                style: TextButton.styleFrom(foregroundColor: Colors.teal),
                onPressed: _navigateToChat,
              ),
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: _isBooking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: Text(_isBooking ? 'Solicitando...' : 'Solicitar Cita'),
              onPressed: (_selectedTimeSlot == null || _isBooking)
                  ? null
                  : _handleBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotGrid() {
    final slots = _getAvailableSlots(_selectedDate);
    if (slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No hay horarios disponibles para este día (Fin de semana).',
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) {
        final slot = slots[index];
        final isSelected = _selectedTimeSlot == index;

        final fullDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot.hour,
          slot.minute,
        );

        if (fullDateTime.isBefore(DateTime.now())) {
          return ChoiceChip(
            label: Text(slot.format(context)),
            selected: false,
            backgroundColor: Colors.grey.shade100,
            labelStyle: TextStyle(
              color: Colors.grey.shade400,
              decoration: TextDecoration.lineThrough,
            ),
            onSelected: null,
          );
        }

        return FutureBuilder<bool>(
          future: _appointmentService.isSlotTaken(widget.kineId, fullDateTime),
          builder: (context, snapshot) {
            final isTaken = snapshot.data == true;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            return ChoiceChip(
              label: Text(slot.format(context)),
              selected: isSelected,
              backgroundColor: isLoading
                  ? Colors.grey.shade200
                  : (isTaken ? Colors.red.shade100 : Colors.white),
              selectedColor: Colors.blue,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isTaken || isLoading)
                    ? Colors.grey.shade400
                    : Colors.black,
                decoration: (isTaken && !isLoading)
                    ? TextDecoration.lineThrough
                    : null,
              ),
              onSelected: (isTaken || isLoading)
                  ? null
                  : (selected) {
                      setState(() {
                        _selectedTimeSlot = selected ? index : null;
                      });
                    },
            );
          },
        );
      },
    );
  }
}
