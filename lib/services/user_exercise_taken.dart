import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserExerciseTaken {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getUserTakenExercises() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return [];
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> userExercisesSnapshot = await _firestore
          .collection('ejercicios_tomados_por_usuarios')
          .doc(user.uid)
          .collection('mis_ejercicios')
          .get();

      final List<Map<String, dynamic>> takenExercises = [];

      for (var userExerciseDoc in userExercisesSnapshot.docs) {
        final dynamic exerciseRefData = userExerciseDoc.data()['ejercicio'];
        if (exerciseRefData is! DocumentReference) {
          print('El documento de usuario ${user.uid} tiene un ejercicio con referencia inválida.');
          continue;
        }
        
        final DocumentReference<Map<String, dynamic>> exerciseRef = exerciseRefData as DocumentReference<Map<String, dynamic>>;
        
        final DocumentSnapshot<Map<String, dynamic>> exerciseDoc = await exerciseRef.get();
        
        if (exerciseDoc.exists) {
          final Map<String, dynamic> exerciseData = exerciseDoc.data()!;
          
          exerciseData['id'] = exerciseDoc.id; 

          // CORRECCIÓN APLICADA AQUÍ: Ahora se usan los nombres 'dificultad' y 'categoria'
          final dynamic dificultadRefData = exerciseData['dificultad'];
          final dynamic categoriaRefData = exerciseData['categoria'];

          if (dificultadRefData is DocumentReference && categoriaRefData is DocumentReference) {
            final DocumentReference<Map<String, dynamic>> dificultadRef = dificultadRefData as DocumentReference<Map<String, dynamic>>;
            final DocumentReference<Map<String, dynamic>> categoriaRef = categoriaRefData as DocumentReference<Map<String, dynamic>>;

            final DocumentSnapshot<Map<String, dynamic>> dificultadDoc = await dificultadRef.get();
            final DocumentSnapshot<Map<String, dynamic>> categoriaDoc = await categoriaRef.get();

            exerciseData['dificultadNombre'] = dificultadDoc.data()?['nombre'];
            exerciseData['categoriaNombre'] = categoriaDoc.data()?['nombre'];
          } else {
            // Manejar el caso en que las referencias no existen o son de tipo incorrecto
            exerciseData['dificultadNombre'] = 'Desconocida';
            exerciseData['categoriaNombre'] = 'Desconocida';
          }

          takenExercises.add(exerciseData);
        }
      }

      return takenExercises;
    } catch (e) {
      print('Error obteniendo los ejercicios del usuario: $e');
      return [];
    }
  }
}