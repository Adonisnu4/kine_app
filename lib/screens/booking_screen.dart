// lib/screens/booking_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/services/appointment_service.dart';
import 'package:kine_app/services/availability_service.dart'; // Importa el servicio de disponibilidad
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

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
  // Servicios y datos del usuario
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService =
      AvailabilityService(); // Servicio de disponibilidad
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // Estado de la pantalla
  DateTime _selectedDate = DateTime.now(); // Día seleccionado en el calendario
  int?
  _selectedTimeSlot; // Índice del horario seleccionado en la lista _availableSlotsForDay
  bool _isCheckingPending =
      true; // Cargando la verificación inicial de cita pendiente
  bool _isLoadingSlots = true; // Cargando los horarios disponibles para el día
  bool _isBooking = false; // Enviando la solicitud de cita
  bool _hasPending =
      false; // Indica si el usuario ya tiene cita pendiente con ESTE Kine

  // Lista dinámica de horarios disponibles para el _selectedDate
  List<TimeOfDay> _availableSlotsForDay = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = _findNextAvailableWorkDay(
      DateTime.now(),
    ); // Inicia en el próximo día hábil
    _checkPendingAppointments(); // Verifica si ya tiene cita con este Kine
    _loadSlotsForSelectedDay(); // Carga los horarios para el día inicial
  }

  // Carga los horarios disponibles desde Firestore para el _selectedDate
  Future<void> _loadSlotsForSelectedDay() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true; // Muestra indicador de carga
      _selectedTimeSlot = null; // Resetea la selección de hora
      _availableSlotsForDay = []; // Limpia horarios anteriores
    });
    try {
      // Llama al servicio para obtener los TimeOfDay disponibles
      final slots = await _availabilityService.getAvailableSlotsForDay(
        widget.kineId,
        _selectedDate,
      );
      if (mounted) {
        setState(() {
          _availableSlotsForDay = slots; // Guarda los horarios encontrados
          _isLoadingSlots = false; // Oculta indicador de carga
        });
      }
    } catch (e) {
      print("Error cargando slots disponibles: $e");
      if (mounted) {
        setState(() {
          _isLoadingSlots = false;
        }); // Oculta indicador incluso si hay error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar horarios: ${e.toString()}'),
            backgroundColor: Colors.red,
          ), // Muestra error
        );
      }
    }
  }

  // Calcula el próximo día hábil (Lunes a Viernes) a partir de una fecha dada
  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;
    // Si ya pasó la última hora de hoy (ej: 16:00), considera a partir de mañana
    if (date.isAfter(DateTime(date.year, date.month, date.day, 16, 0))) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    // Avanza día a día hasta encontrar un día entre Lunes y Viernes
    while (tempDate.weekday == DateTime.saturday ||
        tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return tempDate;
  }

  // Verifica si el paciente ya tiene una cita pendiente con este Kine específico
  void _checkPendingAppointments() async {
    try {
      final hasPending = await _appointmentService.hasPendingAppointment(
        _currentUserId,
        widget.kineId, // Pasa el ID del Kine actual
      );
      if (mounted) {
        setState(() {
          _hasPending = hasPending;
        });
      }
    } catch (e) {
      print('Error al verificar citas pendientes con este Kine: $e');
      if (mounted) {
        setState(() {
          _hasPending = false;
        }); // Asume que no para permitir intento
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al verificar historial: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Siempre quita el indicador de carga inicial
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
      firstDate: DateTime.now(), // No agendar en el pasado
      lastDate: DateTime.now().add(
        const Duration(days: 90),
      ), // Límite (ej: 90 días)
      selectableDayPredicate: (DateTime day) =>
          day.weekday != DateTime.saturday &&
          day.weekday != DateTime.sunday, // Solo Lunes a Viernes
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
    if (_selectedTimeSlot == null) return; // Requiere hora seleccionada
    setState(() {
      _isBooking = true;
    }); // Activa indicador en botón

    try {
      // Obtiene el TimeOfDay seleccionado de la lista dinámica
      final slotTime = _availableSlotsForDay[_selectedTimeSlot!];
      // Combina fecha y hora
      // --- 👇 ARGUMENTOS RESTAURADOS ---
      final fullDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        slotTime.hour,
        slotTime.minute,
      );
      // --- FIN RESTAURACIÓN ---

      // Re-verifica si tiene pendiente con este Kine justo antes de guardar
      final hasPendingNow = await _appointmentService.hasPendingAppointment(
        _currentUserId,
        widget.kineId,
      );
      if (hasPendingNow) {
        setState(() {
          _hasPending = true;
        });
        throw Exception(
          'Ya tienes una cita pendiente con este kinesiólogo. Espera a que sea gestionada.',
        );
      }

      // Re-verifica si el slot fue tomado por otro usuario mientras tanto
      final isTaken = await _appointmentService.isSlotTaken(
        widget.kineId,
        fullDateTime,
      );
      if (isTaken) {
        _loadSlotsForSelectedDay(); // Recarga slots para mostrar actualización
        throw Exception(
          'Este horario acaba de ser reservado. Por favor, selecciona otro.',
        );
      }

      // Si todo OK, crea la cita
      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      // Muestra éxito y cierra
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
      // Muestra cualquier error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Desactiva indicador en botón
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  // Navega al chat (placeholder)
  void _navigateToChat() {
    /* Código real si tienes ChatScreen
    Navigator.push(context, MaterialPageRoute(builder: (context) =>
      ChatScreen(receiverId: widget.kineId, receiverName: widget.kineNombre),
    )); */
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navegando al chat con ${widget.kineNombre}...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de carga inicial
    if (_isCheckingPending) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Pantalla si ya tiene cita pendiente con este Kine
    if (_hasPending) {
      // --- 👇 MENSAJE PENDIENTE RESTAURADO ---
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
      // --- FIN RESTAURACIÓN ---
    }

    // --- Pantalla Principal de Agendamiento ---
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
            // --- Selector de Fecha ---
            Text(
              '1. Selecciona el día',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            // --- 👇 ROW RESTAURADO ---
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
            // --- FIN RESTAURACIÓN ---
            const Divider(height: 30),

            // --- Selector de Hora ---
            Text(
              '2. Selecciona la hora',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Muestra indicador si carga horarios, sino la grilla
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

            // --- Botón de Chat ---
            // --- 👇 CENTER RESTAURADO ---
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
            // --- FIN RESTAURACIÓN ---
            const SizedBox(height: 25),

            // --- Botón Solicitar Cita ---
            // --- 👇 ELEVATEDBUTTON RESTAURADO ---
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
            // --- FIN RESTAURACIÓN ---
          ],
        ),
      ),
    );
  }

  // Widget que construye la grilla de horarios
  Widget _buildTimeSlotGrid() {
    // Mensaje si no hay horarios definidos
    if (_availableSlotsForDay.isEmpty) {
      // --- 👇 CONTAINER RESTAURADO ---
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
      // --- FIN RESTAURACIÓN ---
    }

    // Construye la grilla
    // --- 👇 GRIDVIEW.BUILDER RESTAURADO ---
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 Horarios por fila
        childAspectRatio: 2.8, // Ajusta la proporción ancho/alto
        mainAxisSpacing: 12, // Espacio vertical
        crossAxisSpacing: 12, // Espacio horizontal
      ),
      itemCount: _availableSlotsForDay.length, // Usa la lista dinámica
      itemBuilder: (context, index) {
        final slot = _availableSlotsForDay[index]; // Usa la lista dinámica
        final isSelected =
            _selectedTimeSlot == index; // Comprueba si está seleccionado
        final fullDateTime = DateTime(
          // Combina fecha y hora
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          slot.hour,
          slot.minute,
        );

        // Si el horario ya pasó, lo deshabilita
        if (fullDateTime.isBefore(DateTime.now())) {
          return ChoiceChip(
            // Chip deshabilitado
            label: Text(slot.format(context)),
            selected: false,
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: Colors.grey.shade400,
              decoration: TextDecoration.lineThrough,
            ),
            onSelected: null, // No seleccionable
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          );
        }

        // Si es futuro, verifica si está ocupado
        return FutureBuilder<bool>(
          future: _appointmentService.isSlotTaken(
            widget.kineId,
            fullDateTime,
          ), // Llama al servicio
          builder: (context, snapshot) {
            final isTaken = snapshot.data == true;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            // Dibuja el chip normal, ocupado o cargando
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
                      }); // Actualiza selección
                    },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: isSelected
                      ? Colors.blue.shade700
                      : (isTaken ? Colors.red.shade200 : Colors.grey.shade300),
                ),
              ),
              showCheckmark: false, // Sin marca de check
            );
          },
        ); // Fin FutureBuilder
      }, // Fin itemBuilder
    ); // Fin GridView.builder
    // --- FIN RESTAURACIÓN ---
  } // Fin _buildTimeSlotGrid
} // Fin clase _BookingScreenState
