class Exercise {
  final String id;
  final String nombre;
  final String descripcion;
  final String urlVideo;
  final String categoria;
  final String dificultad;

  Exercise({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.urlVideo,
    required this.categoria,
    required this.dificultad,
  });

  factory Exercise.fromMap(Map<String, dynamic> data, String documentId) {
    return Exercise(
      id: documentId,
      nombre: data['nombre'] ?? '',
      descripcion: data['descripcion'] ?? '',
      urlVideo: data['url_video'] ?? '',
      categoria: data['categoria'] ?? '',
      dificultad: data['dificultad'] ?? '',
    );
  }
}