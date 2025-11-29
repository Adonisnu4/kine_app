// lib/services/stripe_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

/// Servicio encargado de manejar la integración con Stripe.
/// Funcionalidades principales:
//Crear sesiones de pago con Checkout.
//Lanzar la URL del pago.
//Verificar suscripciones activas usando Firestore.
//Validar suscripciones directamente contra Stripe (opcional).
//Obtener información del plan del usuario.
class StripeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Crear Checkout Session en Stripe

  // Crea un checkout session mediante la integración nativa de Firebase + Stripe.

  // Paso a paso:
  // - Crea un documento temporal en:
  //   customers/{uid}/checkout_sessions/{sessionId}
  // - Ese documento es procesado por una Cloud Function oficial de Stripe.
  // - Cuando Stripe genera la URL de pago, escribe el campo "url".
  // - Este método escucha el documento hasta recibir la URL o un error.
  Future<String> createCheckoutSession(String priceId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado.");

    // Referencia al documento de checkout (se crea vacío al inicio)
    final docRef = _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('checkout_sessions')
        .doc();

    print("Creando documento de checkout en: ${docRef.path}");

    // Completer que aguardará hasta obtener la URL o un error
    final completer = Completer<String>();

    // Listener que espera cambios en el documento
    final StreamSubscription subscription = docRef.snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data != null) {
          // Manejo de errores devueltos por Stripe
          if (data.containsKey('error')) {
            final error = data['error']['message'];
            print("Error creando checkout: $error");

            if (!completer.isCompleted) {
              completer.completeError(Exception("Error de Stripe: $error"));
            }

            // Stripe devuelve la URL del checkout
          } else if (data.containsKey('url')) {
            final String url = data['url'];
            print("URL de Checkout recibida: $url");

            if (!completer.isCompleted) {
              completer.complete(url);
            }
          }
        }
      },
      onError: (error) {
        // Error en el listener
        if (!completer.isCompleted) {
          completer.completeError(
            Exception("Error al escuchar snapshot: $error"),
          );
        }
      },
    );

    // Se escribe la solicitud para que la Cloud Function genere la sesión
    await docRef.set({
      'price': priceId,
      'success_url': 'https://kine-8c247.web.app/exito',
      'cancel_url': 'https://kine-8c247.web.app/cancelado',
      'mode': 'subscription',
    });

    // Espera máxima de 20 segundos para recibir la URL desde Stripe
    final url = await completer.future.timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        subscription.cancel();
        throw TimeoutException(
          "Se agotó el tiempo de espera para la URL de Stripe.",
        );
      },
    );

    subscription.cancel();
    return url;
  }

  //Lanzar la URL de Checkout en el navegador

  /// Abre el navegador (o app externa) para iniciar el pago con Stripe Checkout.
  Future<void> launchStripeCheckout(String url) async {
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo lanzar la URL de pago $url';
    }
  }

  //Verificar suscripción usando Firestore
  // Verifica si el usuario tiene un plan Pro activo consultando la colección "usuarios".
  ///Esta es la forma recomendada para tu app móvil:
  // - Lee el campo isPro
  // - Lee el campo plan
  // Estos campos deben ser actualizados desde tu backend (webhook Stripe + Cloud Functions).
  Future<bool> checkProSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        print("Documento del usuario no encontrado en 'usuarios/'.");
        return false;
      }

      final data = userDoc.data()!;
      final bool isPro = data['isPro'] ?? false;
      final String plan = data['plan'] ?? 'estandar';

      print("Estado Firestore → isPro: $isPro | plan: $plan");

      return isPro == true || plan.toLowerCase() == 'pro';
    } catch (e) {
      print("Error en checkProSubscriptionStatus (Firestore): $e");
      return false;
    }
  }

  //Verificar suscripción directamente en Stripe (requiere secret key)

  /// Consulta directamente la API de Stripe para validar si la suscripción está activa.
  /// Advertencia:
  /// - Nunca deberías exponer la clave secreta en el cliente.
  /// - Este método debe usarse solo en pruebas.
  /// - En producción, mover esta lógica a Cloud Functions.
  Future<bool> verifyWithStripeAPI() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Clave secreta (solo para pruebas locales)
      const stripeSecretKey =
          'sk_test_51SNKboPMEZlnmK1ZIamV1fVfcuMH6r2d8sDgWlhbRgMH4ZWZITT7wNBdCVjGrW2kc2FEyX9yFyHmki9qQW92RmIj00eGqOyM1c';

      // Obtiene el stripeId del usuario
      final customerDoc = await _firestore
          .collection('customers')
          .doc(user.uid)
          .get();

      if (!customerDoc.exists) return false;

      final customerId = customerDoc.data()?['stripeId'];
      if (customerId == null) {
        print("Cliente sin 'stripeId' en Firestore.");
        return false;
      }

      // Consulta las suscripciones del cliente directamente en Stripe
      final url = Uri.parse(
        'https://api.stripe.com/v1/subscriptions?customer=$customerId',
      );

      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $stripeSecretKey'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List subs = data['data'] ?? [];

        // Busca una suscripción activa
        final activeSub = subs.firstWhere(
          (s) => s['status'] == 'active' || s['status'] == 'trialing',
          orElse: () => null,
        );

        if (activeSub != null) {
          final end = activeSub['current_period_end'];
          final endDate = DateTime.fromMillisecondsSinceEpoch(end * 1000);

          if (endDate.isAfter(DateTime.now())) {
            print("Verificado en Stripe: suscripción activa hasta $endDate");
            return true;
          }
        }
      } else {
        print("Error Stripe API: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      print("Error verificando con Stripe API: $e");
    }

    return false;
  }

  //Obtener estado del plan desde la colección usuarios/

  /// Retorna:
  /// - isPro (bool)
  /// - limit (cantidad de pacientes permitidos)
  /// Estos valores se usan en:
  /// - MyPatientsScreen
  /// - Bloqueos de funciones PRO
  /// - UI general
  Future<Map<String, dynamic>> getUserPlanStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'isPro': false, 'limit': 50};
      }

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (!doc.exists) {
        return {'isPro': false, 'limit': 50};
      }

      final data = doc.data()!;
      final bool isPro = data['isPro'] ?? false;
      final int limit = data['patientLimit'] ?? 50;

      print("getUserPlanStatus → isPro: $isPro, limit: $limit");

      return {'isPro': isPro, 'limit': limit};
    } catch (e) {
      print("Error en getUserPlanStatus: $e");
      return {'isPro': false, 'limit': 50};
    }
  }
}
