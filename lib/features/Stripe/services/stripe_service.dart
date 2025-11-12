// lib/services/stripe_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class StripeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ===========================================
  /// ✅ 1. Crear checkout de Stripe
  /// ===========================================
  Future<String> createCheckoutSession(String priceId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("Usuario no autenticado.");

    final docRef = _firestore
        .collection('customers')
        .doc(user.uid)
        .collection('checkout_sessions')
        .doc();

    print("Creando documento de checkout en: ${docRef.path}");

    final completer = Completer<String>();

    final StreamSubscription subscription = docRef.snapshots().listen(
      (snapshot) {
        final data = snapshot.data();
        if (data != null) {
          if (data.containsKey('error')) {
            final error = data['error']['message'];
            print("Error creando checkout: $error");
            if (!completer.isCompleted) {
              completer.completeError(Exception("Error de Stripe: $error"));
            }
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
        if (!completer.isCompleted) {
          completer.completeError(
            Exception("Error al escuchar snapshot: $error"),
          );
        }
      },
    );

    await docRef.set({
      'price': priceId,
      'success_url': 'https://kine-8c247.web.app/exito',
      'cancel_url': 'https://kine-8c247.web.app/cancelado',
      'mode': 'subscription',
    });

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

  /// ===========================================
  /// ✅ 2. Abrir URL del checkout
  /// ===========================================
  Future<void> launchStripeCheckout(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'No se pudo lanzar la URL de pago $url';
    }
  }

  /// ===========================================
  /// ✅ 3. Verificar si tiene suscripción activa (versión sincronizada con Firestore)
  /// ===========================================
  Future<bool> checkProSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // 🔍 Leer directamente desde la colección "usuarios"
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

  /// ===========================================
  /// ✅ 4. Verificación directa con Stripe (requiere clave secreta)
  /// ===========================================
  Future<bool> verifyWithStripeAPI() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      // Tu clave secreta de Stripe (MEJOR usar en Cloud Function)
      const stripeSecretKey =
          'sk_test_51SNKboPMEZlnmK1ZIamV1fVfcuMH6r2d8sDgWlhbRgMH4ZWZITT7wNBdCVjGrW2kc2FEyX9yFyHmki9qQW92RmIj00eGqOyM1c';

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

  /// ===========================================
  /// ✅ 5. Obtener estado de plan guardado en usuarios/
  /// ===========================================
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
