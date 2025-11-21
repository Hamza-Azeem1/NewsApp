import 'package:flutter/material.dart';

class DisclaimerScreen extends StatelessWidget {
  const DisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Disclaimer"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Disclaimer",
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),

            Text(
              """
**General Information**  
The content provided through this application — including articles, tools, job listings, external resources, and user-generated submissions — is intended for general informational purposes only. Nothing should be interpreted as professional, financial, legal, or career advice.

**No Guarantee of Accuracy**  
While efforts are made to maintain reliable and updated information, no guarantee is provided regarding the accuracy, completeness, or timeliness of any content. Information may become outdated or may contain unintentional errors.

**External Websites and Links**  
The application may redirect users to external websites or services. These external platforms are not monitored or endorsed, and no responsibility is taken for their content, safety, or policies. Users access third-party sites at their own risk.

**User-Submitted Content**  
Content contributed by users is not verified and may not reflect factual information. No liability is accepted for misleading, incorrect, or inappropriate submissions from users.

**No Liability**  
The application is not responsible for:  
• Decisions made based on content within the app  
• Losses related to job applications, external sites, or third-party resources  
• The accuracy or legitimacy of external content or links  
• Technical issues, interruptions, errors, or data loss  

All use of the application is at the user’s own discretion.

**Not a Substitute for Professional Guidance**  
Users should verify critical information independently, especially when making career, financial, educational, or personal decisions.

**Updates to This Disclaimer**  
This Disclaimer may be revised periodically. Continued use of the service indicates acceptance of the latest version.

**Contact**  
For clarification or questions, please reach out through the support section within the application.
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
