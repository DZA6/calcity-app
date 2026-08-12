import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content.dart';
import '../providers/content_provider.dart';
import 'detail_screen.dart';

/// Detail view for one school: information, quick-link buttons
/// (schedule, calendar, website, call), and that school's news.
class SchoolDetailScreen extends StatelessWidget {
  final SchoolItem school;
  const SchoolDetailScreen({super.key, required this.school});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _typeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'elementary':
        return Icons.child_care;
      case 'middle':
        return Icons.school;
      case 'high':
        return Icons.architecture;
      default:
        return Icons.school_outlined;
    }
  }

  /// Best-guess keyword to match this school to education news items.
  String _newsKeyword() {
    final name = school.name.toLowerCase();
    for (final kw in ['high school', 'middle school', 'elementary']) {
      if (name.contains(kw)) return kw;
    }
    final words = name.split(' ')..removeWhere((w) => w.isEmpty);
    return words.isNotEmpty ? words.last : name;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kw = _newsKeyword();

    return Scaffold(
      appBar: AppBar(title: Text(school.name)),
      body: Consumer<ContentProvider>(
        builder: (context, prov, _) {
          final eduNews =
              prov.news.where((n) => n.category == 'education').toList();
          var schoolNews = eduNews
              .where(
                  (n) => '${n.title} ${n.content}'.toLowerCase().contains(kw))
              .toList();
          if (schoolNews.isEmpty) schoolNews = eduNews;

          return ListView(
            padding: const EdgeInsets.all(14),
            children: [
              // Header
              Container(
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_typeIcon(school.type),
                              color: cs.primary, size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(school.name,
                                  style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface)),
                              if (school.type != null)
                                Text(school.type!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: cs.primary,
                                        fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (school.description != null &&
                        school.description!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(school.description!,
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurfaceVariant,
                              height: 1.4)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Quick-link buttons
              _sectionHeader(cs, 'Quick Links'),
              const SizedBox(height: 8),
              if (school.bellScheduleUrl != null)
                _linkButton(
                    cs,
                    Icons.schedule_outlined,
                    'School Schedule',
                    'Bell schedule & daily class times',
                    () => _launch(school.bellScheduleUrl!)),
              if (school.calendarUrl != null)
                _linkButton(
                    cs,
                    Icons.calendar_month_outlined,
                    'School Calendar',
                    'Events, holidays & early-release days',
                    () => _launch(school.calendarUrl!)),
              if (school.website != null)
                _linkButton(
                    cs,
                    Icons.open_in_new,
                    'School Website',
                    'Official school / district site',
                    () => _launch(school.website!)),
              if (school.phone != null)
                _linkButton(
                    cs,
                    Icons.phone_outlined,
                    'Call the School',
                    school.phone!,
                    () => _launch(
                        'tel:${school.phone!.replaceAll(RegExp(r'[^0-9+]'), '')}')),
              if (school.address != null)
                _linkButton(
                    cs,
                    Icons.location_on_outlined,
                    'Directions',
                    school.address!,
                    () => _launch(
                        'https://maps.google.com/?q=${Uri.encodeComponent(school.address!)}')),

              // Information
              if (school.address != null || school.phone != null) ...[
                const SizedBox(height: 12),
                _sectionHeader(cs, 'Information'),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: cs.outline.withValues(alpha: 0.4)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (school.address != null)
                        _infoRow(
                            cs, Icons.location_on_outlined, school.address!),
                      if (school.phone != null)
                        _infoRow(cs, Icons.phone_outlined, school.phone!),
                      if (school.website != null)
                        _infoRow(cs, Icons.open_in_new, school.website!),
                    ],
                  ),
                ),
              ],

              // School news
              const SizedBox(height: 12),
              _sectionHeader(cs, 'School News'),
              const SizedBox(height: 8),
              if (schoolNews.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No school news yet.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant)),
                )
              else
                for (final n in schoolNews.take(5))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      tileColor: cs.surface,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 4),
                      leading: Icon(Icons.article_outlined, color: cs.primary),
                      title: Text(n.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(
                              title: n.title,
                              itemType: 'news',
                              content: n.content,
                              itemId: n.id,
                              metadata: {
                                if (n.sourceUrl != null)
                                  'source_url': n.sourceUrl!,
                                if (n.imageUrl != null)
                                  'image_url': n.imageUrl!,
                              },
                            ),
                          )),
                    ),
                  ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(ColorScheme cs, String title) => Text(title,
      style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
          letterSpacing: 0.3));

  Widget _linkButton(ColorScheme cs, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(icon, color: cs.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle,
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(ColorScheme cs, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              size: 16, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
              child: Text(text,
                  style: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant, height: 1.3))),
        ],
      ),
    );
  }
}
