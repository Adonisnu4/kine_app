import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';

class SesionEjercicioScreen extends StatefulWidget {
  final String ejecucionId;
  const SesionEjercicioScreen({super.key, required this.ejecucionId});

  @override
  State<SesionEjercicioScreen> createState() => _SesionEjercicioScreenState();
}

class _SesionEjercicioScreenState extends State<SesionEjercicioScreen> {
  VideoPlayerController? _videoController;
  bool _isLoading = true;
  String _nombre = '';
  String _videoUrl = '';
  String _sesionNombre = '';

  // Nuevo estado para la finalización de la SESIÓN (no del plan completo)
  bool _isSessionCompletedAndFinished = false;

  /// ⏱️ Control del tiempo total de reproducción
  late Timer _durationTimer;
  Duration _totalPlayed = Duration.zero;
  Duration _targetDuration = Duration.zero;

  // Variables para mantener la posición actual y poder actualizar Firestore
  String? _currentExerciseKey;
  int _currentSessionIndex = -1;

  // —— PALETA (solo visual) ——
  static const _bg = Color(0xFFF6F6F7);
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _border = Color(0x11000000);

  @override
  void initState() {
    super.initState();
    _loadExercise();
  }

  @override
  void dispose() {
    if (mounted) _durationTimer.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  /// Obtiene el ejercicio actual y prepara el video
  Future<void> _loadExercise() async {
    setState(() {
      _isLoading = true;
      _videoController?.dispose();
      _videoController = null;
      _totalPlayed = Duration.zero;
      _isSessionCompletedAndFinished = false; // Resetear el estado de completado
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final ejecucionRef =
          firestore.collection('plan_tomados_por_usuarios').doc(widget.ejecucionId);

      final ejecucionDoc = await ejecucionRef.get();

      if (!ejecucionDoc.exists) throw Exception('Ejecución no encontrada');

      final data = ejecucionDoc.data()!;
      final sesionActual = data['sesion_actual'] ?? 0;
      final sesiones = List<Map<String, dynamic>>.from(data['sesiones'] ?? []);

      final sesion = sesiones[sesionActual];
      final ejercicios = Map<String, dynamic>.from(sesion['ejercicios'] ?? {});
      final keys = ejercicios.keys.toList()..sort();

      // 2. Encontrar el primer ejercicio no completado en la sesión actual
      final currentKey = keys.firstWhere(
        (k) => !(ejercicios[k]?['completado'] ?? false),
        orElse: () => '', // Si todo está completado, orElse devuelve ''
      );

      // 3. Si todo en la sesión actual está completado, llama a _endSessionSuccess()
      if (currentKey.isEmpty) {
        _endSessionSuccess(sesion['nombre'] ?? 'Sesión ${sesionActual + 1}');
        return;
      }

      final currentData = ejercicios[currentKey];
      if (currentData == null || currentData['ejercicio'] == null) {
        throw Exception('No hay referencia de ejercicio');
      }

      // 4. Cargar datos del ejercicio
      final DocumentReference ref = currentData['ejercicio'];
      final doc = await ref.get();
      if (!doc.exists) throw Exception('Ejercicio no encontrado');

      final ejercicioData = doc.data() as Map<String, dynamic>;
      final videoUrl = ejercicioData['video'] ?? '';
      final nombre = ejercicioData['nombre'] ?? 'Ejercicio sin nombre';

      // Corregido: Usando 'tiempo_segundos'
      final targetSeconds = currentData['tiempo_segundos'] as int? ?? 30; // Leer el tiempo

      if (videoUrl.isEmpty || !videoUrl.startsWith('http')) {
        throw Exception('URL de video no válida');
      }

      final sesionNombre = (sesion['nombre'] != null && (sesion['nombre'] as String).isNotEmpty)
          ? sesion['nombre']
          : 'Sesión ${sesionActual + 1}';

      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      /// 🔁 Escucha cuando el video termina (looping)
      controller.addListener(() {
        if (controller.value.position >= controller.value.duration) {
          if (_totalPlayed < _targetDuration) {
            controller.seekTo(Duration.zero);
            controller.play();
          }
        }
      });

      setState(() {
        _videoController = controller;
        _videoUrl = videoUrl;
        _nombre = nombre;
        _sesionNombre = sesionNombre;
        _targetDuration = Duration(seconds: targetSeconds);
        _isLoading = false;

        // Guardar la posición actual para el avance
        _currentExerciseKey = currentKey;
        _currentSessionIndex = sesionActual;
      });

      // Inicia la reproducción y el temporizador
      _videoController!.play();
      _startDurationTimer();
    } catch (e) {
      debugPrint('Error cargando ejercicio: $e');
      setState(() {
        _isLoading = false;
        _nombre = 'Error al cargar ejercicio: ${e.toString()}';
      });
    }
  }

  /// Determina si todos los ejercicios en la sesión han sido completados.
  bool _isSessionCompleted(Map<String, dynamic> session) {
    final ejercicios = Map<String, dynamic>.from(session['ejercicios'] ?? {});
    return ejercicios.values.every((e) => e['completado'] == true);
  }

  /// 🚀 Marca el ejercicio actual como completado y avanza al siguiente o finaliza la sesión.
  Future<void> _completeExerciseAndAdvance() async {
    // Cancelar el temporizador
    if (_durationTimer.isActive) _durationTimer.cancel();
    _videoController?.pause();

    if (_currentExerciseKey == null || _currentSessionIndex == -1) {
      debugPrint('Error: Clave de ejercicio o índice de sesión no establecido.');
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef =
          firestore.collection('plan_tomados_por_usuarios').doc(widget.ejecucionId);

      final doc = await docRef.get();
      if (!doc.exists) {
        throw Exception('Documento no encontrado para actualizar.');
      }

      final data = doc.data()!;
      final sesiones = List<Map<String, dynamic>>.from(data['sesiones'] ?? []);
      final sesionActual = data['sesion_actual'] ?? 0;

      if (sesionActual != _currentSessionIndex) {
        // Protección: Si el índice actual no coincide con la base de datos, recargar
        return _loadExercise();
      }

      // 1. Marcar el ejercicio actual como completado (Localmente)
      final sesion = sesiones[sesionActual];
      final ejercicios = Map<String, dynamic>.from(sesion['ejercicios'] ?? {});

      if (ejercicios.containsKey(_currentExerciseKey)) {
        ejercicios[_currentExerciseKey]!['completado'] = true;
      }

      // 2. Verificar si la sesión actual ha finalizado
      final bool currentSessionCompleted = _isSessionCompleted(sesion);

      // 3. Preparar actualizaciones para Firestore
      final Map<String, dynamic> updates = {'sesiones': sesiones};

      // 4. Decidir el siguiente paso y aplicar la lógica de avance de sesión
      if (currentSessionCompleted) {
        sesiones[sesionActual]['completada'] = true;
        final nextSessionIndex = sesionActual + 1;
        final isPlanCompleted = nextSessionIndex >= sesiones.length;

        if (isPlanCompleted) {
          // ⭐ plan terminado
          updates['estado'] = 'terminado';
          updates['fecha_finalizacion'] = FieldValue.serverTimestamp();
        } else {
          // avanzar de sesión
          updates['sesion_actual'] = nextSessionIndex;
        }
      }

      // 5. Escribir TODOS los cambios en Firestore
      await docRef.update(updates);

      // 6. Acciones posteriores
      if (currentSessionCompleted) {
        _endSessionSuccess(sesion['nombre'] ?? 'Sesión ${sesionActual + 1}');
      } else {
        _loadExercise();
      }
    } catch (e) {
      debugPrint('Error al completar ejercicio y avanzar: $e');
    }
  }

  //Controla el tiempo total reproducido
  void _startDurationTimer() {
    _durationTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (_videoController != null && _videoController!.value.isPlaying) {
        setState(() {
          _totalPlayed += const Duration(milliseconds: 500);
        });

        if (_totalPlayed >= _targetDuration && _targetDuration.inSeconds > 0) {
          _videoController!.pause();
          timer.cancel(); // Detener el temporizador de conteo

          _completeExerciseAndAdvance();
        }
      }
    });
  }

