import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: DefaultTextStyle(
          style: t.bodyMedium!,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Here you can add your app\'s terms and conditions. '
                'Explain usage rules, content policy, and any legal notes '
                'you want your users to know.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
