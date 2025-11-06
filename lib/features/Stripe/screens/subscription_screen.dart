// lib/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/Stripe/services/stripe_service.dart';

// Enum para claridad en el selector
enum BillingCycle { monthly, annual }

class SubscriptionScreen extends StatefulWidget {
  final String userType;
  const SubscriptionScreen({super.key, required this.userType});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final StripeService _stripeService = StripeService();
  bool _isLoading = false;

  // --- 1. IDs DE PRECIO (MENSUAL Y ANUAL) ---
  // Kine
  final String _kineMonthlyPriceId = 'price_1SNKvSPMEZlnmK1ZrZ3Sk99F'; // Tu ID
  final String _kineAnnualPriceId = 'price_1SNKvSPMEZlnmK1Zwh0EzLu6'; // Tu ID

  // Paciente (Aún pendientes)
  final String _patientMonthlyPriceId = 'price_TU_ID_PACIENTE_MENSUAL';
  final String _patientAnnualPriceId = 'price_TU_ID_PACIENTE_ANUAL';

  // --- 2. ESTADO PARA EL PLAN SELECCIONADO ---
  String _selectedPriceId = '';
  String _selectedPlanTitle = '';
  String _selectedPlanDescription = '';
  String _selectedDisplayPrice = '';
  List<String> _selectedFeatures = []; // Inicializado (evita error de .length)
  Set<BillingCycle> _selectedCycle = {BillingCycle.monthly}; // Inicializado

  @override
  void initState() {
    super.initState();
    // Configura el plan inicial al cargar la pantalla
    _updateSelectedPlan(widget.userType, _selectedCycle.first);
  }

  /// 3. Actualiza la UI (la tarjeta) basado en la selección
  void _updateSelectedPlan(String userType, BillingCycle cycle) {
    setState(() {
      _selectedCycle = {cycle}; // Actualiza el selector visual

      if (userType == 'kine') {
        _selectedPlanTitle = 'Kine Pro';
        _selectedFeatures = [
          'Perfil Destacado en Búsquedas',
          'Pacientes Ilimitados',
        ];

        if (cycle == BillingCycle.monthly) {
          _selectedPriceId = _kineMonthlyPriceId;
          _selectedDisplayPrice =
              '\$5.990 / mes'; // Precio mensual (Hardcodeado)
          _selectedPlanDescription =
              'Pacientes ilimitados, perfil destacado y gestión avanzada.';
        } else {
          // Annual
          _selectedPriceId = _kineAnnualPriceId;
          // ⚠️ ¡AJUSTA ESTE TEXTO! Este es un precio de ejemplo.
          _selectedDisplayPrice =
              '\$49.990 / año'; // Precio anual (Hardcodeado)
          _selectedPlanDescription =
              'Todos los beneficios de Kine Pro, con 2 meses de descuento.';
        }
      } else {
        // patient
        _selectedPlanTitle = 'Paciente Pro';
        _selectedFeatures = [
          'Reservas Instantáneas (sin espera)',
          'Soporte Prioritario 24/7',
          'Descuentos en futuras funciones',
        ];

        if (cycle == BillingCycle.monthly) {
          _selectedPriceId = _patientMonthlyPriceId;
          _selectedDisplayPrice = '\$4.990 / mes'; // Precio (Hardcodeado)
          _selectedPlanDescription =
              'Acceso prioritario y reserva instantánea.';
        } else {
          // Annual
          _selectedPriceId = _patientAnnualPriceId;
          _selectedDisplayPrice = '\$49.990 / año'; // Precio (Hardcodeado)
          _selectedPlanDescription =
              'Todos los beneficios de Paciente Pro, con 2 meses de descuento.';
        }
      }
    });
  }

  /// 4. Maneja el proceso de suscripción
  Future<void> _handleSubscription() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }

      // 1. Obtiene el Price ID del estado (ya sea mensual o anual)
      final String priceId = _selectedPriceId;

      // 2. Verificación
      if (priceId.contains('TU_ID')) {
        throw Exception(
          'Configuración pendiente para el plan: ${widget.userType} - ${_selectedCycle.first.name}',
        );
      }

      // 3. Llama al servicio
      print("Solicitando URL de checkout para $priceId...");
      final String checkoutUrl = await _stripeService.createCheckoutSession(
        priceId,
      );

      // 4. Lanza la URL
      print("URL recibida, lanzando Stripe...");
      await _stripeService.launchStripeCheckout(checkoutUrl);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Error al iniciar la suscripción: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al iniciar el pago: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Widget helper para construir una fila de beneficio
  Widget _buildFeatureRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.teal, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar a Pro'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.teal,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 5. SELECTOR DE CICLO DE PAGO ---
            Center(
              child: SegmentedButton<BillingCycle>(
                segments: const [
                  ButtonSegment(
                    value: BillingCycle.monthly,
                    label: Text('Mensual'),
                    icon: Icon(Icons.calendar_today),
                  ),
                  ButtonSegment(
                    value: BillingCycle.annual,
                    label: Text('Anual (Ahorra)'),
                    icon: Icon(Icons.calendar_month),
                  ),
                ],
                selected: _selectedCycle,
                onSelectionChanged: (Set<BillingCycle> newSelection) {
                  // --- 👇 MEJORA AÑADIDA AQUÍ 👇 ---
                  // Solo actualiza si la nueva selección no está vacía
                  if (newSelection.isNotEmpty) {
                    _updateSelectedPlan(widget.userType, newSelection.first);
                  }
                  // --- FIN MEJORA ---
                },
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor: Colors.teal.shade50,
                  selectedForegroundColor: Colors.teal.shade900,
                  foregroundColor: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- 6. TARJETA DINÁMICA ---
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPlanTitle, // Dinámico
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedPlanDescription, // Dinámico
                      style: TextStyle(
                        fontSize: 17,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _selectedDisplayPrice, // Dinámico
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(height: 30, thickness: 1),
                    Text(
                      'Beneficios incluidos:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // Mapea la lista de beneficios (que ya no es null)
                    ..._selectedFeatures.map(
                      (feature) => _buildFeatureRow(feature),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // --- 7. BOTÓN DE SUSCRIPCIÓN ---
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Suscribirse Ahora',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            Text(
              'El pago es procesado de forma segura por Stripe. Puedes cancelar en cualquier momento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
