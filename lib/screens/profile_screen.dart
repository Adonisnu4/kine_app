import 'package:flutter/material.dart';
import 'package:kine_app/layouts/column.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: 
            ColumnExample()
          ,
        ),
      ),
    );
  }
}