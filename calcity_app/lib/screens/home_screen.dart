import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_page_route.dart';
import '../models/content.dart';
import '../providers/content_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/event_card.dart';
import '../widgets/business_card.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'schools_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

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
      final prov = context.read<ContentProvider>();
      if (!prov.isInitialized) prov.refreshAll();
    });
  }

  void _push(Widget screen) =>
      Navigator.push(context, AppPageRoute(screen));

  Widget _shimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade900,
      highlightColor: Colors.grey.shade700,
      child: ListView(padding: const EdgeInsets.all(16), children: List.generate(6, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 120, height: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(height: 14, width: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(height: 10, width: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
          ])),
        ]),
      ))),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: _appBar(context, cs),
      drawer: _buildDrawer(context),
      body: Consumer2<ContentProvider, SettingsProvider>(
        builder: (context, prov, settings, _) {
          if (prov.isLoading && prov.news.isEmpty) {
            return _shimmerLoading();
          }
          return RefreshIndicator(
            onRefresh: () => prov.refreshAll(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
              children: _buildFeed(context, prov, settings),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFeed(BuildContext context, ContentProvider prov, SettingsProvider settings) {
    final cs = Theme.of(context).colorScheme;
    final items = <Widget>[];

    // Weather card at top
    if (prov.weather != null) {
      items.add(_weatherBanner(cs, prov.weather!));
      items.add(const SizedBox(height: 10));
    }

    // Active alert banner
    if (settings.showAlerts && prov.activeAlerts.isNotEmpty) {
      items.add(_alertBanner(context, prov.activeAlerts.first));
      items.add(const SizedBox(height: 10));
    }

    // Timeline: merged news + events feed sorted by date
    if (settings.showNews || settings.showEvents) {
      items.add(_sectionHeader(cs, 'Timeline'));
      items.add(const SizedBox(height: 6));

      final timelineItems = <_TimelineEntry>[];

      if (settings.showNews) {
        for (final n in prov.news) {
          timelineItems.add(_TimelineEntry(
            date: n.createdAt,
            type: 'news',
            widget: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NewsCard(
                item: n,
                onTap: () => _openNews(context, n),
              ),
            ),
          ));
        }
      }

      if (settings.showEvents) {
        for (final e in prov.events.take(10)) {
          final date = e.startDate ?? DateTime.now();
          timelineItems.add(_TimelineEntry(
            date: date,
            type: 'event',
            widget: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: EventCard(item: e, onTap: () => _openEvent(context, e)),
            ),
          ));
        }
      }

      // Sort by date, newest first
      timelineItems.sort((a, b) => b.date.compareTo(a.date));

      for (final entry in timelineItems.take(30)) {
        items.add(entry.widget);
      }
    }

    // Businesses section
    if (settings.showBusinesses && prov.businesses.isNotEmpty) {
      items.add(const SizedBox(height: 12));
      items.add(_sectionHeader(cs, 'Local Businesses'));
      items.add(const SizedBox(height: 6));

      items.add(
        RepaintBoundary(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.90,
            ),
            itemCount: prov.businesses.length.clamp(0, 8),
            itemBuilder: (_, i) => BusinessCard(
              item: prov.businesses[i],
              onTap: () => _openBusiness(context, prov.businesses[i]),
            ),
          ),
        ),
      );
    }

    // Schools section
    if (settings.showSchools && prov.schools.isNotEmpty) {
      items.add(const SizedBox(height: 12));
      items.add(Row(
        children: [
          _sectionHeader(cs, 'Schools'),
          const Spacer(),
          TextButton(
            onPressed: () => _push(const SchoolsScreen()),
            child: Text('See all', style: TextStyle(fontSize: 12, color: cs.primary)),
          ),
        ],
      ));
      items.add(const SizedBox(height: 6));
      for (final s in prov.schools.take(3)) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _schoolRow(context, s),
        ));
      }
    }

    // Council section
    if (settings.showCouncil && prov.councilAgendas.isNotEmpty) {
      items.add(const SizedBox(height: 12));
      items.add(_sectionHeader(cs, 'City Council'));
      items.add(const SizedBox(height: 6));
      for (final a in prov.councilAgendas.take(3)) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _councilRow(context, a),
        ));
      }
    }

    // Empty state
    if (items.length <= 2) {
      items.add(const SizedBox(height: 60));
      items.add(Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: cs.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No content to show',
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('Enable sections in Settings',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant.withValues(alpha: 0.3))),
          ],
        ),
      ));
    }

    return items;
  }

  // ---- App Bar ----
  PreferredSizeWidget _appBar(BuildContext context, ColorScheme cs) {
    return AppBar(
      title: Text(
        'CalCity',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: cs.primary,
          letterSpacing: -0.3,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => _push(const SettingsScreen()),
          tooltip: 'Settings',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => context.read<ContentProvider>().refreshAll(),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  // ---- Settings Drawer ----
  Widget _buildDrawer(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              color: cs.surfaceVariant.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.location_city, color: cs.primary, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text('CalCity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text('California City Community',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Dark mode toggle
            SwitchListTile(
              title: const Text('Dark Mode', style: TextStyle(fontSize: 14)),
              secondary: Icon(Icons.dark_mode_outlined, color: cs.primary),
              value: settings.darkMode,
              onChanged: (v) => settings.setDarkMode(v),
            ),

            const Divider(indent: 16, endIndent: 16),

            // Section toggles
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('SECTIONS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary, letterSpacing: 0.5)),
            ),

            _drawerToggle(cs, Icons.article_outlined, 'News', settings.showNews, (v) => settings.setShowNews(v), color: const Color(0xFF00FF41)),
            _drawerToggle(cs, Icons.event_outlined, 'Events', settings.showEvents, (v) => settings.setShowEvents(v), color: const Color(0xFF00E5FF)),
            _drawerToggle(cs, Icons.store_outlined, 'Businesses', settings.showBusinesses, (v) => settings.setShowBusinesses(v), color: const Color(0xFFFFB300)),
            _drawerToggle(cs, Icons.school_outlined, 'Schools', settings.showSchools, (v) => settings.setShowSchools(v), color: const Color(0xFFFF5252)),
            _drawerToggle(cs, Icons.person_outlined, 'Freelancers', settings.showFreelancers, (v) => settings.setShowFreelancers(v), color: const Color(0xFFE040FB)),
            _drawerToggle(cs, Icons.campaign_outlined, 'Alerts', settings.showAlerts, (v) => settings.setShowAlerts(v), color: const Color(0xFFFF6D00)),
            _drawerToggle(cs, Icons.account_balance_outlined, 'City Council', settings.showCouncil, (v) => settings.setShowCouncil(v), color: const Color(0xFF76FF03)),

            // Sign In / Sign Up / Profile
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.isLoggedIn) {
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primaryContainer,
                      child: Text(
                        (auth.username ?? 'U')[0].toUpperCase(),
                        style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    title: Text(auth.username ?? 'User', style: const TextStyle(fontSize: 14)),
                    subtitle: Text(auth.email ?? '', style: const TextStyle(fontSize: 12)),
                    trailing: TextButton(
                      onPressed: () { auth.logout(); },
                      child: const Text('Sign Out'),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())); },
                          child: const Text('Sign Up'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())); },
                          child: const Text('Sign In'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Divider(indent: 16, endIndent: 16),

            // Full settings
            ListTile(
              leading: Icon(Icons.settings_outlined, color: cs.primary),
              title: const Text('All Settings', style: TextStyle(fontSize: 14)),
              onTap: () {
                Navigator.pop(context);
                _push(const SettingsScreen());
              },
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Text(
                'California City, CA 93505',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerToggle(ColorScheme cs, IconData icon, String label, bool value, ValueChanged<bool> onChanged, {Color? color}) {
    final iconColor = color ?? cs.primary;
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      secondary: Icon(icon, size: 20, color: value ? iconColor : cs.onSurfaceVariant.withValues(alpha: 0.5)),
      value: value,
      onChanged: onChanged,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  // ---- Section header ----
  Widget _sectionHeader(ColorScheme cs, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.3,
      ),
    );
  }

  // ---- Weather banner ----
  Color _fireRiskColor(String risk) {
    final r = risk.toLowerCase();
    if (r.contains('extreme') || r.contains('critical')) return const Color(0xFFFF1744);
    if (r.contains('high') || r.contains('very')) return const Color(0xFFFF9100);
    if (r.contains('moderate')) return const Color(0xFFFFD600);
    return const Color(0xFF00E676);
  }

  Widget _weatherBanner(ColorScheme cs, WeatherInfo w) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.wb_sunny_outlined, size: 28, color: cs.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(w.headline,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface))),
                  if (w.fireRisk != null && w.fireRisk!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _fireRiskColor(w.fireRisk!).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(w.fireRisk!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _fireRiskColor(w.fireRisk!))),
                    ),
                ]),
                if (w.detail != null && w.detail!.isNotEmpty)
                  ...[
                    const SizedBox(height: 3),
                    Text(w.detail!, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                const SizedBox(height: 4),
                Row(children: [
                  if (w.humidity != null && w.humidity!.isNotEmpty) ...[
                    Icon(Icons.water_drop_outlined, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(w.humidity!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                    const SizedBox(width: 10),
                  ],
                  if (w.wind != null && w.wind!.isNotEmpty) ...[
                    Icon(Icons.air, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 2),
                    Text(w.wind!, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ]),
              ],
            ),
          ),
          if (w.temperatureHigh != null)
            Text('${w.temperatureHigh}F',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: cs.primary)),
        ],
      ),
    );
  }

  // ---- Alert banner ----
  Widget _alertBanner(BuildContext context, AlertItem alert) {
    final sev = alert.severity.toLowerCase();
    final color = sev == 'emergency'
        ? Colors.red.shade700
        : sev == 'warning'
            ? Colors.amber.shade700
            : Colors.blue.shade700;
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              sev == 'emergency' ? Icons.error : sev == 'warning' ? Icons.warning_amber : Icons.info_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(alert.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ),
            Icon(Icons.chevron_right, color: color.withValues(alpha: 0.5), size: 18),
          ],
        ),
      ),
    );
  }

  // ---- School row ----
  Widget _schoolRow(BuildContext context, SchoolItem s) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.school_outlined, color: cs.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cs.onSurface)),
                  if (s.type != null)
                    Text(s.type!,
                      style: TextStyle(fontSize: 12, color: cs.primary)),
                  if (s.address != null)
                    Text(s.address!,
                      style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Council row ----
  Widget _councilRow(BuildContext context, CouncilAgendaItem a) {
    final cs = Theme.of(context).colorScheme;
    final date = a.meetingDate != null
        ? DateFormat('MMM d, yyyy').format(a.meetingDate!)
        : 'TBD';
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(a.title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: cs.onSurface),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(date,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Nav helpers ----
  void _openNews(BuildContext ctx, NewsItem item) {
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

/// Timeline entry for sorting news + events
class _TimelineEntry {
  final DateTime date;
  final String type;
  final Widget widget;
  const _TimelineEntry({required this.date, required this.type, required this.widget});
}
