import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/content_provider.dart';
import '../models/content.dart';

class CouncilScreen extends StatefulWidget {
  const CouncilScreen({super.key});

  @override
  State<CouncilScreen> createState() => _CouncilScreenState();
}

class _CouncilScreenState extends State<CouncilScreen> {
  int? _selectedYear; // null = all years

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().fetchCouncilAgendas();
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// The council "agenda" field is populated by the Granicus scraper with a
  /// video player URL (not a PDF). Detect video/media URLs so we can label
  /// the action correctly.
  bool _isVideoUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('granicus.com') ||
        u.contains('mediaplayer') ||
        u.contains('youtube.com') ||
        u.contains('youtu.be') ||
        u.contains('vimeo.com') ||
        u.endsWith('.mp4') ||
        u.endsWith('.m3u8');
  }

  Widget _yearFilter(BuildContext context, ThemeData theme, List<int> years) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _yearChip(theme, null, 'All'),
            for (final y in years) _yearChip(theme, y, '$y'),
          ],
        ),
      ),
    );
  }

  Widget _yearChip(ThemeData theme, int? year, String label) {
    final selected = _selectedYear == year;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _selectedYear = year),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('City Council'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoadingCouncil && provider.councilAgendas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.councilAgendas.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => provider.fetchCouncilAgendas(),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.groups_outlined,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No upcoming council meetings posted',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Check back later for meeting agendas',
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          // Sort by meeting date (closest first), items without dates at end
          final sorted = List<CouncilAgendaItem>.from(provider.councilAgendas)
            ..sort((a, b) {
              if (a.meetingDate == null && b.meetingDate == null) return 0;
              if (a.meetingDate == null) return 1;
              if (b.meetingDate == null) return -1;
              return a.meetingDate!.compareTo(b.meetingDate!);
            });

          // Distinct years for the filter (newest first)
          final years = sorted
              .where((a) => a.meetingDate != null)
              .map((a) => a.meetingDate!.year)
              .toSet()
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final filtered = _selectedYear == null
              ? sorted
              : sorted
                  .where((a) => a.meetingDate?.year == _selectedYear)
                  .toList();

          return RefreshIndicator(
            onRefresh: () => provider.fetchCouncilAgendas(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filtered.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _yearFilter(context, theme, years);
                }
                final item = filtered[index - 1];
                final dateStr = item.meetingDate != null
                    ? DateFormat('EEEE, MMMM d, yyyy').format(item.meetingDate!)
                    : 'Date TBD';
                final timeStr = item.meetingDate != null
                    ? DateFormat('h:mm a').format(item.meetingDate!)
                    : null;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Meeting date badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  dateStr,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                if (timeStr != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    'at $timeStr',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Description snippet
                          if (item.description != null &&
                              item.description!.isNotEmpty)
                            Text(
                              item.description!.length > 200
                                  ? '${item.description!.substring(0, 200)}...'
                                  : item.description!,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 12),

                          // View Agenda button
                          if (item.pdfUrl != null && item.pdfUrl!.isNotEmpty)
                            Align(
                              alignment: Alignment.centerLeft,
                              child: OutlinedButton.icon(
                                onPressed: () => _launchUrl(item.pdfUrl!),
                                icon: Icon(
                                  _isVideoUrl(item.pdfUrl!)
                                      ? Icons.play_circle_outline
                                      : Icons.picture_as_pdf,
                                  size: 18,
                                ),
                                label: Text(
                                  _isVideoUrl(item.pdfUrl!)
                                      ? 'Watch Meeting'
                                      : 'View Agenda',
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.primary,
                                  side: BorderSide(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.4),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
}
