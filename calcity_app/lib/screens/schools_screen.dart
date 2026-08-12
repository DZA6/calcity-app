import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/content.dart';
import '../providers/content_provider.dart';
import 'school_detail_screen.dart';

class SchoolsScreen extends StatefulWidget {
  const SchoolsScreen({super.key});
  @override
  State<SchoolsScreen> createState() => _SchoolsScreenState();
}

class _SchoolsScreenState extends State<SchoolsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ContentProvider>();
      if (prov.schools.isEmpty) prov.refreshAll();
    });
  }

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
      case 'college':
      case 'university':
        return Icons.account_balance;
      case 'charter':
        return Icons.stars;
      default:
        return Icons.school_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Schools')),
      body: Consumer<ContentProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.schools.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.schools.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, size: 48, color: cs.outline),
                  const SizedBox(height: 12),
                  Text('No schools listed yet',
                      style:
                          TextStyle(fontSize: 15, color: cs.onSurfaceVariant)),
                ],
              ),
            );
          }

          final schools = List<SchoolItem>.from(prov.schools)
            ..sort((a, b) => a.name.compareTo(b.name));

          return RefreshIndicator(
            onRefresh: () => prov.refreshAll(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: schools.length + 1,
              itemBuilder: (_, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      height: 110,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Image.asset(
                        'assets/images/banner_events.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                final s = schools[i - 1];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SchoolDetailScreen(school: s)),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: cs.outline.withValues(alpha: 0.4)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: cs.primary.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_typeIcon(s.type),
                                      color: cs.primary, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(s.name,
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: cs.onSurface)),
                                      if (s.type != null)
                                        Text(s.type!,
                                            style: TextStyle(
                                                fontSize: 13,
                                                color: cs.primary,
                                                fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (s.description != null &&
                                s.description!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                s.description!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant,
                                    height: 1.3),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            if (s.address != null ||
                                s.phone != null ||
                                s.website != null ||
                                s.calendarUrl != null ||
                                s.bellScheduleUrl != null) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (s.address != null)
                                    _infoChip(cs, Icons.location_on_outlined,
                                        s.address!),
                                  if (s.phone != null)
                                    _infoChip(
                                        cs, Icons.phone_outlined, s.phone!),
                                  if (s.website != null)
                                    GestureDetector(
                                      onTap: () => _launch(s.website!),
                                      child: _infoChip(
                                          cs, Icons.open_in_new, 'Website'),
                                    ),
                                  if (s.calendarUrl != null)
                                    GestureDetector(
                                      onTap: () => _launch(s.calendarUrl!),
                                      child: _infoChip(
                                          cs,
                                          Icons.calendar_month_outlined,
                                          'Calendar'),
                                    ),
                                  if (s.bellScheduleUrl != null)
                                    GestureDetector(
                                      onTap: () => _launch(s.bellScheduleUrl!),
                                      child: _infoChip(
                                          cs,
                                          Icons.schedule_outlined,
                                          'Bell Schedule'),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _infoChip(ColorScheme cs, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 12, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
                fontSize: 11,
                color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
