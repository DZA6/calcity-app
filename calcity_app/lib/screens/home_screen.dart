import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/content_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/event_card.dart';
import '../widgets/business_card.dart';
import 'news_screen.dart';
import 'events_screen.dart';
import 'businesses_screen.dart';
import 'tip_screen.dart';
import 'alerts_screen.dart';
import 'council_screen.dart';
import 'category_screen.dart';
import 'detail_screen.dart';

/// Category definitions for the hamburger drawer.
const _drawerCategories = <_DrawerEntry>[
  _DrawerEntry('City Works', 'city_works', Icons.engineering_outlined, Color(0xFF5F6B41)),
  _DrawerEntry('Church / Faith', 'church', Icons.church_outlined, Color(0xFF8B5A3C)),
  _DrawerEntry('Recreation & Parks', 'recreation', Icons.park_outlined, Color(0xFF4A7C59)),
  _DrawerEntry('Law Enforcement', 'law_enforcement', Icons.local_police_outlined, Color(0xFF3A4B6D)),
  _DrawerEntry('Health & Wellness', 'health', Icons.health_and_safety_outlined, Color(0xFF4D8C7A)),
  _DrawerEntry('Schools & Education', 'education', Icons.school_outlined, Color(0xFF6B5B95)),
  _DrawerEntry('Business & Economy', 'business', Icons.store_outlined, Color(0xFFB8573E)),
  _DrawerEntry('Traffic & Roads', 'traffic', Icons.traffic_outlined, Color(0xFF8B6B3A)),
  _DrawerEntry('Community Events', 'community', Icons.celebration_outlined, Color(0xFF9B5E3A)),
];

