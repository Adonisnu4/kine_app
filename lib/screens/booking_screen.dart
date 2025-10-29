// lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/services/appointment_service.dart';
// --- 👇 IMPORT FALTANTE (SOLUCIONA ERROR 2) 👇 ---
import 'package:kine_app/services/availability_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

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
  final AvailabilityService _availabilityService = AvailabilityService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _selectedDate = DateTime.now();
  int? _selectedTimeSlot;
  bool _isCheckingPending = true; // Cargando verificación inicial
  bool _isLoadingSlots = true; // Cargando horarios del día
  bool _isBooking = false;

  // --- 👇 NUEVOS ESTADOS PARA RESTRICCIONES 👇 ---
  bool _hasPending = false; // Tiene pendiente con este Kine
  bool _hasConfirmed = false; // Tiene confirmada FUTURA con este Kine
  // --- FIN NUEVOS ESTADOS ---

  List<TimeOfDay> _availableSlotsForDay = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = _findNextAvailableWorkDay(DateTime.now());
    _checkExistingAppointments(); // Verifica AMBAS restricciones
    _loadSlotsForSelectedDay();
  }

  // Carga los horarios disponibles desde Firestore
  Future<void> _loadSlotsForSelectedDay() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true;
      _selectedTimeSlot = null;
      _availableSlotsForDay = [];
    });
    try {
      final slots = await _availabilityService.getAvailableSlotsForDay(
        widget.kineId,
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _availableSlotsForDay = slots;
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar horarios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Calcula el próximo día hábil
  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;
    // Si ya pasó la hora de corte hoy, empieza mañana
    if (date.isAfter(DateTime(date.year, date.month, date.day, 16, 0))) {
      // Asume hora de corte 16:00
      tempDate = tempDate.add(const Duration(days: 1));
    }
    // Salta fines de semana
    while (tempDate.weekday == DateTime.saturday ||
        tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return tempDate;
  }

  /// Verifica si el paciente tiene citas pendientes O confirmadas con este Kine
  Future<void> _checkExistingAppointments() async {
    setState(() {
      _isCheckingPending = true;
    });
    try {
      // Verifica ambos estados en paralelo
      final results = await Future.wait([
        _appointmentService.hasPendingAppointment(
          _currentUserId,
          widget.kineId,
        ),
        _appointmentService.hasConfirmedAppointmentWithKine(
          _currentUserId,
          widget.kineId,
        ), // Nueva verificación
      ]);
      if (mounted) {
        setState(() {
          _hasPending = results[0]; // Resultado de pendiente
          _hasConfirmed = results[1]; // Resultado de confirmada
        });
      }
    } catch (e) {
      print('Error al verificar citas existentes: $e');
      // --- ESTE ES EL ERROR 3: FALTA DE ÍNDICE ---
      // El 'e' (error) aquí es el 'failed-precondition'.
      // Necesitas crear el índice que te pide en el link.
      if (mounted) {
        setState(() {
          _hasPending = false;
          _hasConfirmed = false;
        }); // Asume que no si hay error
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

  // Muestra el selector de fechas
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      selectableDayPredicate: (DateTime day) =>
          day.weekday != DateTime.saturday && day.weekday != DateTime.sunday,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSlotsForSelectedDay(); // Recarga horarios al cambiar día
    }
  }

  // Procesa la solicitud de cita
  void _handleBooking() async {
    if (_selectedTimeSlot == null) return;
    setState(() {
      _isBooking = true;
    });
    try {
      final slotTime = _availableSlotsForDay[_selectedTimeSlot!];
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slotTime.hour,
        slotTime.minute,
      );

      // --- RE-VERIFICACIÓN ANTES DE GUARDAR ---
      // Llama de nuevo por si el estado cambió mientras elegía hora
      final results = await Future.wait([
        _appointmentService.hasPendingAppointment(
          _currentUserId,
          widget.kineId,
        ),
        _appointmentService.hasConfirmedAppointmentWithKine(
          _currentUserId,
          widget.kineId,
        ),
      ]);
      final hasPendingNow = results[0];
      final hasConfirmedNow = results[1];
      if (mounted) {
        setState(() {
          _hasPending = hasPendingNow;
          _hasConfirmed = hasConfirmedNow;
        });
      }

      // Lanza error si alguna de las dos es verdadera
      if (hasPendingNow) {
        throw Exception('Ya tienes una cita pendiente con este kinesiólogo.');
      }
      if (hasConfirmedNow) {
        throw Exception(
          'Ya tienes una cita confirmada activa con este kinesiólogo.',
        );
      }
      // --- FIN RE-VERIFICACIÓN ---

      final isTaken = await _appointmentService.isSlotTaken(
        widget.kineId,
        fullDateTime,
      );
      if (isTaken) {
        _loadSlotsForSelectedDay();
        throw Exception('Este horario acaba de ser reservado.');
      }

      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud enviada.'),
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

  // Navega al chat (placeholder)
  void _navigateToChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando al chat con ${widget.kineNombre}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Carga inicial
    if (_isCheckingPending) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- 👇 BLOQUES DE RESTRICCIÓN 👇 ---
    // Mensaje si ya tiene PENDIENTE
    if (_hasPending) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agendar Cita')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 60),
                const SizedBox(height: 20),
                Text(
                  'Ya tienes una cita pendiente con ${widget.kineNombre}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Espera a que esta solicitud sea confirmada o rechazada antes de agendar una nueva con el/la mismo(a) profesional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
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
    // Mensaje si ya tiene CONFIRMADA (FUTURA)
    if (_hasConfirmed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Agendar Cita')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade700,
                  size: 60,
                ),
                const SizedBox(height: 20),
                Text(
                  'Cita ya Confirmada',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'No puedes tomar otra hora con ${widget.kineNombre} porque su solicitud anterior fue aceptada. Ya tienes una cita confirmada activa.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
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
    // --- FIN BLOQUES DE RESTRICCIÓN ---

    // --- Pantalla Principal de Agendamiento (si pasa los filtros) ---
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
            // Selector de Fecha
            Text(
              '1. Selecciona el día',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  DateFormat(
                    'EEE, dd MMMM yyyy',
                    'es_ES',
                  ).format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('Cambiar'),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const Divider(height: 30),

            // Selector de Hora
            Text(
              '2. Selecciona la hora',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            _isLoadingSlots
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 30.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _buildTimeSlotGrid(),

            const SizedBox(height: 25),
            const Divider(),
            const SizedBox(height: 15),

            // Botón de Chat
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text('¿Dudas? Enviar Mensaje a ${widget.kineNombre}'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                ),
                onPressed: _navigateToChat,
              ),
            ),
            const SizedBox(height: 25),

            // Botón Solicitar Cita
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
                backgroundColor: Colors.blueAccent.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget que construye la grilla de horarios
  Widget _buildTimeSlotGrid() {
    if (_availableSlotsForDay.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(25),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'El kinesiólogo no tiene horarios disponibles para este día.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.8,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: _availableSlotsForDay.length,
      itemBuilder: (context, index) {
        final slot = _availableSlotsForDay[index];
        final isSelected = _selectedTimeSlot == index;
        final fullDateTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot.hour,
          slot.minute,
        );

        // --- SOLUCIÓN ERROR 4: HORAS PASADAS ---
        // Esta lógica comprueba si la hora del slot es ANTERIOR a la hora actual.
        // Si son las 21:20 de HOY, 14:00 de HOY es 'isBefore' y se deshabilita.
        // Si son las 21:20 de HOY, 14:00 de MAÑANA NO es 'isBefore' y SÍ se muestra.
        // ¡Esto es correcto!
        if (fullDateTime.isBefore(DateTime.now())) {
          return ChoiceChip(
            label: Text(slot.format(context)),
            selected: false,
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: Colors.grey.shade400,
              decoration: TextDecoration.lineThrough,
            ),
            onSelected: null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          );
        }

        // Verifica si el slot está ocupado por otra cita
        return FutureBuilder<bool>(
          future: _appointmentService.isSlotTaken(widget.kineId, fullDateTime),
          builder: (context, snapshot) {
            final isTaken = snapshot.data == true;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            // Muestra la hora como disponible (o cargando, u ocupada)
            return ChoiceChip(
              label: Text(slot.format(context)),
              selected: isSelected,
              backgroundColor: isLoading
                  ? Colors.grey.shade200
                  : (isTaken ? Colors.red.shade100 : Colors.white),
              selectedColor: Colors.blue.shade700,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isTaken || isLoading
                          ? Colors.grey.shade500
                          : Colors.black87),
                decoration: (isTaken && !isLoading)
                    ? TextDecoration.lineThrough
                    : null,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (isTaken || isLoading)
                  ? null
                  : (selected) {
                      setState(() {
                        _selectedTimeSlot = selected ? index : null;
                      });
                    },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? Colors.blue.shade700
                      : (isTaken ? Colors.red.shade200 : Colors.grey.shade300),
                ),
              ),
              showCheckmark: false,
            );
          },
        );
      },
    );
  } // Fin _buildTimeSlotGrid
} // Fin clase _BookingScreenState
