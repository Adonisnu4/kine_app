// presentation_editor_screen.dart
import 'package:flutter/material.dart';

// Esta pantalla será usada por el Kinesiólogo (ID 3) para editar su carta.
class PresentationEditorScreen extends StatefulWidget {
  const PresentationEditorScreen({super.key});

  @override
  State<PresentationEditorScreen> createState() =>
      _PresentationEditorScreenState();
}

class _PresentationEditorScreenState extends State<PresentationEditorScreen> {
  // Controladores para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _estudiosController = TextEditingController();
  final TextEditingController _horasController = TextEditingController();
  final TextEditingController _experienciaController = TextEditingController();

  // TODO: En un escenario real, aquí cargarías los datos existentes del Kine al inicio.

  void _savePresentation() {
    // 1. Recoger los valores
    final String nombre = _nombreController.text.trim();
    final String estudios = _estudiosController.text.trim();
    final String horas = _horasController.text.trim();
    final String experiencia = _experienciaController.text.trim();

    // 2. TODO: Implementar la lógica para guardar estos datos
    //    en Firestore (o tu base de datos) bajo el perfil del Kinesiólogo.
    //    Deberías actualizar un campo como 'carta_presentacion' en el documento del usuario.

    // 3. Mostrar confirmación y cerrar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Carta de presentación guardada con éxito.'),
      ),
    );
    Navigator.pop(
      context,
      true,
    ); // Retorna 'true' para indicar que hubo un cambio
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _estudiosController.dispose();
    _horasController.dispose();
    _experienciaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Carta de Presentación'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Completa los detalles de tu perfil profesional. Esta información será pública.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(height: 30),

            // Campo Nombre/Especialidad
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Título o Especialidad (ej: Kinesiólogo Deportivo)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
              ),
            ),
            const SizedBox(height: 20),

            // Campo Estudios/Certificaciones
            TextField(
              controller: _estudiosController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText:
                    'Estudios y Certificaciones (ej: U. de Chile, Postgrado en Rehabilitación)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 20),

            // Campo Horas de Trabajo
            TextField(
              controller: _horasController,
              decoration: const InputDecoration(
                labelText: 'Disponibilidad / Horas de Trabajo',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 20),

            // Campo Experiencia (Breve resumen)
            TextField(
              controller: _experienciaController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText:
                    'Experiencia y Enfoque Profesional (Biografía breve)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.star),
              ),
            ),
            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: _savePresentation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Guardar Presentación',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
