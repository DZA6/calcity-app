import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../app_page_route.dart';
import '../models/content.dart';
import '../providers/content_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../services/weather_service.dart';
import '../services/api_service.dart';
import '../models/social.dart';
import '../widgets/news_card.dart';
import '../widgets/event_card.dart';
import '../widgets/business_card.dart';
import 'detail_screen.dart';
import 'settings_screen.dart';
import 'schools_screen.dart';
import 'login_screen.dart';
import 'news_screen.dart';
import 'signup_screen.dart';
import 'businesses_screen.dart';
import 'tip_screen.dart';
import 'deals_screen.dart';
import 'council_screen.dart';
import 'freelancers_screen.dart';
import 'category_screen.dart';
import 'conversations_screen.dart';
import 'topic_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  LiveWeather? _liveWeather;
  Timer? _weatherTimer;
  List<DiscussionTopicItem> _dailyTopics = const [];

  @override
  void initState() {
    super.initState();
    _loadWeather();
    _loadTopics();
    // Refresh live weather every 20 min so the card changes through the day
    // (topics ride the same tick so an always-open app still gets the fresh
    // morning question without a manual refresh).
    _weatherTimer = Timer.periodic(const Duration(minutes: 20), (_) {
      _loadWeather();
      _loadTopics();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<ContentProvider>();
      if (!prov.isInitialized) prov.refreshAll();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWeather() async {
    final w = await WeatherService.fetch();
    if (mounted && w != null) setState(() => _liveWeather = w);
  }

  /// Today's discussion topics for the home section (pinned first, capped at 3).
  Future<void> _loadTopics() async {
    final topics = await ApiService().fetchTopics();
    if (mounted && topics.isNotEmpty) {
      setState(() => _dailyTopics = topics.take(3).toList());
    }
  }

  void _push(Widget screen) => Navigator.push(context, AppPageRoute(screen));

  Future<void> _showPostDialog(BuildContext context) async {
    final api = ApiService();
    final category = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Post to the community'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'for_sale'),
            child: const ListTile(
              leading: Icon(Icons.sell_outlined),
              title: Text('For Sale & Free'),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, 'announcements'),
            child: const ListTile(
              leading: Icon(Icons.campaign_outlined),
              title: Text('Announcement'),
            ),
          ),
        ],
      ),
    );
    if (category == null || !mounted) return;

    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(category == 'for_sale'
            ? 'Post a For Sale / Free item'
            : 'Post an announcement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Submit')),
        ],
      ),
    );

    if (ok == true) {
      final title = titleController.text.trim();
      final body = bodyController.text.trim();
      if (title.isEmpty || body.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Title and description are required.')));
        }
        return;
      }
      final id = await api.postClassified(
          title: title, content: body, category: category);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(id != null
                ? 'Submitted! It will appear after staff approval.'
                : 'Could not submit. Try again.')));
      }
    }
  }

  Widget _shimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade900,
      highlightColor: Colors.grey.shade700,
      child: ListView(
          padding: const EdgeInsets.all(16),
          children: List.generate(
              6,
              (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 120,
                              height: 80,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12))),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(4))),
                                const SizedBox(height: 8),
                                Container(
                                    height: 14,
                                    width: 200,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(4))),
                                const SizedBox(height: 8),
                                Container(
                                    height: 10,
                                    width: 100,
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(4))),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPostDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Post'),
      ),
      body: Consumer2<ContentProvider, SettingsProvider>(
        builder: (context, prov, settings, _) {
          if (prov.isLoading && prov.news.isEmpty) {
            return _shimmerLoading();
          }
          return RefreshIndicator(
            onRefresh: () async {
              await Future.wait(
                  [prov.refreshAll(), _loadWeather(), _loadTopics()]);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 40),
              children: _buildFeed(context, prov, settings),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildFeed(
      BuildContext context, ContentProvider prov, SettingsProvider settings) {
    final cs = Theme.of(context).colorScheme;
    final items = <Widget>[];

    // Live weather hero at the top
    items.add(_weatherHero(context, cs, _liveWeather, prov.weather));
    items.add(const SizedBox(height: 12));

    // Quick actions row
    items.add(_quickActions(context, cs));
    items.add(const SizedBox(height: 12));

    // Today's discussion (daily Seddit topics — fresh every morning)
    if (_dailyTopics.isNotEmpty) {
      items.add(_dailyDiscussionSection(context, cs));
      items.add(const SizedBox(height: 12));
    }

    // Active alert banner
    if (settings.showAlerts && prov.activeAlerts.isNotEmpty) {
      items.add(_alertBanner(context, prov.activeAlerts.first));
      items.add(const SizedBox(height: 10));
    }

    // Featured Businesses section (paid placements, or invite when empty)
    if (settings.showBusinesses) {
      items.add(_featuredSection(context, prov));
      items.add(const SizedBox(height: 10));
    }

    // Timeline: merged news + events feed sorted by date (5 items)
    if (settings.showNews || settings.showEvents) {
      items.add(Row(
        children: [
          _sectionHeader(cs, 'LATEST'),
          const Spacer(),
          TextButton(
            onPressed: () => _push(const NewsScreen()),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            child: const Text('See all'),
          ),
        ],
      ));
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

      for (final entry in timelineItems.take(5)) {
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
            child: Text('See all',
                style: TextStyle(fontSize: 12, color: cs.primary)),
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
            Icon(Icons.inbox_outlined,
                size: 48, color: cs.outline.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No content to show',
                style: TextStyle(
                    fontSize: 15,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5))),
            const SizedBox(height: 4),
            Text('Enable sections in Settings',
                style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.3))),
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        Icon(Icons.location_city, color: cs.primary, size: 24),
                  ),
                  const SizedBox(height: 14),
                  Text('CalCity',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text('California City Community',
                      style:
                          TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
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
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                      letterSpacing: 0.5)),
            ),

            _drawerToggle(cs, Icons.article_outlined, 'News', settings.showNews,
                (v) => settings.setShowNews(v),
                color: const Color(0xFF2E7D32)),
            _drawerToggle(cs, Icons.event_outlined, 'Events',
                settings.showEvents, (v) => settings.setShowEvents(v),
                color: const Color(0xFF00E5FF)),
            _drawerToggle(cs, Icons.store_outlined, 'Businesses',
                settings.showBusinesses, (v) => settings.setShowBusinesses(v),
                color: const Color(0xFFFFB300)),
            _drawerToggle(cs, Icons.school_outlined, 'Schools',
                settings.showSchools, (v) => settings.setShowSchools(v),
                color: const Color(0xFFFF5252)),
            _drawerToggle(cs, Icons.person_outlined, 'Freelancers',
                settings.showFreelancers, (v) => settings.setShowFreelancers(v),
                color: const Color(0xFFE040FB)),
            _drawerToggle(cs, Icons.campaign_outlined, 'Alerts',
                settings.showAlerts, (v) => settings.setShowAlerts(v),
                color: const Color(0xFFFF6D00)),
            _drawerToggle(cs, Icons.account_balance_outlined, 'City Council',
                settings.showCouncil, (v) => settings.setShowCouncil(v),
                color: const Color(0xFF5F6B41)),

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
                        style: TextStyle(
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                    title: Text(auth.username ?? 'User',
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text(auth.email ?? '',
                        style: const TextStyle(fontSize: 12)),
                    trailing: TextButton(
                      onPressed: () {
                        auth.logout();
                      },
                      child: const Text('Sign Out'),
                    ),
                  );
                }
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignupScreen()));
                          },
                          child: const Text('Sign Up'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()));
                          },
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
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerToggle(ColorScheme cs, IconData icon, String label, bool value,
      ValueChanged<bool> onChanged,
      {Color? color}) {
    final iconColor = color ?? cs.primary;
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      secondary: Icon(icon,
          size: 20,
          color:
              value ? iconColor : cs.onSurfaceVariant.withValues(alpha: 0.5)),
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

  // ---- Live weather hero (falls back to the static image hero offline) ----
  Widget _weatherHero(BuildContext context, ColorScheme cs, LiveWeather? w,
      WeatherInfo? advisory) {
    if (w == null) return _staticHero(context);

    final gradient = _skyGradient(w);
    final hours = w.nextHours(6);

    return Container(
      height: 232,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Decorative big condition icon, low opacity
          Positioned(
            right: -18,
            top: -22,
            child: Icon(w.icon,
                size: 150, color: Colors.white.withValues(alpha: 0.14)),
          ),
          // Text layer — always readable on the gradient
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Location + date row
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded,
                        size: 15, color: Colors.white70),
                    const SizedBox(width: 3),
                    Text('California City',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95))),
                    const Spacer(),
                    Text(DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85))),
                    if (advisory != null &&
                        advisory.fireRisk != null &&
                        advisory.fireRisk!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _fireRiskColor(advisory.fireRisk!)
                              .withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Text('🔥 ${advisory.fireRisk!}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                // Big temp + condition
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${w.temp}°',
                        style: const TextStyle(
                            fontSize: 62,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 0.95,
                            letterSpacing: -2)),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(w.condition,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          Text('Feels like ${w.feelsLike}°',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('H ${w.highToday}°  L ${w.lowToday}°',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.95))),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.water_drop_rounded,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 2),
                              Text('${w.humidity}%',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white
                                          .withValues(alpha: 0.85))),
                              const SizedBox(width: 8),
                              const Icon(Icons.air_rounded,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 2),
                              Text('${w.windMph.round()} mph',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white
                                          .withValues(alpha: 0.85))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Hourly strip
                SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      for (final h in hours) ...[
                        if (h != hours.first) const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_hourLabel(h.time),
                                    style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white
                                            .withValues(alpha: 0.9))),
                                Icon(_wmoIcon(h.code, w.isDay),
                                    size: 14, color: Colors.white),
                                Text('${h.temp}°',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _hourLabel(DateTime t) {
    if (t.hour == DateTime.now().hour) return 'Now';
    var h = t.hour % 12;
    if (h == 0) h = 12;
    return '$h${t.hour >= 12 ? 'p' : 'a'}';
  }

  static IconData _wmoIcon(int code, bool isDay) =>
      LiveWeather.wmoIcon(code, isDay);

  // Sky gradient that changes with condition + time of day + desert heat.
  LinearGradient _skyGradient(LiveWeather w) {
    final colors = <Color>[
      if (!w.isDay) ...[
        const Color(0xFF14103A),
        const Color(0xFF2B1F5E),
        const Color(0xFF45308A),
      ] else if (w.temp >= 95) ...[
        const Color(0xFFE2711D),
        const Color(0xFFF59B3C),
        const Color(0xFFF9C15C),
      ] else if (w.conditionCode == 0 || w.conditionCode == 1) ...[
        const Color(0xFF1E88E5),
        const Color(0xFF42A5F5),
        const Color(0xFF7EC8F7),
      ] else if (w.conditionCode == 2) ...[
        const Color(0xFF5C8FC4),
        const Color(0xFF8FB5D9),
        const Color(0xFFBBD4E8),
      ] else if (w.conditionCode >= 61 && w.conditionCode <= 67 ||
          w.conditionCode >= 80 && w.conditionCode <= 82 ||
          w.conditionCode >= 95) ...[
        const Color(0xFF37474F),
        const Color(0xFF546E7A),
        const Color(0xFF78909C),
      ] else ...[
        const Color(0xFF607D8B),
        const Color(0xFF90A4AE),
        const Color(0xFFB0BEC5),
      ],
    ];
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  // ---- Static image hero (offline / first frame fallback) ----
  Widget _staticHero(BuildContext context) {
    return Container(
      height: 172,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/hero_desert.png',
            fit: BoxFit.cover,
          ),
          // Scrim so the text reads on any theme
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'California City',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your community, connected',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Quick actions row ----
  Widget _quickActions(BuildContext context, ColorScheme cs) {
    final actions = <(IconData, String, Color, VoidCallback)>[
      (
        Icons.local_offer_rounded,
        'Deals',
        const Color(0xFFFF7043),
        () => _push(const DealsScreen())
      ),
      (
        Icons.pets_rounded,
        'Lost Pets',
        const Color(0xFFAB47BC),
        () => _push(CategoryScreen(category: 'lost_pets', title: 'Lost Pets'))
      ),
      (
        Icons.handyman_rounded,
        'Gigs',
        const Color(0xFF42A5F5),
        () => _push(CategoryScreen(category: 'gigs', title: 'Gigs & Services'))
      ),
      (
        Icons.account_balance_rounded,
        'Council',
        const Color(0xFF66BB6A),
        () => _push(const CouncilScreen())
      ),
      (
        Icons.school_rounded,
        'Schools',
        const Color(0xFFEC407A),
        () => _push(const SchoolsScreen())
      ),
      (
        Icons.work_rounded,
        'Freelancers',
        const Color(0xFFFFA726),
        () => _push(const FreelancersScreen())
      ),
      (
        Icons.sell_rounded,
        'For Sale',
        const Color(0xFF00897B),
        () => _push(CategoryScreen(category: 'for_sale', title: 'For Sale & Free'))
      ),
      (
        Icons.campaign_rounded,
        'Announcements',
        const Color(0xFF5E35B1),
        () => _push(CategoryScreen(category: 'announcements', title: 'Announcements'))
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final a in actions) ...[
            if (a != actions.first) const SizedBox(width: 8),
            SizedBox(
              width: 74,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: a.$4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: a.$3.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(a.$1, color: a.$3, size: 22),
                      ),
                      const SizedBox(height: 5),
                      Text(a.$2,
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Featured Businesses section ----
  Widget _featuredSection(BuildContext context, ContentProvider prov) {
    final cs = Theme.of(context).colorScheme;
    final placements = prov.featured;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFD600)),
            const SizedBox(width: 6),
            Expanded(child: _sectionHeader(cs, 'FEATURED BUSINESSES')),
            TextButton(
              onPressed: () => _push(const BusinessesScreen()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (placements.isEmpty)
          _featuredInviteCard(context)
        else
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: placements.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _featuredPlacementCard(context, placements[i]),
            ),
          ),
      ],
    );
  }

  Widget _featuredPlacementCard(BuildContext context, dynamic placement) {
    final cs = Theme.of(context).colorScheme;
    final name = placement['business_name'] ?? 'Local Business';
    final headline = placement['headline'] ?? 'Featured';
    final bizImage = placement['business_image'] as String?;

    return GestureDetector(
      onTap: () => _push(const BusinessesScreen()),
      child: Container(
        width: 236,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: cs.surface,
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (bizImage != null && bizImage.isNotEmpty)
              Image.network(bizImage, fit: BoxFit.cover)
            else
              Image.asset('assets/images/banner_business.png',
                  fit: BoxFit.cover),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.72),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD600),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('SPONSORED',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: Colors.black)),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  if (headline.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(headline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85))),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shown when no paid placements are active — the monetization nudge.
  Widget _featuredInviteCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _push(const TipScreen()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.14),
              cs.tertiary.withValues(alpha: 0.08)
            ],
          ),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.star_outline_rounded,
                  color: Color(0xFFFFD600), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Own a local business?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 2),
                  Text('Get featured to the whole community.',
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.primary),
          ],
        ),
      ),
    );
  }

  // ---- Weather banner ----
  Color _fireRiskColor(String risk) {
    final r = risk.toLowerCase();
    if (r.contains('extreme') || r.contains('critical'))
      return const Color(0xFFFF1744);
    if (r.contains('high') || r.contains('very'))
      return const Color(0xFFFF9100);
    if (r.contains('moderate')) return const Color(0xFFFFD600);
    return const Color(0xFF00E676);
  }

  // ---- Today's discussion (daily Seddit topics) ----
  Widget _dailyDiscussionSection(BuildContext context, ColorScheme cs) {
    final featured = _dailyTopics.first;
    final rest = _dailyTopics.skip(1).take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.forum_rounded, size: 18, color: Color(0xFF00E5FF)),
            const SizedBox(width: 6),
            Expanded(child: _sectionHeader(cs, "TODAY'S DISCUSSION")),
            TextButton(
              onPressed: () => _push(const ConversationsScreen()),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
                textStyle:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _dailyTopicCard(context, cs, featured),
        for (final t in rest) ...[
          const SizedBox(height: 6),
          _dailyTopicRow(context, cs, t),
        ],
      ],
    );
  }

  Widget _dailyTopicCard(
      BuildContext context, ColorScheme cs, DiscussionTopicItem t) {
    return GestureDetector(
      onTap: () => _push(TopicScreen(topicId: t.id)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              cs.primary.withValues(alpha: 0.16),
              cs.tertiary.withValues(alpha: 0.08),
            ],
          ),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('DAILY QUESTION',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                          letterSpacing: 0.6)),
                ),
                const Spacer(),
                Text('by ${t.author}',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text(t.title,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface)),
            if (t.body.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(t.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${t.commentCount} comments',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant)),
                const Spacer(),
                Text('Join in',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.primary)),
                Icon(Icons.chevron_right, size: 16, color: cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyTopicRow(
      BuildContext context, ColorScheme cs, DiscussionTopicItem t) {
    return GestureDetector(
      onTap: () => _push(TopicScreen(topicId: t.id)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface)),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chat_bubble_outline_rounded,
                size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 3),
            Text('${t.commentCount}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            Icon(Icons.chevron_right, size: 16, color: cs.outline),
          ],
        ),
      ),
    );
  }

  // ---- Active alert banner ----
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
              sev == 'emergency'
                  ? Icons.error
                  : sev == 'warning'
                      ? Icons.warning_amber
                      : Icons.info_outline,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(alert.title,
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ),
            Icon(Icons.chevron_right,
                color: color.withValues(alpha: 0.5), size: 18),
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
              width: 44,
              height: 44,
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
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface)),
                  if (s.type != null)
                    Text(s.type!,
                        style: TextStyle(fontSize: 12, color: cs.primary)),
                  if (s.address != null)
                    Text(s.address!,
                        style:
                            TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
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
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(date,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary)),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Nav helpers ----
  void _openNews(BuildContext ctx, NewsItem item) {
    _push(DetailScreen(
        title: item.title,
        itemType: 'news',
        content: item.content,
        itemId: item.id,
        metadata: {
          if (item.imageUrl != null) 'image_url': item.imageUrl!,
          if (item.videoUrl != null) 'video_url': item.videoUrl!,
          if (item.sourceUrl != null) 'source_url': item.sourceUrl!,
        }));
  }

  void _openEvent(BuildContext ctx, EventItem e) => _push(DetailScreen(
          title: e.title,
          itemType: 'event',
          content: e.description ?? '',
          itemId: e.id,
          metadata: {
            if (e.startDate != null)
              'start_date': e.startDate!.toIso8601String(),
            if (e.endDate != null) 'end_date': e.endDate!.toIso8601String(),
            if (e.location != null) 'location': e.location!,
            if (e.imageUrl != null) 'image_url': e.imageUrl!,
          }));

  void _openBusiness(BuildContext ctx, BusinessItem b) => _push(DetailScreen(
          title: b.name,
          itemType: 'business',
          content: b.description ?? '',
          itemId: b.id,
          metadata: {
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
  const _TimelineEntry(
      {required this.date, required this.type, required this.widget});
}
