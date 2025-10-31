// lib/screens/booking_screen.dart

import 'package:flutter/material.dart';
// ⚠️ Rutas corregidas para tu estructura:
import 'package:kine_app/features/Appointments/services/appointment_service.dart';
import 'package:kine_app/features/Appointments/services/availability_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

// 🚀 AÑADIR ESTE IMPORT: Para navegar directamente a la pantalla de chat
import 'package:kine_app/features/Chat/screens/chat_screen.dart';
// (Asegúrate que esta ruta a ChatScreen.dart sea correcta)

/// Pantalla para agendar una nueva cita con un kinesiólogo específico.
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
  // Instancias de servicios para interactuar con la base de datos
  final AppointmentService _appointmentService = AppointmentService();
  final AvailabilityService _availabilityService = AvailabilityService();
  // ID del usuario actual logueado para registrar la cita
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  // --- Estados de la Pantalla ---
  DateTime _selectedDate = DateTime.now(); // Día seleccionado para la cita
  int? _selectedTimeSlot; // Índice del horario seleccionado en la lista
  bool _isCheckingPending =
      true; // Indica si se está verificando historial (carga inicial)
  bool _isLoadingSlots =
      true; // Indica si se están cargando los horarios para el día
  bool _isBooking = false; // Indica si se está enviando la solicitud de reserva

  // --- Estados para Restricciones de Citas (para evitar doble reserva) ---
  bool _hasPending =
      false; // True si tiene una cita PENDIENTE de aprobación con este Kine
  bool _hasConfirmed =
      false; // True si tiene una cita CONFIRMADA FUTURA con este Kine
  // --- Fin Estados de Restricciones ---

  // Lista de horarios disponibles (TimeOfDay) para el día seleccionado
  List<TimeOfDay> _availableSlotsForDay = [];

  @override
  void initState() {
    super.initState();
    // Inicializa con el próximo día hábil disponible, sin fines de semana o pasado el corte
    _selectedDate = _findNextAvailableWorkDay(DateTime.now());
    // Inicia la verificación de restricciones (pendiente/confirmada)
    _checkExistingAppointments();
    // Carga los horarios del día hábil inicial
    _loadSlotsForSelectedDay();
  }

  /// Carga los horarios disponibles desde Firestore para la fecha actual.
  Future<void> _loadSlotsForSelectedDay() async {
    if (!mounted) return;
    setState(() {
      _isLoadingSlots = true; // Activa el indicador de carga
      _selectedTimeSlot = null; // Reinicia el slot seleccionado
      _availableSlotsForDay = []; // Limpia los slots anteriores
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

  /// Calcula el próximo día hábil, saltando fines de semana y el día actual si ya
  /// pasó la hora de corte (16:00).
  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;
    // Si ya pasó la hora de corte (16:00), empieza la búsqueda desde mañana
    if (date.isAfter(DateTime(date.year, date.month, date.day, 16, 0))) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    // Salta fines de semana
    while (tempDate.weekday == DateTime.saturday ||
        tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    // Asegura que la hora se ponga a medianoche para evitar problemas de zona horaria
    return DateTime(tempDate.year, tempDate.month, tempDate.day);
  }

  /// Verifica si el paciente ya tiene citas pendientes O confirmadas con este Kine.
  Future<void> _checkExistingAppointments() async {
    setState(() {
      _isCheckingPending = true;
    });
    try {
      // Verifica ambos estados en paralelo para mayor eficiencia
      final results = await Future.wait([
        // 1. Verificar si hay cita PENDIENTE
        _appointmentService.hasPendingAppointment(
          _currentUserId,
          widget.kineId,
        ),
        // 2. Verificar si hay cita CONFIRMADA FUTURA
        _appointmentService.hasConfirmedAppointmentWithKine(
          _currentUserId,
          widget.kineId,
        ),
      ]);
      if (mounted) {
        setState(() {
          _hasPending = results[0]; // Actualiza el estado de pendiente
          _hasConfirmed = results[1]; // Actualiza el estado de confirmada
        });
      }
    } catch (e) {
      // Manejo de error, usualmente por falta de un índice compuesto en Firestore
      print('Error al verificar citas existentes: $e');
      if (mounted) {
        setState(() {
          _hasPending = false; // Asume que no hay cita si hay error
          _hasConfirmed = false; // Asume que no hay cita si hay error
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
          _isCheckingPending = false; // Finaliza la carga inicial
        });
      }
    }
  }

  /// Muestra el selector de fechas y actualiza el estado.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 90),
      ), // Agendar hasta 90 días
      // Predicado: Solo días de Lunes a Viernes
      selectableDayPredicate: (DateTime day) =>
          day.weekday != DateTime.saturday && day.weekday != DateTime.sunday,
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadSlotsForSelectedDay(); // Recarga horarios al cambiar de día
    }
  }

  /// Procesa la solicitud de cita al profesional.
  void _handleBooking() async {
    if (_selectedTimeSlot == null) return; // No hay hora seleccionada
    setState(() {
      _isBooking = true; // Inicia el proceso de reserva
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

      // --- Re-verificación de restricciones ANTES de guardar ---
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

      // Actualiza estados y lanza error si aplica
      if (mounted) {
        setState(() {
          _hasPending = hasPendingNow;
          _hasConfirmed = hasConfirmedNow;
        });
      }

      if (hasPendingNow) {
        throw Exception('Ya tienes una cita pendiente con este kinesiólogo.');
      }
      if (hasConfirmedNow) {
        throw Exception(
          'Ya tienes una cita confirmada activa con este kinesiólogo.',
        );
      }
      // --- Fin Re-verificación ---

      // Doble check final para ver si alguien más tomó el slot justo ahora
      final isTaken = await _appointmentService.isSlotTaken(
        widget.kineId,
        fullDateTime,
      );
      if (isTaken) {
        _loadSlotsForSelectedDay(); // Recarga los slots para reflejar el cambio
        throw Exception('Este horario acaba de ser reservado.');
      }

      // Procede con la solicitud de cita
      await _appointmentService.requestAppointment(
        kineId: widget.kineId,
        kineNombre: widget.kineNombre,
        fechaCita: fullDateTime,
      );

      // Muestra éxito y cierra la pantalla
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Solicitud enviada. Espera la confirmación.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Muestra error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al solicitar cita: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Siempre desactiva la carga
      if (mounted) {
        setState(() {
          _isBooking = false;
        });
      }
    }
  }

  /// Navega al chat con el kinesiólogo (AHORA IMPLEMENTADO).
  void _navigateToChat() {
    // 🚀 IMPLEMENTACIÓN REAL DE NAVEGACIÓN A CHAT
    // Se utiliza MaterialPageRoute, ya que se asume que no hay rutas nombradas AppRoutes.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          receiverId: widget.kineId,
          receiverName: widget.kineNombre,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Pantalla de Carga Inicial
    if (_isCheckingPending) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- 2. Bloques de Restricción ---
    // Muestra un mensaje si ya tiene una cita PENDIENTE
    if (_hasPending) {
      return _buildRestrictionScreen(
        icon: Icons.info_outline,
        iconColor: Colors.blue.shade700,
        title: 'Ya tienes una cita pendiente',
        message:
            'Espera a que esta solicitud sea confirmada o rechazada antes de agendar una nueva con el/la mismo(a) profesional.',
      );
    }
    // Muestra un mensaje si ya tiene una cita CONFIRMADA (Futura)
    if (_hasConfirmed) {
      return _buildRestrictionScreen(
        icon: Icons.check_circle_outline,
        iconColor: Colors.green.shade700,
        title: 'Cita ya Confirmada',
        message:
            'Ya tienes una cita confirmada activa con ${widget.kineNombre}. No puedes tomar otra hora.',
      );
    }
    // --- Fin Bloques de Restricción ---

    // 3. Pantalla Principal de Agendamiento
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
            // Sección 1: Selector de Fecha
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
                  // Formatea la fecha seleccionada (ej: Jue, 30 Octubre 2025)
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

            // Sección 2: Selector de Hora (Grilla)
            Text(
              '2. Selecciona la hora',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            // Muestra indicador de carga o la grilla de horarios
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

            // Botón de Chat (AHORA FUNCIONAL)
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                label: Text('¿Dudas? Enviar Mensaje a ${widget.kineNombre}'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.teal.shade700,
                ),
                onPressed: _navigateToChat, // Llama a la función corregida
              ),
            ),
            const SizedBox(height: 25),

            // Botón Solicitar Cita (Deshabilitado si no hay slot o está reservando)
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
                  ? null // Deshabilita si no hay slot seleccionado o está en proceso
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

  /// Widget de utilidad para mostrar las pantallas de restricción (pendiente/confirmada).
  Widget _buildRestrictionScreen({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Cita')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 60),
              const SizedBox(height: 20),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
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

  /// Widget que construye la grilla de horarios disponibles (ChoiceChip).
  Widget _buildTimeSlotGrid() {
    // Mensaje si no hay horarios
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
      physics:
          const NeverScrollableScrollPhysics(), // Deshabilita scroll interno
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

        // Combina fecha y hora para una comparación precisa
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
            backgroundColor: Colors.grey.shade200,
            labelStyle: TextStyle(
              color: Colors.grey.shade400,
              decoration: TextDecoration.lineThrough, // Tachado visual
            ),
            onSelected: null, // No seleccionable
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
          );
        }

        // FutureBuilder para verificar en tiempo real si el slot está ocupado por otro usuario
        return FutureBuilder<bool>(
          future: _appointmentService.isSlotTaken(widget.kineId, fullDateTime),
          builder: (context, snapshot) {
            final isTaken = snapshot.data == true;
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;

            // Muestra el chip del horario
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
                  ? null // No seleccionable si está tomado o cargando
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
              showCheckmark: false, // Oculta el checkmark predeterminado
            );
          },
        );
      },
    );
  }
} // Fin clase _BookingScreenState
