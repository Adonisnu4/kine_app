// lib/services/stripe_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ===========================================
  ///  ✅ 1. Crear checkout de Stripe
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
  /// ✅ 3. Verificar si tiene suscripción activa
  /// ===========================================
  Future<bool> checkProSubscriptionStatus() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final query = await _firestore
          .collection('customers')
          .doc(user.uid)
          .collection('subscriptions')
          .where('status', whereIn: ['active', 'trialing'])
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        print("checkProSubscriptionStatus: Usuario ES Pro.");
        return true;
      } else {
        print("checkProSubscriptionStatus: Usuario NO es Pro.");
        return false;
      }
    } catch (e) {
      print("Error en checkProSubscriptionStatus: $e");
      return false;
    }
  }

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

      print("✅ getUserPlanStatus → isPro: $isPro, limit: $limit");

      return {'isPro': isPro, 'limit': limit};
    } catch (e) {
      print("Error en getUserPlanStatus: $e");
      return {'isPro': false, 'limit': 50};
    }
  }
}
