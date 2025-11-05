// lib/screens/manage_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/services/availability_service.dart'; // Importa el servicio
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // Necesitas este paquete

// 💡 IMPORTAMOS LOS DIÁLOGOS
import 'package:kine_app/shared/widgets/app_dialog.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final AvailabilityService _availabilityService = AvailabilityService();
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<TimeOfDay> _baseTimeSlots = [
    const TimeOfDay(hour: 8, minute: 0), // 8:00 AM
    const TimeOfDay(hour: 9, minute: 0), // 9:00 AM
    const TimeOfDay(hour: 10, minute: 0), // 10:00 AM
    const TimeOfDay(hour: 11, minute: 0), // 11:00 AM
    const TimeOfDay(hour: 12, minute: 0), // 12:00 PM (Añadido)
    const TimeOfDay(hour: 13, minute: 0), // 1:00 PM (Añadido)
    const TimeOfDay(hour: 14, minute: 0), // 2:00 PM
    const TimeOfDay(hour: 15, minute: 0), // 3:00 PM
    const TimeOfDay(hour: 16, minute: 0), // 4:00 PM
    const TimeOfDay(hour: 17, minute: 0), // 5:00 PM
    // (6:00 PM y 7:00 PM eliminados)
  ];

  Set<String> _selectedSlots = {};
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSavingWeek = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = _findNextAvailableWorkDay(DateTime.now());
    _focusedDay = _selectedDay;
    _loadAvailabilityForSelectedDay();
  }

  // (Funciones de SnackBar eliminadas, ya que todo usa popups)

  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;
    while (tempDate.weekday == DateTime.saturday ||
        tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return tempDate;
  }

  Future<void> _loadAvailabilityForSelectedDay() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _selectedSlots = {};
    });

    try {
      final savedSlots = await _availabilityService.getSavedAvailability(
        _currentKineId,
        _selectedDay,
      );

      if (!mounted) return;
      setState(() {
        _selectedSlots = Set.from(savedSlots);
      });
    } catch (e) {
      print("Error cargando disponibilidad: $e");
      if (!mounted) return;

      await showAppErrorDialog(
        context: context,
        icon: Icons.cloud_off_rounded,
        title: 'Error al Cargar',
        content: 'No se pudo cargar la disponibilidad: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 💡 --- FUNCIÓN MODIFICADA ---
  Future<void> _saveAvailabilityForSelectedDay() async {
    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final List<String> slotsToSave = _selectedSlots.toList()..sort();

      await _availabilityService.setAvailability(
        kineId: _currentKineId,
        date: _selectedDay,
        availableSlots: slotsToSave,
      );

      if (!mounted) return;

      // 💡 --- INICIO DE LA LÓGICA MEJORADA ---
      if (slotsToSave.isEmpty) {
        // Mensaje para cuando se guarda un DÍA VACÍO
        await showAppInfoDialog(
          context: context,
          icon: Icons.event_busy_rounded, // Icono de "día no disponible"
          title: 'Día No Disponible',
          content:
              'Has guardado este día sin horarios. Los pacientes no podrán agendar.',
        );
      } else {
        // Mensaje para cuando se guardan horarios
        await showAppInfoDialog(
          context: context,
          icon: Icons.check_circle_outline_rounded,
          title: '¡Guardado!',
          content:
              'Disponibilidad guardada para este día. (${slotsToSave.length} horarios)',
        );
      }
      // 💡 --- FIN DE LA LÓGICA MEJORADA ---
    } catch (e) {
      print("Error guardando disponibilidad del día: $e");
      if (!mounted) return;

      await showAppErrorDialog(
        context: context,
        icon: Icons.error_outline_rounded,
        title: 'Error al Guardar',
        content: 'No se pudo guardar la disponibilidad: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  // 💡 --- FIN DE LA FUNCIÓN MODIFICADA ---

  Future<void> _saveAvailabilityForWeek() async {
    if (!mounted) return;

    // 1. Verifica si hay horarios seleccionados
    if (_selectedSlots.isEmpty) {
      await showAppWarningDialog(
        context: context,
        icon: Icons.warning_amber_rounded,
        title: 'Sin Horarios',
        content: 'Selecciona al menos un horario antes de aplicar a la semana.',
      );
      return;
    }

    // 2. Pide confirmación al Kine
    bool? confirm = await showAppConfirmationDialog(
      context: context,
      icon: Icons.event_repeat_rounded,
      title: 'Aplicar a la Semana',
      content:
          'Esto aplicará los ${_selectedSlots.length} horarios seleccionados a todos los días de Lunes a Viernes de esta semana. ¿Deseas continuar?',
      confirmText: 'Aplicar',
      cancelText: 'Cancelar',
      isDestructive: false,
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() {
      _isSavingWeek = true;
    });

    try {
      final List<String> slotsToSave = _selectedSlots.toList()..sort();
      DateTime monday = _getMonday(_selectedDay);

      List<Future> saveFutures = [];
      for (int i = 0; i < 5; i++) {
        DateTime currentWeekday = monday.add(Duration(days: i));
        saveFutures.add(
          _availabilityService.setAvailability(
            kineId: _currentKineId,
            date: currentWeekday,
            availableSlots: slotsToSave,
          ),
        );
      }
      await Future.wait(saveFutures);

      if (!mounted) return;

      await showAppInfoDialog(
        context: context,
        icon: Icons.check_circle_outline_rounded,
        title: '¡Semana Actualizada!',
        content: 'Disponibilidad aplicada a Lunes-Viernes de esta semana.',
      );
    } catch (e) {
      print("Error guardando disponibilidad semanal: $e");
      if (!mounted) return;

      await showAppErrorDialog(
        context: context,
        icon: Icons.error_outline_rounded,
        title: 'Error al Guardar',
        content: 'No se pudo aplicar a la semana: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingWeek = false;
        });
      }
    }
  }

  DateTime _getMonday(DateTime date) {
    int daysToSubtract = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: daysToSubtract));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Disponibilidad'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: (_isLoading || _isSaving || _isSavingWeek)
                  ? null
                  : _saveAvailabilityForSelectedDay,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'GUARDAR DÍA',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'es_ES',
            firstDay: DateTime.now().subtract(const Duration(days: 30)),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.week,
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.tealAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
            enabledDayPredicate: (day) =>
                day.weekday != DateTime.saturday &&
                day.weekday != DateTime.sunday,
            onDaySelected: (selectedDay, focusedDay) {
              if (selectedDay.weekday == DateTime.saturday ||
                  selectedDay.weekday == DateTime.sunday)
                return;

              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _loadAvailabilityForSelectedDay();
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            child: Text(
              'Selecciona los horarios para:\n${DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(_selectedDay)}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.teal),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _baseTimeSlots.length,
                    itemBuilder: (context, index) {
                      final timeSlot = _baseTimeSlots[index];
                      final slotString =
                          '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}';
                      final bool isSelected = _selectedSlots.contains(
                        slotString,
                      );

                      return CheckboxListTile(
                        title: Text(
                          timeSlot.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        value: isSelected,
                        onChanged: (bool? newValue) {
                          setState(() {
                            if (newValue == true) {
                              _selectedSlots.add(slotString);
                            } else {
                              _selectedSlots.remove(slotString);
                            }
                          });
                        },
                        activeColor: Colors.teal,
                      );
                    },
                  ),
          ),
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: ElevatedButton.icon(
                icon: _isSavingWeek
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.calendar_view_week, size: 20),
                label: Text(
                  _isSavingWeek
                      ? 'Aplicando...'
                      : 'Aplicar Horarios a L-V de esta Semana',
                ),
                onPressed: (_isLoading || _isSaving || _isSavingWeek)
                    ? null
                    : _saveAvailabilityForWeek,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 45),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
