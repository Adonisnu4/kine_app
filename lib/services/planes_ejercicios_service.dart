import 'package:cloud_firestore/cloud_firestore.dart';

// Modifica la función para que devuelva una lista de DocumentSnapshot
Future<List<DocumentSnapshot>> obtenerTodosLosPlanesEjercicio() async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  
  try {
    // 1. Obtener la referencia y los datos
    QuerySnapshot querySnapshot = await db.collection('planes_ejercicio').get();

    // 2. Devolver la lista de documentos
    return querySnapshot.docs;

  } catch (e) {
    print('Error al obtener los planes de ejercicio: $e');
    // Si hay un error, puedes devolver una lista vacía o lanzar una excepción
    return []; 
  }
}

Future<Map<String, dynamic>?> ObtenerPlanEjercicio(String idPlan) async {
  FirebaseFirestore db = FirebaseFirestore.instance;
  DocumentReference documentoPlan = db.collection('planes_ejercicio').doc(idPlan);

  try {    
    DocumentSnapshot documentSnapshot = await documentoPlan.get();

    if (documentSnapshot.exists) {
      return documentSnapshot.data() as Map<String, dynamic>?;
    } else {
      print('El plan con ID $idPlan no existe.');
      return null;
    }

  } catch (e) {
    print('Error al obtener el plan de ejercicio: $e');
    return null; 
  }
}