import 'package:cloud_firestore/cloud_firestore.dart';

// Este servicio se encarga de las operaciones con la colección 'ejercicio'
class ExercisesService {
  final CollectionReference exercisesCollection =
      FirebaseFirestore.instance.collection('ejercicio');

  final CollectionReference difficultiesCollection =
      FirebaseFirestore.instance.collection('dificultad');
  
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('categoria');

  // Método para obtener todos los documentos de la colección 'ejercicio'
  // y adjuntar los nombres de las dificultades y categorías.
  Future<List<Map<String, dynamic>>> getExercisesWithDetails() async {
    // Usar Future.wait para hacer todas las consultas en paralelo.
    final results = await Future.wait([
      exercisesCollection.get(),
      difficultiesCollection.get(),
      categoriesCollection.get(),
    ]);

    final exercisesSnapshot = results[0] as QuerySnapshot;
    final difficultiesSnapshot = results[1] as QuerySnapshot;
    final categoriesSnapshot = results[2] as QuerySnapshot;

    // Crear un mapa para buscar rápidamente los nombres de las dificultades por ID.
    final Map<String, String> difficultiesMap = {};
    for (var doc in difficultiesSnapshot.docs) {
      difficultiesMap[doc.id] = doc['nombre'] as String;
    }
    
    // Crear un mapa para buscar rápidamente los nombres de las categorías por ID.
    final Map<String, String> categoriesMap = {};
    for (var doc in categoriesSnapshot.docs) {
      categoriesMap[doc.id] = doc['nombre'] as String;
    }

    // Mapear los documentos de ejercicios y adjuntar el nombre de la dificultad y categoría.
    return exercisesSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Obtener las referencias de dificultad y categoría.
      final DocumentReference difficultyRef = data['dificultad'];
      final DocumentReference categoryRef = data['categoria'];

      final difficultyName = difficultiesMap[difficultyRef.id] ?? 'Dificultad no disponible';
      final categoryName = categoriesMap[categoryRef.id] ?? 'Categoría no disponible';
      
      // Retornar un nuevo mapa que incluya los nombres de la dificultad y categoría.
      return {
        ...data,
        'id': doc.id,
        'dificultadNombre': difficultyName,
        'categoriaNombre': categoryName,
      };
    }).toList();
  }
}

// Este servicio se encarga de las operaciones con la colección 'categoria'
class CategoriesService {
  final CollectionReference categoriesCollection = FirebaseFirestore.instance.collection('categoria');

// Método para obtener todas las categorías
Future<QuerySnapshot> getCategories() {
 return categoriesCollection.get();
}
}

// Este servicio se encarga de las operaciones con la colección 'dificultad'
class DifficultiesService {
final CollectionReference difficultiesCollection =
FirebaseFirestore.instance.collection('dificultad');

// Método para obtener todas las dificultades
Future<QuerySnapshot> getDifficulties() {return difficultiesCollection.get();}
}