class _DrawerEntry {
  final String label;
  final String slug;
  final IconData icon;
  final Color color;
  const _DrawerEntry(this.label, this.slug, this.icon, this.color);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContentProvider>().refreshAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cal City'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<ContentProvider>().refreshAll(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Consumer<ContentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.news.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.refreshAll(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // Weather card
                _buildWeatherCard(context, provider),
                const SizedBox(height: 16),
                // Alert banners
                if (provider.activeAlerts.isNotEmpty) ...[
                  _buildAlertBanner(context, provider),
                  const SizedBox(height: 16),
                ],
                // Quick category chips
                _buildCategoryChips(context),
                const SizedBox(height: 20),
                // Featured News
                _buildSectionHeader(context, 'Latest News', Icons.article_outlined,
                    provider.news.length,
                    onSeeAll: () => _push(context, const NewsScreen())),
                const SizedBox(height: 10),
                if (provider.news.isNotEmpty)
                  SizedBox(
                    height: 290,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: provider.news.length.clamp(0, 10),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) => SizedBox(
                        width: 260,
                        child: NewsCard(
                          item: provider.news[i],
                          onTap: () => _openDetail(context, provider.news[i]),
                        ),
                      ),
                    ),
                  )
                else
                  _emptyState(Icons.article_outlined, 'No news yet'),
                const SizedBox(height: 24),
                // Events
                _buildSectionHeader(context, 'Upcoming Events', Icons.event_outlined,
                    provider.events.length,
                    onSeeAll: () => _push(context, const EventsScreen())),
                const SizedBox(height: 10),
                ...provider.events.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: EventCard(
                        item: e,
                        onTap: () => _openEventDetail(context, e),
                      ),
                    )),
                if (provider.events.isEmpty) _emptyState(Icons.event_outlined, 'No events yet'),
                const SizedBox(height: 24),
                // Businesses
                _buildSectionHeader(context, 'Local Businesses', Icons.store_outlined,
                    provider.featuredBusinesses.length,
                    onSeeAll: () => _push(context, const BusinessesScreen())),
                const SizedBox(height: 10),
                if (provider.featuredBusinesses.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: provider.featuredBusinesses.length,
                    itemBuilder: (_, i) => BusinessCard(
                      item: provider.featuredBusinesses[i],
                      onTap: () => _openBusinessDetail(context, provider.featuredBusinesses[i]),
                    ),
                  )
                else
                  _emptyState(Icons.store_outlined, 'No businesses yet'),
                const SizedBox(height: 24),
                // Council
                _buildSectionHeader(context, 'City Council', Icons.groups_outlined,
                    provider.councilAgendas.length,
                    onSeeAll: () => _push(context, const CouncilScreen())),
                if (provider.councilAgendas.isNotEmpty)
                  ...provider.councilAgendas.take(4).map((a) => _councilTile(context, a)),
                // Footer
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    'California City, CA',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  void _openDetail(BuildContext context, dynamic item) {
    if (item is! NewsItem) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(
      title: item.title,
      itemType: 'news',
      content: item.content,
      metadata: {
        'date': item.createdAt.toIso8601String(),
        if (item.sourceUrl != null) 'source_url': item.sourceUrl!,
        if (item.imageUrl != null) 'image_url': item.imageUrl!,
        if (item.videoUrl != null) 'video_url': item.videoUrl!,
      },
    )));
  }

  void _openEventDetail(BuildContext context, EventItem e) =>
      _push(context, DetailScreen(title: e.title, itemType: 'event',
          content: e.description ?? '', metadata: {
        if (e.startDate != null) 'start_date': e.startDate!.toIso8601String(),
        if (e.endDate != null) 'end_date': e.endDate!.toIso8601String(),
        if (e.location != null) 'location': e.location!,
        if (e.imageUrl != null) 'image_url': e.imageUrl!,
      }));

  void _openBusinessDetail(BuildContext context, BusinessItem b) =>
      _push(context, DetailScreen(title: b.name, itemType: 'business',
          content: b.description ?? '', metadata: {
        if (b.category != null) 'category': b.category!,
        if (b.imageUrl != null) 'image_url': b.imageUrl!,
        if (b.contactPhone != null) 'phone': b.contactPhone!,
        if (b.contactEmail != null) 'email': b.contactEmail!,
        if (b.website != null) 'website': b.website!,
      }));

  // ---- Drawer ----
  Widget _buildDrawer(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.75)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.location_city, color: Colors.white.withValues(alpha: 0.9), size: 32),
                  const SizedBox(height: 12),
                  const Text('California City',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Community Hub',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                ],
              ),
            ),
            // Weather summary in drawer
            Consumer<ContentProvider>(
              builder: (context, provider, _) {
                final w = provider.weather;
                if (w == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, color: Colors.amber.shade700, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${w.temperatureHigh ?? '—'}°F / ${w.temperatureLow ?? '—'}°F',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                            Text(w.headline, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // Category menu items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  ..._drawerCategories.map((cat) => ListTile(
                    leading: Icon(cat.icon, color: cat.color, size: 22),
                    title: Text(cat.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    trailing: const Icon(Icons.chevron_right, size: 18),
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      _push(context, CategoryScreen(category: cat.slug, title: cat.label));
                    },
                  )),
                  const Divider(indent: 16, endIndent: 16),
                  ListTile(
                    leading: Icon(Icons.groups_outlined, color: theme.colorScheme.primary, size: 22),
                    title: const Text('City Council', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    onTap: () { Navigator.pop(context); _push(context, const CouncilScreen()); },
                  ),
                  ListTile(
                    leading: Icon(Icons.campaign_outlined, color: Colors.red.shade600, size: 22),
                    title: const Text('Alerts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    onTap: () { Navigator.pop(context); _push(context, const AlertsScreen()); },
                  ),
                  ListTile(
                    leading: Icon(Icons.edit_note_outlined, color: theme.colorScheme.primary, size: 22),
                    title: const Text('Submit a Tip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    onTap: () { Navigator.pop(context); _push(context, const TipScreen()); },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Home screen widgets ----

  Widget _buildWeatherCard(BuildContext context, ContentProvider provider) {
    final theme = Theme.of(context);
    final w = provider.weather;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [const Color(0xFF1565C0), const Color(0xFF1565C0).withValues(alpha: 0.8)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: w == null
          ? _weatherPlaceholder()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.amber.shade300, size: 40),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${w.temperatureHigh ?? '—'}°F / ${w.temperatureLow ?? '—'}°F',
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700, height: 1.1)),
                        Text(w.headline, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _weatherStat(Icons.water_drop_outlined, w.humidity ?? ''),
                    const SizedBox(width: 16),
                    _weatherStat(Icons.air, w.wind ?? ''),
                    const SizedBox(width: 16),
                    if (w.fireRisk != null && w.fireRisk!.isNotEmpty)
                      _weatherStat(Icons.local_fire_department_outlined, w.fireRisk!),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _weatherPlaceholder() {
    return const Row(
      children: [
        Icon(Icons.wb_sunny, color: Colors.white54, size: 40),
        SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weather', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w600)),
            Text('Update coming soon', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _weatherStat(IconData icon, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 14),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      ],
    );
  }

  Widget _buildAlertBanner(BuildContext context, ContentProvider provider) {
    final topAlert = provider.activeAlerts.first;
    final severity = topAlert.severity.toLowerCase();
    final color = severity == 'emergency' ? Colors.red.shade800
        : severity == 'warning' ? Colors.amber.shade800
        : Colors.blue.shade800;

    return GestureDetector(
      onTap: () => _push(context, const AlertsScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(Icons.campaign, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(topAlert.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, color: Colors.white, size: 18),
        ]),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context) {
    final theme = Theme.of(context);
    final cats = _drawerCategories.take(6).toList();
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: cats
          .map((c) => ActionChip(
                avatar: Icon(c.icon, color: c.color, size: 16),
                label: Text(c.label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface)),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                onPressed: () => _push(context, CategoryScreen(category: c.slug, title: c.label)),
              ))
          .toList(),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, int count, {VoidCallback? onSeeAll}) {
    return Row(children: [
      Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(width: 8),
      Text('($count)', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.outline)),
      const Spacer(),
      if (onSeeAll != null)
        TextButton(onPressed: onSeeAll, child: const Text('See all', style: TextStyle(fontWeight: FontWeight.w600))),
    ]);
  }

  Widget _emptyState(IconData icon, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(children: [
          Icon(icon, color: Theme.of(context).colorScheme.outline, size: 36),
          const SizedBox(height: 8),
          Text(msg, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ]),
      ),
    );
  }

  Widget _councilTile(BuildContext context, council) {
    final theme = Theme.of(context);
    String date = 'TBD';
    if (council.meetingDate != null) date = DateFormat('MMM d').format(council.meetingDate!);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
        title: Text(council.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14)),
        trailing: Chip(label: Text(date, style: const TextStyle(fontSize: 11)), visualDensity: VisualDensity.compact),
        onTap: () {
          _push(context, DetailScreen(
            title: council.title, itemType: 'council',
            content: council.description ?? '',
            metadata: {'pdf_url': council.pdfUrl ?? '', 'meeting_date': council.meetingDate?.toIso8601String() ?? ''},
          ));
        },
      ),
    );
  }
}
