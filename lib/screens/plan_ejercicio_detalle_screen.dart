// plan_ejercicio_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlanEjercicioDetalleScreen extends StatefulWidget {
  final String planId;
  final String planName;

  const PlanEjercicioDetalleScreen({
    super.key,
    required this.planId,
    required this.planName,
  });

  @override
  State<PlanEjercicioDetalleScreen> createState() =>
      _PlanEjercicioDetalleScreenState();
}

class _PlanEjercicioDetalleScreenState extends State<PlanEjercicioDetalleScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(widget.planName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('plan').doc(widget.planId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error al cargar el plan: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('No se encontró el plan.'));
          }

          final Map<String, dynamic> planData =
              snapshot.data!.data() as Map<String, dynamic>;
          final List<dynamic> sesiones = planData['sesiones'] ?? [];

          if (sesiones.isEmpty) {
            return const Center(
                child: Text('Este plan aún no tiene sesiones asignadas.'));
          }

          int totalEjercicios = 0;
          int ejerciciosCompletados = 0;
          for (final s in sesiones) {
            final Map<String, dynamic> ses = s as Map<String, dynamic>;
             final dynamic ejerciciosRaw = ses['ejercicios'];
             if (ejerciciosRaw is Map) {
                final Map<String, dynamic> ejercicios = Map<String, dynamic>.from(ejerciciosRaw);
                totalEjercicios += ejercicios.length;
                for (final e in ejercicios.values) {
                  final Map<String, dynamic> info = e as Map<String, dynamic>;
                  if (info['completado'] == true) ejerciciosCompletados++;
                }
             } else if (ejerciciosRaw is List) {
                final List<dynamic> ejerciciosList = List<dynamic>.from(ejerciciosRaw);
                totalEjercicios += ejerciciosList.length;
                for (final e in ejerciciosList) {
                  if (e is Map) {
                     final Map<String, dynamic> info = Map<String, dynamic>.from(e);
                     if (info['completado'] == true) ejerciciosCompletados++;
                  }
                }
             }
          }

          final double progreso =
              totalEjercicios == 0 ? 0.0 : ejerciciosCompletados / totalEjercicios;

          return Column(
            children: [
              _buildProgresoCard(
                context,
                progreso,
                ejerciciosCompletados,
                totalEjercicios,
              ),
              Expanded(
                child: _buildSesionesList(sesiones),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProgresoCard(BuildContext context, double progreso,
      int ejerciciosCompletados, int totalEjercicios) {
    
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.all(12.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso del plan',
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 10,
                      color: Colors.deepPurple,
                      backgroundColor: Colors.deepPurple.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${(progreso * 100).toStringAsFixed(0)}%',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Ejercicios: $ejerciciosCompletados / $totalEjercicios',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSesionesList(List<dynamic> sesiones) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16.0),
      itemCount: sesiones.length,
      itemBuilder: (context, index) {
        final Map<String, dynamic> sesionActual =
            sesiones[index] as Map<String, dynamic>;
        final int numeroSesion = sesionActual['numero_sesion'] ?? (index + 1);
        final dynamic ejerciciosData = sesionActual['ejercicios']; 
        final bool sesionCompletada = sesionActual['completada'] == true;

        int totalEjerciciosSesion = 0;
        if (ejerciciosData is Map) {
          totalEjerciciosSesion = ejerciciosData.length;
        } else if (ejerciciosData is List) {
          totalEjerciciosSesion = ejerciciosData.length;
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
          elevation: 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias, 
          child: ExpansionTile(
            leading: Icon(
              sesionCompletada ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
              color: sesionCompletada ? Colors.green : Colors.deepPurple,
              size: 28,
            ),
            trailing: Checkbox(
              value: sesionCompletada,
              activeColor: Colors.deepPurple,
              onChanged: (val) async {
                await _toggleSesionCompletada(index, val == true);
              },
            ),
            title: Text(
              'Sesión $numeroSesion',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: sesionCompletada ? Colors.grey.shade700 : Colors.black87,
                decoration: sesionCompletada
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            subtitle: Text('$totalEjerciciosSesion ejercicios'),
            children: _buildEjerciciosList(ejerciciosData, index),
          ),
        );
      },
    );
  }

  List<Widget> _buildEjerciciosList(dynamic ejerciciosData, int sesionIndex) {
    if (ejerciciosData == null) {
       return [const ListTile(title: Text('No hay ejercicios en esta sesión.'))];
    }

    if (ejerciciosData is Map<String, dynamic>) {
      if (ejerciciosData.isEmpty) {
        return [const ListTile(title: Text('No hay ejercicios en esta sesión.'))];
      }
      return ejerciciosData.entries.map<Widget>((entry) {
        final String ejercicioKey = entry.key;
        final info = Map<String, dynamic>.from(entry.value as Map);
        return _buildEjercicioTile(info, sesionIndex, ejercicioKey);
      }).toList();
    }

    if (ejerciciosData is List) {
       if (ejerciciosData.isEmpty) {
        return [const ListTile(title: Text('No hay ejercicios en esta sesión.'))];
      }
      return ejerciciosData.asMap().entries.map<Widget>((entry) {
          final int ejercicioIndex = entry.key;
          final info = Map<String, dynamic>.from(entry.value as Map);
          return _buildEjercicioTile(info, sesionIndex, ejercicioIndex.toString());
      }).toList();
    }
    
    return [const ListTile(title: Text('Formato de ejercicios no reconocido.'))];
  }

  Widget _buildEjercicioTile(Map<String, dynamic> info, int sesionIndex, String ejercicioKey) {
    final String nombreEjercicio =
        info['nombre_ejercicio'] ?? 'Nombre no encontrado';
    final int tiempoSegundos = info['tiempo_segundos'] ?? 0;
    final bool completado = info['completado'] == true;

    return ListTile(
      contentPadding:
          const EdgeInsets.only(left: 56.0, right: 16.0, bottom: 4.0),
      leading: Icon(
        completado ? Icons.check_circle : Icons.directions_run_rounded,
        color: completado ? Colors.green : Colors.orange.shade700,
      ),
      title: Text(
        nombreEjercicio,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: completado ? Colors.grey.shade700 : Colors.black87,
          decoration:
              completado ? TextDecoration.lineThrough : TextDecoration.none,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tiempoSegundos > 0)
            Text(
              '$tiempoSegundos seg',
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          const SizedBox(width: 8),
          Checkbox(
            value: completado,
            activeColor: Colors.deepPurple,
            onChanged: (val) async {
              await _toggleEjercicioCompletado(
                  sesionIndex, ejercicioKey, val == true);
            },
          ),
        ],
      ),
    );
  }

  // Lógica de Firestore
  Future<void> _toggleSesionCompletada(int sesionIndex, bool completada) async {
    final docRef = _firestore.collection('plan').doc(widget.planId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('El plan no existe');
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(snapshot.data() as Map);
        final List<dynamic> sesiones = List<dynamic>.from(data['sesiones'] ?? []);
        if (sesionIndex < 0 || sesionIndex >= sesiones.length) return;
        final Map<String, dynamic> ses =
            Map<String, dynamic>.from(sesiones[sesionIndex] as Map);
        ses['completada'] = completada;

        final dynamic ejerciciosRaw = ses['ejercicios'];
        if (ejerciciosRaw is Map) {
          final Map<String, dynamic> ejercicios =
              Map<String, dynamic>.from(ejerciciosRaw);
          ejercicios.forEach((key, value) {
            final Map<String, dynamic> info = Map<String, dynamic>.from(value);
            info['completado'] = completada;
            ejercicios[key] = info;
          });
          ses['ejercicios'] = ejercicios;
        } else if (ejerciciosRaw is List) {
          final List<dynamic> ejerciciosList =
              List<dynamic>.from(ejerciciosRaw);
          for (int i = 0; i < ejerciciosList.length; i++) {
            if (ejerciciosList[i] is Map) {
              final Map<String, dynamic> info =
                  Map<String, dynamic>.from(ejerciciosList[i]);
              info['completado'] = completada;
              ejerciciosList[i] = info;
            }
          }
          ses['ejercicios'] = ejerciciosList;
        }

        sesiones[sesionIndex] = ses;
        transaction.update(docRef, {'sesiones': sesiones});
      });

      await _syncUserProgress();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al actualizar sesión: $e')));
    }
  }

  Future<void> _toggleEjercicioCompletado(
      int sesionIndex, String ejercicioKey, bool completado) async {
    final docRef = _firestore.collection('plan').doc(widget.planId);
    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) throw Exception('El plan no existe');
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(snapshot.data() as Map);
        final List<dynamic> sesiones = List<dynamic>.from(data['sesiones'] ?? []);
        if (sesionIndex < 0 || sesionIndex >= sesiones.length) return;
        final Map<String, dynamic> ses =
            Map<String, dynamic>.from(sesiones[sesionIndex] as Map);
        final dynamic ejerciciosRaw = ses['ejercicios'];

        if (ejerciciosRaw is Map) {
          final Map<String, dynamic> ejercicios =
              Map<String, dynamic>.from(ejerciciosRaw);
          if (ejercicios.containsKey(ejercicioKey)) {
            final Map<String, dynamic> info =
                Map<String, dynamic>.from(ejercicios[ejercicioKey]);
            info['completado'] = completado;
            ejercicios[ejercicioKey] = info;
          }
          ses['ejercicios'] = ejercicios;
        } else if (ejerciciosRaw is List) {
          final List<dynamic> ejerciciosList =
              List<dynamic>.from(ejerciciosRaw);
          int? idx = int.tryParse(ejercicioKey); 
          if (idx != null && idx >= 0 && idx < ejerciciosList.length) {
            final Map<String, dynamic> info =
                Map<String, dynamic>.from(ejerciciosList[idx]);
            info['completado'] = completado;
            ejerciciosList[idx] = info;
          } else {
             for (int i = 0; i < ejerciciosList.length; i++) {
               if (ejerciciosList[i] is Map) {
                 final Map<String, dynamic> info = Map<String, dynamic>.from(ejerciciosList[i]);
                 if ((info['id'] != null && info['id'].toString() == ejercicioKey) || (info['nombre_ejercicio'] != null && info['nombre_ejercicio'].toString() == ejercicioKey)) {
                   info['completado'] = completado;
                   ejerciciosList[i] = info;
                   break;
                 }
               }
             }
          }
          ses['ejercicios'] = ejerciciosList;
        }

        sesiones[sesionIndex] = ses;
        transaction.update(docRef, {'sesiones': sesiones});
      });

      await _syncUserProgress();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar ejercicio: $e')));
    }
  }

  // --- FUNCIÓN MODIFICADA ---
  Future<void> _syncUserProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final docRef = _firestore.collection('plan').doc(widget.planId);
      final snap = await docRef.get();
      if (!snap.exists) return;
      final Map<String, dynamic> planData =
          Map<String, dynamic>.from(snap.data() as Map);
      final List<dynamic> sesiones = List<dynamic>.from(planData['sesiones'] ?? []);

      int totalEjercicios = 0;
      int ejerciciosCompletados = 0;
      for (final s in sesiones) {
        final Map<String, dynamic> ses = Map<String, dynamic>.from(s as Map);
        final dynamic ejerciciosRaw = ses['ejercicios'];
        if (ejerciciosRaw is Map) {
          final Map<String, dynamic> ejercicios =
              Map<String, dynamic>.from(ejerciciosRaw);
          totalEjercicios += ejercicios.length;
          for (final v in ejercicios.values) {
            final Map<String, dynamic> info = Map<String, dynamic>.from(v);
            if (info['completado'] == true) ejerciciosCompletados++;
          }
        } else if (ejerciciosRaw is List) {
          final List<dynamic> ejerciciosList =
              List<dynamic>.from(ejerciciosRaw);
          totalEjercicios += ejerciciosList.length;
          for (final v in ejerciciosList) {
            if (v is Map) {
              final Map<String, dynamic> info = Map<String, dynamic>.from(v);
              if (info['completado'] == true) ejerciciosCompletados++;
            }
          }
        }
      }

      final double porcentaje =
          totalEjercicios == 0 ? 0.0 : ejerciciosCompletados / totalEjercicios;
      
      // --- CAMBIO CLAVE AQUÍ ---
      // Si el porcentaje es 1.0 o más, el plan está 'completado'.
      final bool completado = (porcentaje >= 1.0); 

      final collection = _firestore.collection('plan_tomados_por_usuarios');
      final query = await collection
          .where('planId', isEqualTo: widget.planId)
          .where('usuarioId', isEqualTo: user.uid)
          .limit(1)
          .get();

      final progresoPayload = {
        'completado': completado, // El estado general del plan
        'porcentaje': (porcentaje * 100).toInt(),
        'ejerciciosCompletados': ejerciciosCompletados,
        'totalEjercicios': totalEjercicios,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (query.docs.isNotEmpty) {
        final docId = query.docs.first.id;
        await collection.doc(docId).update({
          'progreso': progresoPayload,
          'activo': !completado, // <-- SE ACTUALIZA AQUÍ
        });
      } else {
        await collection.add({
          'planId': widget.planId,
          'planNombre': planData['nombre'] ?? widget.planName,
          'usuarioId': user.uid,
          'activo': !completado, // <-- SE AÑADE AQUÍ
          'fecha_inicio': FieldValue.serverTimestamp(),
          'progreso': progresoPayload,
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error sincronizando progreso del usuario: $e');
    }
  }
}