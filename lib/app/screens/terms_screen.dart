import 'package:flutter/material.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Terms & Conditions"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Terms & Conditions",
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            Text(
              """
**Acceptance of Terms**  
By using this application, you agree to comply with and be bound by these Terms & Conditions. If you do not agree, you should discontinue use immediately.

**Use of the Service**  
The application provides access to news content, educational materials, tools, job listings, and user-submitted information for informational purposes only. You are responsible for using the service in a lawful and respectful manner.

**User Responsibilities**  
• You may not misuse, modify, or disrupt the service.  
• You may not upload harmful, offensive, or illegal material.  
• You must ensure that any information you submit is accurate and does not infringe on the rights of others.  
• You are responsible for maintaining the security of your device and login credentials.

**Content and Information**  
The content available through the service may include news, articles, tools, links, job listings, courses, or other informational material. No guarantee is made regarding accuracy, reliability, or completeness. Content may be updated, changed, or removed without notice.

**External Links**  
Some sections may contain links to third-party websites. These websites are not controlled or endorsed, and no responsibility is taken for their content, availability, or policies. Users access external sites at their own discretion.

**Intellectual Property**  
All designs, text, visuals, logos, and other materials within the app are protected under applicable intellectual property laws. Unauthorized copying, distribution, or reuse of materials is prohibited.

**Limitation of Liability**  
The service is provided “as is” without warranties of any kind. No liability is accepted for:  
• Errors or inaccuracies in the content  
• Losses resulting from reliance on provided information  
• Issues arising from external websites or third-party content  
• Data loss, service interruptions, or device-related problems  

Usage is at your own risk.

**Termination of Use**  
Access may be limited or removed if misuse, violations of these terms, or harmful behavior is detected.

**Changes to Terms**  
These Terms & Conditions may be updated periodically. Continued use of the service indicates acceptance of any revisions.

**Contact**  
For questions or concerns, please reach out through the support section within the application.
""",
              style: t.bodyMedium?.copyWith(
                height: 1.55,
                color: cs.onSurface.withOpacity(0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
