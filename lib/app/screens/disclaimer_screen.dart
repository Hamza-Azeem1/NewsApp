import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Disclaimer'),
      ),
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: DefaultTextStyle(
    style: t.bodyMedium!,
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        // ...
      ],
    ),
  ),
),

    );
  }
}
