import 'package:cloud_firestore/cloud_firestore.dart';

// Este servicio se encarga de las operaciones con la colección 'ejercicios'
class ExercisesService {
  final CollectionReference exercisesCollection =
      FirebaseFirestore.instance.collection('ejercicios');

  final CollectionReference difficultiesCollection =
      FirebaseFirestore.instance.collection('dificultades');
  
  final CollectionReference categoriesCollection =
      FirebaseFirestore.instance.collection('categorias');

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

  // Nuevo método para obtener un ejercicio específico por su ID y adjuntar los nombres de la dificultad y categoría.
  Future<Map<String, dynamic>> getExerciseById(String exerciseId) async {
    // 1. Obtiene el documento del ejercicio
    final exerciseDoc = await exercisesCollection.doc(exerciseId).get();
    
    // 2. Si el ejercicio no existe, devuelve un mapa vacío
    if (!exerciseDoc.exists) {
      return {};
    }

    final data = exerciseDoc.data() as Map<String, dynamic>;
    
    // 3. Obtener las referencias de dificultad y categoría.
    final DocumentReference difficultyRef = data['dificultad'];
    final DocumentReference categoryRef = data['categoria'];

    // 4. Obtener los documentos de dificultad y categoría en paralelo.
    final results = await Future.wait([
      difficultyRef.get(),
      categoryRef.get(),
    ]);

    final difficultyDoc = results[0] as DocumentSnapshot;
    final categoryDoc = results[1] as DocumentSnapshot;
    
    final difficultyName = (difficultyDoc.data() as Map<String, dynamic>)['nombre'] ?? 'Dificultad no disponible';
    final categoryName = (categoryDoc.data() as Map<String, dynamic>)['nombre'] ?? 'Categoría no disponible';
    
    // 5. Retornar un nuevo mapa que incluya los nombres de la dificultad y categoría.
    return {
      ...data,
      'id': exerciseDoc.id,
      'dificultadNombre': difficultyName,
      'categoriaNombre': categoryName,
    };
  }
}

// Este servicio se encarga de las operaciones con la colección 'categoria'
class CategoriesService {final CollectionReference categoriesCollection = FirebaseFirestore.instance.collection('categorias');

// Método para obtener todas las categorías
Future<QuerySnapshot> getCategories() {return categoriesCollection.get();
}
}

// Este servicio se encarga de las operaciones con la colección 'dificultad'
class DifficultiesService {
final CollectionReference difficultiesCollection =
FirebaseFirestore.instance.collection('dificultades');

// Método para obtener todas las dificultades
Future<QuerySnapshot> getDifficulties() {return difficultiesCollection.get();}
}
