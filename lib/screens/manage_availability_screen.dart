// lib/screens/manage_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/services/availability_service.dart'; // Importa el servicio
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  // Horarios base que el Kine puede elegir
  final List<TimeOfDay> _baseTimeSlots = List.generate(8, (index) {
    int hour = index < 4 ? 9 + index : 14 + (index - 4);
    return TimeOfDay(hour: hour, minute: 0);
  });

  Set<String> _selectedSlots = {}; // Slots seleccionados ("HH:mm")
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Asegura que el día inicial no sea fin de semana
    _selectedDay = _findNextAvailableWorkDay(DateTime.now());
    _focusedDay = _selectedDay;
    _loadAvailabilityForSelectedDay();
  }

  // Encuentra el próximo día laboral (Lunes a Viernes)
  DateTime _findNextAvailableWorkDay(DateTime date) {
    DateTime tempDate = date;
    // Si es sábado, suma 2 días. Si es domingo, suma 1 día.
    if (tempDate.weekday == DateTime.saturday) {
      tempDate = tempDate.add(const Duration(days: 2));
    } else if (tempDate.weekday == DateTime.sunday) {
      tempDate = tempDate.add(const Duration(days: 1));
    }
    return tempDate;
  }

  // Carga disponibilidad guardada para el día seleccionado
  Future<void> _loadAvailabilityForSelectedDay() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    }); // Muestra indicador de carga
    try {
      // Llama al servicio para obtener los slots guardados ("HH:mm")
      final savedSlots = await _availabilityService.getSavedAvailability(
        _currentKineId,
        _selectedDay,
      );
      if (mounted) {
        // Guarda los slots en el Set y oculta el indicador
        setState(() {
          _selectedSlots = Set.from(savedSlots);
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando disponibilidad: $e");
      // Muestra error si falla la carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        }); // Oculta indicador
        ScaffoldMessenger.of(context).showSnackBar(
          // --- 👇 CÓDIGO RESTAURADO 👇 ---
          SnackBar(
            content: Text('Error al cargar disponibilidad: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
          // --- FIN RESTAURACIÓN ---
        );
      }
    }
  }

  // Guarda los slots seleccionados
  Future<void> _saveAvailability() async {
    if (!mounted) return;
    setState(() {
      _isSaving = true;
    }); // Muestra indicador en el botón AppBar
    try {
      // Convierte el Set a List antes de guardar y ordena
      final List<String> slotsToSave = _selectedSlots.toList()..sort();

      // Llama al servicio para guardar
      await _availabilityService.setAvailability(
        kineId: _currentKineId,
        date: _selectedDay,
        availableSlots: slotsToSave,
      );

      // Muestra mensaje de éxito
      if (mounted) {
        setState(() {
          _isSaving = false;
        }); // Oculta indicador
        ScaffoldMessenger.of(context).showSnackBar(
          // --- 👇 CÓDIGO RESTAURADO 👇 ---
          const SnackBar(
            content: Text('Disponibilidad guardada con éxito.'),
            backgroundColor: Colors.green,
          ),
          // --- FIN RESTAURACIÓN ---
        );
      }
    } catch (e) {
      print("Error guardando disponibilidad: $e");
      // Muestra mensaje de error
      if (mounted) {
        setState(() {
          _isSaving = false;
        }); // Oculta indicador
        ScaffoldMessenger.of(context).showSnackBar(
          // --- 👇 CÓDIGO RESTAURADO 👇 ---
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
          // --- FIN RESTAURACIÓN ---
        );
      }
    }
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
              onPressed: _isSaving ? null : _saveAvailability,
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
                      'GUARDAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Calendario ---
          TableCalendar(
            locale: 'es_ES',
            firstDay: DateTime.now().subtract(
              const Duration(days: 7),
            ), // Rango ajustable
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.week, // Mostrar por semana
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(/* ... Estilos ... */),
            // Filtro para no poder seleccionar fines de semana
            enabledDayPredicate: (day) {
              return day.weekday != DateTime.saturday &&
                  day.weekday != DateTime.sunday;
            },
            onDaySelected: (selectedDay, focusedDay) {
              // Asegura no seleccionar fin de semana (doble chequeo)
              if (selectedDay.weekday == DateTime.saturday ||
                  selectedDay.weekday == DateTime.sunday) {
                return; // No hacer nada si se intenta seleccionar fin de semana
              }
              if (!isSameDay(_selectedDay, selectedDay)) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                  _selectedSlots = {};
                });
                _loadAvailabilityForSelectedDay(); // Carga disponibilidad del nuevo día
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
              'Selecciona los horarios disponibles para:\n${DateFormat('EEEE, dd MMMM yyyy', 'es_ES').format(_selectedDay)}',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // --- Lista de Horarios (Checkboxes) ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
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

                      // Checkbox para cada horario
                      return CheckboxListTile(
                        title: Text(timeSlot.format(context)),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
