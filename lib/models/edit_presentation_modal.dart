import 'package:flutter/material.dart';

// Definimos la estructura de datos que manejará el modal (usando records de Dart)
typedef PresentationData = ({
  String specialization,
  String experience,
  String presentation,
});

class EditPresentationModal extends StatefulWidget {
  final PresentationData initialData;
  // La función onSave ahora recibe la estructura de datos completa
  final Function(PresentationData) onSave;

  const EditPresentationModal({
    super.key,
    required this.initialData,
    required this.onSave,
  });

  @override
  State<EditPresentationModal> createState() => _EditPresentationModalState();
}

class _EditPresentationModalState extends State<EditPresentationModal> {
  late TextEditingController _specializationController;
  late TextEditingController _experienceController;
  late TextEditingController _presentationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _specializationController = TextEditingController(
      text: widget.initialData.specialization,
    );
    _experienceController = TextEditingController(
      text: widget.initialData.experience,
    );
    _presentationController = TextEditingController(
      text: widget.initialData.presentation,
    );
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _experienceController.dispose();
    _presentationController.dispose();
    super.dispose();
  }

  void _handleSave() async {
    final newPresentation = _presentationController.text.trim();
    final newSpecialization = _specializationController.text.trim();
    final newExperience = _experienceController.text.trim();

    if (newPresentation.isEmpty ||
        newSpecialization.isEmpty ||
        newExperience.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todos los campos son obligatorios.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final dataToSave = (
      specialization: newSpecialization,
      experience: newExperience,
      presentation: newPresentation,
    );

    // Llama a la función de guardado asíncrona en ProfileScreen
    await widget.onSave(dataToSave);

    if (mounted) {
      // Se asegura de que la UI se ha actualizado antes de cerrar.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Administrar Datos Profesionales',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Divider(),
          const SizedBox(height: 10),
          // --- CAMPO 1: Especialidad ---
          TextField(
            controller: _specializationController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Especialidad Principal',
              hintText: 'Ej: Fisioterapia Deportiva',
            ),
          ),
          const SizedBox(height: 15),
          // --- CAMPO 2: Experiencia ---
          TextField(
            controller: _experienceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Años de Experiencia',
              hintText: 'Ej: 5',
            ),
          ),
          const SizedBox(height: 15),
          // --- CAMPO 3: Carta de Presentación ---
          TextField(
            controller: _presentationController,
            maxLines: 8,
            minLines: 5,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Carta de Presentación (Detalle)',
              hintText: 'Describe tu experiencia, estudios y disponibilidad.',
            ),
          ),
          const SizedBox(height: 25),
          ElevatedButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? 'Guardando...' : 'Guardar y Publicar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
