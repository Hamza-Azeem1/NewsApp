import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Privacy Policy"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text("Privacy Policy",
                style: t.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: 14),

            Text(
              """
**Introduction**  
This Privacy Policy explains how user information is collected, stored, and used within this application. By using the service, you acknowledge that you have read and understood this policy.

**Information We Collect**  
The application may collect or receive the following types of information:

**1. Personal Information Provided by the User**  
• Information submitted through forms (e.g., feedback, job submissions, or contact entries).  
• Content you voluntarily provide such as text, links, or attachments.

**2. Automatically Collected Information**  
• Device type, operating system, and general interaction data.  
• Usage analytics, crash reports, and performance statistics.  
• Non-identifying technical information that helps improve the service.

**3. Third-Party Data**  
Some content, such as job listings, news articles, or tool links, may originate from third-party sources. External websites may collect their own data according to their respective policies.

**How We Use the Information**  
Information may be used for the following purposes:  
• To display content such as news, tools, and job listings  
• To improve user experience and application performance  
• To respond to submissions or feedback  
• To maintain security and prevent misuse  
• To perform analytics and understand app usage patterns  

**Sharing of Information**  
The application does **not** sell or rent user information. Information may only be shared in the following cases:

• With third-party service providers such as analytics or crash-reporting platforms  
• When required by law, legal process, or lawful government request  
• With external sites you voluntarily choose to open through the app (e.g., job application links, tool websites)

The service is not responsible for how external websites handle user data.

**External Links**  
The application may display or redirect users to third-party sites. Once you leave the app, this Privacy Policy no longer applies. We recommend reviewing the privacy policies of any external platform you visit.

**User-Submitted Content**  
If you submit content (such as job information, messages, feedback, or links), you are responsible for ensuring the information is lawful, accurate, and free from personal identifiers unless voluntarily provided.

**Data Retention**  
Data is retained only for as long as necessary to operate and maintain the service. Information may be removed periodically or upon user request where applicable.

**Security**  
Reasonable measures are applied to protect user information against unauthorized access, loss, or misuse. However, no system is completely secure, and absolute protection cannot be guaranteed.

**Children’s Privacy**  
This application is not intended for children under the age of 13. No personal information is knowingly collected from children. If such information is detected, it will be removed promptly.

**Your Choices and Controls**  
Users may choose to:  
• Stop using the application at any time  
• Avoid submitting optional information  
• Restrict device permissions such as notifications or storage access  
• Request removal of specific voluntarily submitted content (where technically feasible)

**Changes to This Policy**  
This Privacy Policy may be updated periodically to reflect improvements or legal requirements. Continued use of the service indicates acceptance of any revisions.

**Contact**  
For questions, concerns, or requests regarding this Privacy Policy, please reach out via the support section within the application.
""",
              style: t.bodyMedium?.copyWith(
                height: 1.55,
                color: cs.onSurface.withValues(alpha: .85),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
