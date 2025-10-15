import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_screen.dart'; // Asegúrate de que esta pantalla exista

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // ===================================
  // 1. CONTROLADORES Y ESTADO
  // ===================================
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _ageController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _selectedGender;

  final List<String> _genders = const [
    'Masculino',
    'Femenino',
    'Otro',
    'Prefiero no decirlo',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // ===================================
  // 2. MÉTODOS DE UTILIDAD Y SNACKBAR
  // ===================================

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // ===================================
  // 3. LÓGICA DE REGISTRO
  // ===================================
  Future<void> _register() async {
    // 3.1. Validación del formulario
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 3.2. Creación de la cuenta en Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final User? user = userCredential.user;

      if (user != null) {
        // 3.3. Envío del correo de verificación
        await user.sendEmailVerification();

        // 3.4. Preparar referencia y guardar datos en Firestore
        final DocumentReference tipoUsuarioRef = _firestore
            .collection('tipo_usuario')
            .doc('1');

        await _firestore.collection('usuarios').doc(user.uid).set({
          'nombre_completo': _nameController.text.trim(),
          'nombre_usuario': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'edad': int.tryParse(_ageController.text.trim()),
          'sexo': _selectedGender,
          'tipo_usuario': tipoUsuarioRef,
          'fecha_registro': FieldValue.serverTimestamp(),
        });

        // 3.5. CERRAR SESIÓN INMEDIATAMENTE para forzar el Login
        await _auth.signOut();

        // 3.6. Navegación y mensaje de éxito
        if (mounted) {
          Navigator.pop(context);
          _showSnackBar(
            '✅ ¡Registro exitoso! Se ha enviado un correo de verificación. Por favor, revísalo para activar tu cuenta.',
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = '⚠️ La contraseña es demasiado débil (mínimo 6 caracteres).';
      } else if (e.code == 'email-already-in-use') {
        message = '⚠️ Ya existe una cuenta con este correo.';
      } else if (e.code == 'invalid-email') {
        message = '⚠️ El formato del correo electrónico es inválido.';
      } else {
        message = '❌ Error desconocido: ${e.message}';
      }
      _showSnackBar(message);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ===================================
  // 4. WIDGET BUILD (Interfaz de Usuario)
  // ===================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nueva Cuenta'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Completa tus datos para empezar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              // --- CAMPOS DE ENTRADA ---
              _buildTextFormField(
                controller: _nameController,
                label: 'Nombre Completo',
                icon: Icons.person_outline,
                validator: (value) => value == null || value.isEmpty
                    ? 'El nombre es obligatorio.'
                    : null,
              ),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                icon: Icons.person_pin_circle_outlined,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'El nombre de usuario es obligatorio.';
                  if (value.length < 4)
                    return 'Debe tener al menos 4 caracteres.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _emailController,
                label: 'Correo Electrónico',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      !value.contains('@') ||
                      !value.contains('.'))
                    return 'Ingresa un correo válido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextFormField(
                controller: _passwordController,
                label: 'Contraseña (mín. 6 caracteres)',
                icon: Icons.lock_outline,
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? 'Mínimo 6 caracteres.'
                    : null,
              ),
              const SizedBox(height: 24),

              _buildTextFormField(
                controller: _ageController,
                label: 'Edad',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 1 || age > 120)
                    return 'Ingresa una edad válida (1-120).';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // --- DROPDOWN DE SEXO ---
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wc),
                ),
                value: _selectedGender,
                hint: const Text('Selecciona tu sexo'),
                items: _genders.map((String gender) {
                  return DropdownMenuItem<String>(
                    value: gender,
                    child: Text(gender),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'El sexo es obligatorio.' : null,
              ),

              const SizedBox(height: 32),

              // --- BOTÓN DE REGISTRO ---
              SizedBox(
                height: 50,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Registrarme',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // --- ENLACE PARA VOLVER AL LOGIN ---
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  ); // Vuelve a la pantalla anterior (Login)
                },
                child: const Text('¿Ya tienes una cuenta? Inicia Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para simplificar la creación de campos de texto
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
    );
  }
}