  /// 🏁 Lógica para el fin de la SESIÓN actual
  void _endSessionSuccess(String sessionName) {
    setState(() {
      _isLoading = false;
      _isSessionCompletedAndFinished = true;
      _sesionNombre = '¡Sesión completada!';
      _nombre = sessionName;
    });
    // La pantalla permanecerá en este estado hasta que el usuario decida salir.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(_sesionNombre.isEmpty ? 'Sesión' : _sesionNombre),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : _isSessionCompletedAndFinished
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(22.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _border),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 52,
                            width: 52,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.green, size: 28),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '¡Sesión completada!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _nombre,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.black87,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                        color: _blue, width: 1.2),
                                    foregroundColor: _blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    minimumSize: const Size(0, 46),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  child: const Text('Volver'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _loadExercise,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _orange,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    minimumSize: const Size(0, 46),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                  child: const Text('Continuar'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _videoController == null || !_videoController!.value.isInitialized
                  ? Center(
                      child: Text(
                        'No se pudo cargar el video: $_nombre',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Acento naranja
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 48,
                                height: 3.5,
                                margin:
                                    const EdgeInsets.fromLTRB(2, 6, 0, 12),
                                decoration: BoxDecoration(
                                  color: _orange,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            ),
                            Text(
                              "Ejercicio:  $_nombre",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _blue,
                                letterSpacing: -.1,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),

                            // Tarjeta de video
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: _border),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Controles
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Play/Pause (redondo)
                                Material(
                                  color: _blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 2,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (_videoController!
                                            .value.isPlaying) {
                                          _videoController!.pause();
                                        } else {
                                          if (_totalPlayed < _targetDuration) {
                                            _videoController!.play();
                                          }
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(32),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Icon(
                                        _videoController!.value.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        size: 34,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Stop (outlined rojo)
                                Material(
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                    side: BorderSide(
                                      color: Colors.red.shade500,
                                      width: 2,
                                    ),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      _videoController!
                                          .seekTo(Duration.zero);
                                      _videoController!.pause();
                                      if (_durationTimer.isActive) {
                                        _durationTimer.cancel();
                                        _startDurationTimer();
                                      }
                                      setState(() {
                                        _totalPlayed = Duration.zero;
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(32),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Icon(
                                        Icons.stop_rounded,
                                        size: 30,
                                        color: Colors.red.shade500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Progreso redondeado
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: _targetDuration.inSeconds > 0
                                    ? _totalPlayed.inMilliseconds /
                                        _targetDuration.inMilliseconds
                                    : 0,
                                minHeight: 8,
                                backgroundColor: Colors.black12,
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(_blue),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Texto de tiempo y duración objetivo
                            Text(
                              'Tiempo ejercitado: ${_totalPlayed.inSeconds}s / ${_targetDuration.inSeconds}s',
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            // Mensaje de completado
                            if (_totalPlayed >= _targetDuration &&
                                _targetDuration.inSeconds > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  '¡Objetivo alcanzado! Avanzando...',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
    );
  }
}
