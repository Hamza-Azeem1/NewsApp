import 'package:flutter/material.dart';
import '../screens/bookmarks_screen.dart';
import '../screens/jobs_screen.dart';
import '../screens/user_submission_screen.dart';
import '../screens/terms_screen.dart';
import '../screens/disclaimer_screen.dart';

class SideDrawer extends StatelessWidget {
  /// Kept for compatibility, but we now rely on Theme.of(context).brightness
  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  const SideDrawer({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    // 👇 Always use the REAL current theme from context
    final effectiveIsDark =
        Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // =======================
            // HEADER
            // =======================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore',
                    style: t.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'More options & info',
                    style: t.bodyMedium?.copyWith(
                      color: cs.onPrimaryContainer.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // =======================
            // MENU ITEMS
            // =======================
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _item(
                    context,
                    icon: Icons.work_outline_rounded,
                    text: 'Jobs',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const JobsScreen(),
                        ),
                      );
                    },
                  ),
                  _item(
                    context,
                    icon: Icons.upload_file_rounded,
                    text: 'User Submission',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const UserSubmissionScreen(),
                        ),
                      );
                    },
                  ),
                  _item(
                    context,
                    icon: Icons.bookmark_rounded,
                    text: 'Bookmarks / Saved',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BookmarksScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 24),

                  _item(
                    context,
                    icon: Icons.gavel_rounded,
                    text: 'Terms & Conditions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsScreen(),
                        ),
                      );
                    },
                  ),
                  _item(
                    context,
                    icon: Icons.report_problem_rounded,
                    text: 'Disclaimer',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DisclaimerScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 24),

                  // =======================
                  // 🌗 THEME TOGGLE
                  // =======================
                  SwitchListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20),
                    secondary: Icon(
                      effectiveIsDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      color: cs.primary,
                    ),
                    title: const Text(
                      'Dark mode',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    value: effectiveIsDark,
                    onChanged: (value) {
                      // Tell root to change theme
                      onThemeChanged(value);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: Icon(icon, color: cs.primary),
      title: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      minLeadingWidth: 26,
      horizontalTitleGap: 12,
      hoverColor: cs.primaryContainer.withOpacity(0.2),
    );
  }
}
