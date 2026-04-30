import 'package:flutter/material.dart';

class InstructorDetailPage extends StatelessWidget {
  const InstructorDetailPage({super.key, required this.instructorId});

  final String instructorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Instructor')),
      body: Center(child: Text('Instructor detail • id: $instructorId')),
    );
  }
}
