import 'package:flutter/material.dart';

class UserSubmissionScreen extends StatelessWidget {
  const UserSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Submission'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Users will be able to submit their own content here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
