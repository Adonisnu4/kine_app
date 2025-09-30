import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart'; // Asegúrate de que esta pantalla exista para la navegación

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // -------------------------
  // 1. CONTROLADORES Y ESTADO
  // -------------------------
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

  final List<String> _genders = [
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

  // -------------------------
  // 2. MÉTODOS DE UTILIDAD
  // -------------------------

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // -------------------------
  // 3. LÓGICA DE REGISTRO - (Crea cuenta, envía correo y guarda en Firestore)
  // -------------------------
  Future<void> _register() async {
    // Validar todos los campos del formulario.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Creación de la cuenta de autenticación en Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final User? user = userCredential.user;

      if (user != null) {
        // 2. Envío del correo de verificación (REQUERIDO)
        await user.sendEmailVerification();

        // 3. Guardado de datos adicionales en Firestore (REQUERIDO)
        final DocumentReference tipoUsuarioRef = _firestore
            .collection('tipo_usuario')
            .doc('1');

        await _firestore.collection('usuarios').doc(user.uid).set({
          'nombre_completo': _nameController.text.trim(),
          'nombre_usuario': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'edad': int.tryParse(
            _ageController.text.trim(),
          ), // Guarda la edad como entero
          'sexo': _selectedGender, // Guarda el sexo
          'tipo_usuario': tipoUsuarioRef,
          'fecha_registro': FieldValue.serverTimestamp(),
        });

        // 4. Navegación y mensaje de éxito
        if (mounted) {
          Navigator.pop(context); // Vuelve a la pantalla de Login
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

  // -------------------------
  // 4. WIDGET BUILD (Interfaz de Usuario)
  // -------------------------
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

              // Campo de Nombre Completo (REQUERIDO)
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre es obligatorio.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de Nombre de Usuario (REQUERIDO)
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_pin_circle_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'El nombre de usuario es obligatorio.';
                  }
                  if (value.length < 4) {
                    return 'El nombre de usuario debe tener al menos 4 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de Correo Electrónico (REQUERIDO)
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null ||
                      !value.contains('@') ||
                      !value.contains('.')) {
                    return 'Ingresa un correo electrónico válido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo de Contraseña (REQUERIDO)
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña (mín. 6 caracteres)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Campo de Edad (REQUERIDO)
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Edad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La edad es obligatoria.';
                  }
                  final int? age = int.tryParse(value);
                  if (age == null || age < 1 || age > 120) {
                    return 'Ingresa una edad válida (1-120).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Selector de Sexo (REQUERIDO)
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

              // Botón de Registro
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

              // Enlace para volver al Login
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
}
