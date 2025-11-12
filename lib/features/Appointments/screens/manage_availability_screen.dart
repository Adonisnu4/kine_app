// lib/screens/manage_availability_screen.dart
import 'package:flutter/material.dart';
import 'package:kine_app/features/Appointments/services/availability_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:kine_app/shared/widgets/app_dialog.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() =>
      _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  // ====== PALETA CENTRAL ======
  static const _bg = Color(0xFFF3F3F3);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  final AvailabilityService _availabilityService = AvailabilityService();
  final String _currentKineId = FirebaseAuth.instance.currentUser!.uid;

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<TimeOfDay> _baseTimeSlots = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 9, minute: 0),
    const TimeOfDay(hour: 10, minute: 0),
    const TimeOfDay(hour: 11, minute: 0),
    const TimeOfDay(hour: 12, minute: 0),
    const TimeOfDay(hour: 13, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
    const TimeOfDay(hour: 15, minute: 0),
    const TimeOfDay(hour: 16, minute: 0),
    const TimeOfDay(hour: 17, minute: 0),
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

  // ---------- helper para dialog elegante ----------
  Future<void> _showNiceInfoDialog({
    required IconData icon,
    required Color color,
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: color.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                      minimumSize: const Size(0, 42),
                    ),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --------------------------------------------------

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
      if (!mounted) return;
      await showAppErrorDialog(
        context: context,
        icon: Icons.cloud_off_rounded,
        title: 'Error al cargar',
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

      if (slotsToSave.isEmpty) {
        await _showNiceInfoDialog(
          icon: Icons.event_busy_rounded,
          color: _orange,
          title: 'Día no disponible',
          message:
              'Guardaste este día sin horarios. Los pacientes no podrán agendar.',
        );
      } else {
        await _showNiceInfoDialog(
          icon: Icons.check_circle_outline_rounded,
          color: _blue,
          title: '¡Guardado!',
          message:
              'Disponibilidad guardada para este día. (${slotsToSave.length} horarios)',
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showAppErrorDialog(
        context: context,
        icon: Icons.error_outline_rounded,
        title: 'Error al guardar',
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

  Future<void> _saveAvailabilityForWeek() async {
    if (!mounted) return;

    // 🔸 Aquí estaba el popup feo. Ahora usamos nuestro helper bonito:
    if (_selectedSlots.isEmpty) {
      await _showNiceInfoDialog(
        icon: Icons.warning_amber_rounded,
        color: _orange,
        title: 'Sin horarios',
        message: 'Selecciona al menos un horario antes de aplicar a la semana.',
      );
      return;
    }

    final qty = _selectedSlots.length;

    // popup de confirmación
    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: _orange.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.event_repeat_rounded,
                    color: _orange,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Aplicar a la semana',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Esto aplicará los $qty horarios seleccionados a lunes-viernes de esta semana. ¿Continuar?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: _orange, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          foregroundColor: _orange,
                          minimumSize: const Size(0, 42),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size(0, 42),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Aplicar',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() {
      _isSavingWeek = true;
    });

    try {
      final slotsToSave = _selectedSlots.toList()..sort();
      final monday = _getMonday(_selectedDay);

      final futures = <Future>[];
      for (int i = 0; i < 5; i++) {
        final day = monday.add(Duration(days: i));
        futures.add(
          _availabilityService.setAvailability(
            kineId: _currentKineId,
            date: day,
            availableSlots: slotsToSave,
          ),
        );
      }
      await Future.wait(futures);

      if (!mounted) return;
      await _showNiceInfoDialog(
        icon: Icons.check_circle_outline_rounded,
        color: _blue,
        title: '¡Semana actualizada!',
        message: 'Disponibilidad aplicada a L-V de esta semana.',
      );
    } catch (e) {
      if (!mounted) return;
      await showAppErrorDialog(
        context: context,
        icon: Icons.error_outline_rounded,
        title: 'Error al guardar',
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
    final daysToSubtract = date.weekday - DateTime.monday;
    return date.subtract(Duration(days: daysToSubtract));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE, d MMMM yyyy', 'es_ES')
        .format(_selectedDay)
        .replaceFirstMapped(
          RegExp(r'^[a-z]'),
          (m) => m[0]!.toUpperCase(),
        );

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          'Gestionar disponibilidad',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -.1,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: OutlinedButton(
              onPressed: (_isLoading || _isSaving || _isSavingWeek)
                  ? null
                  : _saveAvailabilityForSelectedDay,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _blue, width: 1),
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _blue,
                      ),
                    )
                  : const Text(
                      'Guardar día',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: _blue,
                      ),
                    ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 48,
              height: 3.5,
              margin: const EdgeInsets.fromLTRB(16, 10, 0, 12),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: TableCalendar(
              locale: 'es_ES',
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: CalendarFormat.week,
              startingDayOfWeek: StartingDayOfWeek.monday,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                titleTextStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: _blue.withOpacity(.16),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: _blue,
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: const TextStyle(color: Colors.grey),
                outsideDaysVisible: false,
              ),
              enabledDayPredicate: (day) =>
                  day.weekday != DateTime.saturday &&
                  day.weekday != DateTime.sunday,
              onDaySelected: (selectedDay, focusedDay) {
                if (selectedDay.weekday == DateTime.saturday ||
                    selectedDay.weekday == DateTime.sunday) return;
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
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Selecciona los horarios para:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _blue),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    itemCount: _baseTimeSlots.length,
                    itemBuilder: (context, index) {
                      final timeSlot = _baseTimeSlots[index];
                      final slotString =
                          '${timeSlot.hour.toString().padLeft(2, '0')}:${timeSlot.minute.toString().padLeft(2, '0')}';
                      final isSelected = _selectedSlots.contains(slotString);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                isSelected ? _blue.withOpacity(.25) : _border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.015),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedSlots.add(slotString);
                              } else {
                                _selectedSlots.remove(slotString);
                              }
                            });
                          },
                          activeColor: _blue,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 14),
                          title: Text(
                            timeSlot.format(context),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                        ),
                      );
                    },
                  ),
          ),
          if (!_isLoading)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: ElevatedButton.icon(
                onPressed: (_isLoading || _isSaving || _isSavingWeek)
                    ? null
                    : _saveAvailabilityForWeek,
                icon: _isSavingWeek
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.event_available_rounded, size: 22),
                label: Text(
                  _isSavingWeek
                      ? 'Aplicando...'
                      : 'Aplicar horarios a L-V de esta semana',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -.05,
                  ),
                  elevation: 0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
