// lib/screens/subscription_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:kine_app/features/Stripe/services/stripe_service.dart';

/// Enum que representa el ciclo de facturación posible.
/// monthly = pago mensual
/// annual = pago anual con descuento
enum BillingCycle { monthly, annual }

/// Pantalla donde un usuario (kine o paciente)
/// puede visualizar su plan y contratar el plan PRO correspondiente.
///
/// Recibe como parámetro:
/// - userType: "kine" o "patient"
class SubscriptionScreen extends StatefulWidget {
  final String userType;
  const SubscriptionScreen({super.key, required this.userType});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  // Paleta de colores usada en la aplicación
  static const _blue = Color(0xFF47A5D6);
  static const _orange = Color(0xFFE28825);
  static const _bg = Color(0xFFF7F3F7);

  /// Servicio que contiene las funciones para conectar con Stripe:
  /// - createCheckoutSession()
  /// - launchStripeCheckout()
  final StripeService _stripeService = StripeService();

  /// Indica si se está ejecutando un proceso de pago
  bool _isLoading = false;

  /// Price IDs configurados en Stripe para Kinesiólogos
  final String _kineMonthlyPriceId = 'price_1SNKvSPMEZlnmK1ZrZ3Sk99F';
  final String _kineAnnualPriceId = 'price_1SNKvSPMEZlnmK1Zwh0EzLu6';

  /// Estos IDs deben reemplazarse si activas planes PRO para pacientes
  final String _patientMonthlyPriceId = 'price_TU_ID_PACIENTE_MENSUAL';
  final String _patientAnnualPriceId = 'price_TU_ID_PACIENTE_ANUAL';

  /// Estado del ciclo de facturación seleccionado por el usuario
  BillingCycle _cycle = BillingCycle.monthly;

  /// Variables que se actualizan al cambiar ciclo o tipo de usuario
  String _selectedPriceId = '';
  String _selectedPlanTitle = '';
  String _selectedPlanDescription = '';
  String _selectedDisplayPrice = '';
  List<String> _selectedFeatures = [];

  @override
  void initState() {
    super.initState();
    // Carga inicial del plan según userType y ciclo de facturación
    _updateSelectedPlan(widget.userType, _cycle);
  }

  /// Maneja la lógica para:
  /// - Determinar precio según ciclo
  /// - Determinar características del plan
  /// - Actualizar textos y display del valor
  ///
  /// userType: "kine" o "patient"
  /// cycle: mensual o anual
  void _updateSelectedPlan(String userType, BillingCycle cycle) {
    _cycle = cycle;

    // Configuración para Kinesiólogos
    if (userType == 'kine') {
      _selectedPlanTitle = 'Kine Pro';
      _selectedFeatures = [
        'Perfil destacado en búsquedas',
        'Pacientes ilimitados',
      ];

      if (cycle == BillingCycle.monthly) {
        _selectedPriceId = _kineMonthlyPriceId;
        _selectedDisplayPrice = '\$5.990 / mes';
        _selectedPlanDescription =
            'Pacientes ilimitados, perfil destacado y gestión avanzada.';
      } else {
        _selectedPriceId = _kineAnnualPriceId;
        _selectedDisplayPrice = '\$49.990 / año';
        _selectedPlanDescription =
            'Todos los beneficios de Kine Pro, con 2 meses de descuento.';
      }
    } else {
      // Configuración si activas planes para pacientes
      _selectedPlanTitle = 'Paciente Pro';
      _selectedFeatures = [
        'Reservas instantáneas',
        'Soporte prioritario',
        'Descuentos futuros',
      ];

      if (cycle == BillingCycle.monthly) {
        _selectedPriceId = _patientMonthlyPriceId;
        _selectedDisplayPrice = '\$4.990 / mes';
        _selectedPlanDescription = 'Acceso prioritario y reserva instantánea.';
      } else {
        _selectedPriceId = _patientAnnualPriceId;
        _selectedDisplayPrice = '\$49.990 / año';
        _selectedPlanDescription =
            'Todos los beneficios con 2 meses de descuento.';
      }
    }

    // Actualiza la UI
    setState(() {});
  }

  /// Inicia el proceso de suscripción:
  /// 1. Verifica usuario autenticado
  /// 2. Valida el priceId
  /// 3. Crea la sesión de Stripe (Checkout)
  /// 4. Abre el navegador para procesar el pago
  /// 5. Retorna a la pantalla anterior
  Future<void> _handleSubscription() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado.');
      }

      // Verifica que tengas configurado un priceId válido
      if (_selectedPriceId.contains('TU_ID')) {
        throw Exception(
          'Configura correctamente el priceId del plan seleccionado.',
        );
      }

      // Crea sesión de Checkout en Stripe
      final url = await _stripeService.createCheckoutSession(_selectedPriceId);

      // Abre Stripe en el navegador
      await _stripeService.launchStripeCheckout(url);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // Muestra error en pantalla
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar el pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Termina el estado de carga
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Construye un ítem de característica dentro de la tarjeta de beneficios
  Widget _buildFeatureRow(String text, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: accent, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15.5, color: Color(0xFF4B5563)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color activeColor = _cycle == BillingCycle.monthly ? _blue : _orange;

    return Scaffold(
      backgroundColor: _bg,

      // Barra superior
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF111827),
        title: const Text(
          'Actualizar a Pro',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      // Contenido completo
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Selector de ciclo (mensual / anual)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: activeColor.withOpacity(.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Opción mensual
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _updateSelectedPlan(
                        widget.userType,
                        BillingCycle.monthly,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _cycle == BillingCycle.monthly
                              ? _blue
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              size: 16,
                              color: _cycle == BillingCycle.monthly
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Mensual',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _cycle == BillingCycle.monthly
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 4),

                  // Opción anual
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _updateSelectedPlan(
                        widget.userType,
                        BillingCycle.annual,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _cycle == BillingCycle.annual
                              ? _orange
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              size: 16,
                              color: _cycle == BillingCycle.annual
                                  ? Colors.white
                                  : const Color(0xFF4B5563),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Anual (Ahorra)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _cycle == BillingCycle.annual
                                    ? Colors.white
                                    : const Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // Tarjeta con información del plan
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: activeColor.withOpacity(.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPlanTitle,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                      letterSpacing: -.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _selectedPlanDescription,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: Color(0xFF6B7280),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _selectedDisplayPrice,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Divider(color: Colors.grey.shade100, thickness: 1),

                  const SizedBox(height: 10),

                  const Text(
                    'Beneficios incluidos:',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Lista de beneficios
                  ..._selectedFeatures.map(
                    (f) => _buildFeatureRow(f, activeColor),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Botón principal para iniciar la compra
            ElevatedButton(
              onPressed: _isLoading ? null : _handleSubscription,
              style: ElevatedButton.styleFrom(
                backgroundColor: activeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Suscribirse ahora',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
            ),

            const SizedBox(height: 16),

            const Text(
              'El pago es procesado de forma segura por Stripe. Puedes cancelar en cualquier momento.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      ),
    );
  }
}
