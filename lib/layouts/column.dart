import 'package:flutter/material.dart';



class ColumnExample extends StatelessWidget {
  const ColumnExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Hola"),
        Text("Hola"),
        Text("Hola"),

      ],
    );
  }
}