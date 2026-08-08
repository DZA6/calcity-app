import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/content.dart';
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

/// Drawer categories with emoji-enhanced labels.
class _DrawerEntry {
  final String label;
  final String emoji;
  final String slug;
  final IconData icon;
  final Color color;
  const _DrawerEntry(this.label, this.emoji, this.slug, this.icon, this.color);
}

const _drawerCategories = <_DrawerEntry>[
  _DrawerEntry('City Works', '🏗️', 'city_works', Icons.engineering_outlined, Color(0xFF5F6B41)),
  _DrawerEntry('Church / Faith', '⛪', 'church', Icons.church_outlined, Color(0xFF8B5A3C)),
  _DrawerEntry('Recreation & Parks', '🌳', 'recreation', Icons.park_outlined, Color(0xFF4A7C59)),
  _DrawerEntry('Law Enforcement', '🚔', 'law_enforcement', Icons.local_police_outlined, Color(0xFF3A4B6D)),
  _DrawerEntry('Health & Wellness', '🏥', 'health', Icons.health_and_safety_outlined, Color(0xFF4D8C7A)),
  _DrawerEntry('Schools & Education', '🎓', 'education', Icons.school_outlined, Color(0xFF6B5B95)),
  _DrawerEntry('Business & Economy', '💼', 'business', Icons.store_outlined, Color(0xFFB8573E)),
  _DrawerEntry('Traffic & Roads', '🚧', 'traffic', Icons.traffic_outlined, Color(0xFF8B6B3A)),
  _DrawerEntry('Community Events', '🎉', 'community', Icons.celebration_outlined, Color(0xFF9B5E3A)),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ContentProvider>();
      if (!provider.isInitialized) provider.refreshAll();
    });
  }

  void _push(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  // ---- build ----
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: _appBar(context),
      drawer: _buildDrawer(context),
      body: Consumer<ContentProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.news.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => prov.refreshAll(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
              children: [
                _weatherCard(context, prov),
                const SizedBox(height: 12),
                if (prov.activeAlerts.isNotEmpty) ...[
                  _alertBanner(context, prov.activeAlerts.first),
                  const SizedBox(height: 12),
                ],
                _categoryChipsCompact(context),
                const SizedBox(height: 16),
                _sectionNews(context, prov),
                const SizedBox(height: 20),
                _sectionEvents(context, prov),
                const SizedBox(height: 20),
                _sectionBusinesses(context, prov),
                const SizedBox(height: 20),
                _sectionCouncil(context, prov),
                const SizedBox(height: 32),
                _footer(context),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---- app bar ----
  PreferredSizeWidget _appBar(BuildContext context) => AppBar(
    title: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('🌵 Cal City'),
        SizedBox(width: 6),
        Text('📍', style: TextStyle(fontSize: 18)),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.refresh),
        onPressed: () => context.read<ContentProvider>().refreshAll(),
        tooltip: 'Refresh',
      ),
    ],
  );

  // ---- drawer ----
  Widget _buildDrawer(BuildContext ctx) {
    final theme = Theme.of(ctx);
    return Drawer(
      child: SafeArea(
        child: Column(children: [
          _drawerHeader(theme),
          _drawerWeather(theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                ..._drawerCategories.map((cat) => ListTile(
                  leading: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                  title: Text(cat.label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () {
                    Navigator.pop(ctx);
                    _push(CategoryScreen(category: cat.slug, title: '${cat.emoji} ${cat.label}'));
                  },
                )),
                const Divider(indent: 16, endIndent: 16),
                ListTile(
                  leading: const Text('🏛️', style: TextStyle(fontSize: 20)),
                  title: const Text('City Council', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () { Navigator.pop(ctx); _push(const CouncilScreen()); },
                ),
                ListTile(
                  leading: const Text('🚨', style: TextStyle(fontSize: 20)),
                  title: const Text('Alerts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () { Navigator.pop(ctx); _push(const AlertsScreen()); },
                ),
                ListTile(
                  leading: const Text('💡', style: TextStyle(fontSize: 20)),
                  title: const Text('Submit a Tip', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () { Navigator.pop(ctx); _push(const TipScreen()); },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _drawerHeader(ThemeData theme) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.75)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('🌵', style: TextStyle(fontSize: 28)),
      const SizedBox(height: 8),
      const Text('California City', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text('🏜️ Community Hub', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
    ]),
  );

  Widget _drawerWeather(ThemeData theme) =>
    Consumer<ContentProvider>(builder: (_, prov, __) {
      final w = prov.weather;
      if (w == null) return const SizedBox.shrink();
      return Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(children: [
          Icon(Icons.wb_sunny_outlined, color: Colors.amber.shade700, size: 26),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${w.temperatureHigh ?? '—'}° / ${w.temperatureLow ?? '—'}°',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            Text(w.headline, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
          ]),
        ]),
      );
    });

  // ---- weather card ----
  Widget _weatherCard(BuildContext ctx, ContentProvider prov) {
    final w = prov.weather;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1565C0).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: w == null
        ? const Row(children: [
            Text('☀️', style: TextStyle(fontSize: 36)),
            SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Weather', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
              Text('Update coming soon', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ]),
          ])
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.temperatureHigh != null && w.temperatureHigh! > 90 ? '🥵' : '☀️', style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${w.temperatureHigh ?? '—'}°F / ${w.temperatureLow ?? '—'}°F',
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700, height: 1.1)),
                Text(w.headline, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
              ]),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              if (w.humidity != null && w.humidity!.isNotEmpty)
                _weatherStat('💧', w.humidity!),
              const SizedBox(width: 14),
              if (w.wind != null && w.wind!.isNotEmpty)
                _weatherStat('💨', w.wind!),
              const SizedBox(width: 14),
              if (w.fireRisk != null && w.fireRisk!.isNotEmpty)
                _weatherStat('🔥', w.fireRisk!),
            ]),
          ]),
    );
  }

  Widget _weatherStat(String icon, String val) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(icon, style: const TextStyle(fontSize: 14)),
    const SizedBox(width: 4),
    Text(val, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 12)),
  ]);

  // ---- alert banner ----
  Widget _alertBanner(BuildContext ctx, AlertItem alert) {
    final sev = alert.severity.toLowerCase();
    final color = sev == 'emergency' ? Colors.red.shade800
        : sev == 'warning' ? Colors.orange.shade800
        : Colors.blue.shade800;
    final emoji = sev == 'emergency' ? '🚨' : sev == 'warning' ? '⚠️' : 'ℹ️';
    return GestureDetector(
      onTap: () => _push(const AlertsScreen()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(alert.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14))),
          const Icon(Icons.chevron_right, color: Colors.white, size: 18),
        ]),
      ),
    );
  }

  // ---- category chips (compact, emoji) ----
  Widget _categoryChipsCompact(BuildContext ctx) => Wrap(
    spacing: 6, runSpacing: 6,
    children: _drawerCategories.take(6).map((c) => ActionChip(
      avatar: Text(c.emoji, style: const TextStyle(fontSize: 16)),
      label: Text(c.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Theme.of(ctx).colorScheme.outlineVariant.withValues(alpha: 0.4)),
      onPressed: () => _push(CategoryScreen(category: c.slug, title: '${c.emoji} ${c.label}')),
    )).toList(),
  );

  // ---- section headers (const-able) ----
  Widget _sectionHeader(String emojiLabel, int count, {VoidCallback? onSeeAll}) => Row(children: [
    Text(emojiLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    const SizedBox(width: 6),
    Text('$count', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
    const Spacer(),
    if (onSeeAll != null)
      TextButton(onPressed: onSeeAll, child: const Text('See all →', style: TextStyle(fontWeight: FontWeight.w600))),
  ]);

  // ---- news section ----
  Widget _sectionNews(BuildContext ctx, ContentProvider prov) {
    if (prov.news.isEmpty) return _empty('📰', 'No news yet — check back soon!');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('📰 Latest News', prov.news.length, onSeeAll: () => _push(const NewsScreen())),
      const SizedBox(height: 8),
      SizedBox(
        height: 280,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: prov.news.length.clamp(0, 10),
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => SizedBox(
            width: 250,
            child: NewsCard(item: prov.news[i], onTap: () => _openNews(ctx, prov.news[i])),
          ),
        ),
      ),
    ]);
  }

  // ---- events section ----
  Widget _sectionEvents(BuildContext ctx, ContentProvider prov) {
    if (prov.events.isEmpty) return _empty('📅', 'No upcoming events');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('📅 Upcoming Events', prov.events.length, onSeeAll: () => _push(const EventsScreen())),
      const SizedBox(height: 6),
      ...prov.events.take(3).map((e) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: EventCard(item: e, onTap: () => _openEvent(ctx, e)),
      )),
    ]);
  }

  // ---- businesses section ----
  Widget _sectionBusinesses(BuildContext ctx, ContentProvider prov) {
    if (prov.businesses.isEmpty) return _empty('🏪', 'No businesses yet');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('🏪 Local Businesses', prov.businesses.length, onSeeAll: () => _push(const BusinessesScreen())),
      const SizedBox(height: 6),
      RepaintBoundary(
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82,
          ),
          itemCount: prov.businesses.length.clamp(0, 8),
          itemBuilder: (_, i) => BusinessCard(item: prov.businesses[i], onTap: () => _openBusiness(ctx, prov.businesses[i])),
        ),
      ),
    ]);
  }

  // ---- council section ----
  Widget _sectionCouncil(BuildContext ctx, ContentProvider prov) {
    if (prov.councilAgendas.isEmpty) return _empty('🏛️', 'No council meetings');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('🏛️ City Council', prov.councilAgendas.length, onSeeAll: () => _push(const CouncilScreen())),
      const SizedBox(height: 6),
      ...prov.councilAgendas.take(4).map((a) => _councilRow(ctx, a)),
    ]);
  }

  Widget _councilRow(BuildContext ctx, council) {
    final theme = Theme.of(ctx);
    final date = council.meetingDate != null
        ? DateFormat('MMM d').format(council.meetingDate!)
        : 'TBD';
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: Icon(Icons.calendar_today, color: theme.colorScheme.primary, size: 22),
        title: Text(council.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        trailing: Chip(label: Text(date, style: const TextStyle(fontSize: 10)), visualDensity: VisualDensity.compact),
        onTap: () => _push(DetailScreen(
          title: council.title, itemType: 'council',
          content: council.description ?? '',
          metadata: {'pdf_url': council.pdfUrl ?? '', 'meeting_date': council.meetingDate?.toIso8601String() ?? ''},
        )),
      ),
    );
  }

  Widget _empty(String emoji, String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 32)),
      const SizedBox(height: 6),
      Text(msg, style: TextStyle(color: Theme.of(context).colorScheme.outline, fontSize: 13)),
    ])),
  );

  Widget _footer(BuildContext ctx) => Center(child: Text('📍 California City, CA 93505 🏜️',
    style: TextStyle(fontSize: 11, color: Theme.of(ctx).colorScheme.outline)));

  // ---- navigation helpers ----
  void _openNews(BuildContext ctx, dynamic item) {
    if (item is! NewsItem) return;
    _push(DetailScreen(title: item.title, itemType: 'news', content: item.content, metadata: {
      if (item.imageUrl != null) 'image_url': item.imageUrl!,
      if (item.videoUrl != null) 'video_url': item.videoUrl!,
      if (item.sourceUrl != null) 'source_url': item.sourceUrl!,
    }));
  }

  void _openEvent(BuildContext ctx, EventItem e) =>
    _push(DetailScreen(title: e.title, itemType: 'event', content: e.description ?? '', metadata: {
      if (e.startDate != null) 'start_date': e.startDate!.toIso8601String(),
      if (e.endDate != null) 'end_date': e.endDate!.toIso8601String(),
      if (e.location != null) 'location': e.location!,
      if (e.imageUrl != null) 'image_url': e.imageUrl!,
    }));

  void _openBusiness(BuildContext ctx, BusinessItem b) =>
    _push(DetailScreen(title: b.name, itemType: 'business', content: b.description ?? '', metadata: {
      if (b.category != null) 'category': b.category!,
      if (b.contactPhone != null) 'phone': b.contactPhone!,
      if (b.contactEmail != null) 'email': b.contactEmail!,
      if (b.website != null) 'website': b.website!,
      if (b.address != null) 'address': b.address!,
      if (b.imageUrl != null) 'image_url': b.imageUrl!,
    }));
}
