import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../../app/screens/in_app_browser.dart';

class TeacherCard extends StatelessWidget {
  final Teacher t;
  const TeacherCard({super.key, required this.t});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Responsive tuning (tiny phones get a bit more compact)
    final w = MediaQuery.sizeOf(context).width;
    final isSmallPhone = w < 360;
    final isPhone = w < 600;
    final bannerH = isSmallPhone ? 120.0 : (isPhone ? 140.0 : 160.0);
    final avatarR = isSmallPhone ? 28.0 : 32.0; // visible face ✔
    final bioLines = isSmallPhone ? 1 : (isPhone ? 2 : 3);
    final specMax = isSmallPhone ? 2 : (isPhone ? 3 : 4);
    final eduMax  = isSmallPhone ? 1 : (isPhone ? 2 : 3);

    return Card(
      elevation: 1.2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ---- Banner + Face Avatar (guarantees a complete face is visible) ----
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner: can crop a bit, that's fine now
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
                child: SizedBox(
                  height: bannerH,
                  width: double.infinity,
                  child: t.imageUrl == null || t.imageUrl!.isEmpty
                      ? Container(
                          color: cs.surfaceContainerHighest,
                          alignment: Alignment.center,
                          child: const Icon(Icons.person, size: 48),
                        )
                      : Image.network(
                          t.imageUrl!,
                          fit: BoxFit.cover,         // background look
                          alignment: Alignment.center,
                        ),
                ),
              ),
              // Round avatar (full image, not cropped) -> face always visible
              Positioned(
                left: 16,
                bottom: -avatarR, // overlap below banner
                child: CircleAvatar(
                  radius: avatarR,
                  backgroundColor: cs.surface,
                  child: CircleAvatar(
                    radius: avatarR - 3,
                    backgroundImage: (t.imageUrl != null && t.imageUrl!.isNotEmpty)
                        ? NetworkImage(t.imageUrl!)
                        : null,
                    child: (t.imageUrl == null || t.imageUrl!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                ),
              ),
            ],
          ),

          // Body
          Padding(
            // extra top padding because avatar overlaps
            padding: EdgeInsets.fromLTRB(12, avatarR + 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name
                Text(
                  t.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),

                // Profile (intro)
                if (t.intro?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  const _SectionPill(icon: Icons.badge_outlined, label: 'Profile'),
                  const SizedBox(height: 4),
                  Text(
                    t.intro!,
                    maxLines: bioLines,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Specializations
                if (t.specializations.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const _SectionPill(
                    icon: Icons.auto_awesome,
                    label: 'Specializations',
                  ),
                  const SizedBox(height: 6),
                  _Chips(items: t.specializations, max: specMax),
                ],

                // Education
                if (t.qualifications.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const _SectionPill(
                    icon: Icons.school_outlined,
                    label: 'Education',
                  ),
                  const SizedBox(height: 6),
                  _Chips(items: t.qualifications, max: eduMax),
                ],

                // Links
                if (t.socials.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const _SectionPill(
                    icon: Icons.link_rounded,
                    label: 'Links',
                  ),
                  const SizedBox(height: 6),
                  _LinksRow(socials: t.socials),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionPill({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _Chips extends StatelessWidget {
  final List<String> items;
  final int max;
  const _Chips({required this.items, this.max = 3});
  @override
  Widget build(BuildContext context) {
    final shown = items.take(max).toList();
    final remaining = items.length - shown.length;
    return Wrap(
      spacing: 8,
      runSpacing: 8, // positive spacing -> no overlap
      children: [
        for (final s in shown)
          Chip(
            label: Text(s, overflow: TextOverflow.ellipsis),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        if (remaining > 0) Text('+$remaining more'),
      ],
    );
  }
}

class _LinksRow extends StatelessWidget {
  final Map<String, String> socials;
  const _LinksRow({required this.socials});

  @override
  Widget build(BuildContext context) {
    final entries = socials.entries.toList();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final e in entries.take(3))
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: Icon(_iconFor(e.key), size: 18),
            label: Text(e.key),
            onPressed: () {
              // 👇 Open social link in *in-app* browser
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InAppBrowser(url: e.value),
                ),
              );
            },
          ),
        if (entries.length > 3) Text('+${entries.length - 3}'),
      ],
    );
  }

  IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('youtube')) return Icons.ondemand_video_rounded;
    if (l.contains('linkedin')) return Icons.business_center_outlined;
    if (l.contains('twitter') || l == 'x') return Icons.alternate_email_rounded;
    if (l.contains('github')) return Icons.code_rounded;
    if (l.contains('facebook')) return Icons.facebook_rounded;
    if (l.contains('instagram')) return Icons.camera_alt_outlined;
    if (l.contains('website') || l.contains('portfolio')) {
      return Icons.language_rounded;
    }
    if (l.contains('dribble') || l.contains('dribble')) {
      return Icons.sports_basketball_outlined;
    }
    if (l.contains('bechance')) return Icons.palette_outlined;
    return Icons.link_rounded;
  }
}
