import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageTestScreen extends StatelessWidget {
  const ImageTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String imageUrl = 'https://kineapp.blob.core.windows.net/imagenes/imagen_test.jpg';

    return Scaffold(
      body: Center(
        child: CachedNetworkImage(
        imageUrl: "https://kineapp.blob.core.windows.net/imagenes/imagen_test.jpg",
        placeholder: (context, url) => CircularProgressIndicator(),
        errorWidget: (context, url, error) => Icon(Icons.error),
     ),
      ),
    );
  }
}