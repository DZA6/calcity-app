import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/content_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'services/ad_service.dart';
import 'services/api_service.dart';
import 'services/push_service.dart';
import 'widgets/ad_banner.dart';
import 'models/content.dart';
import 'screens/home_screen.dart';
import 'screens/businesses_screen.dart';
import 'screens/freelancers_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/category_screen.dart';
import 'screens/deals_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AdService().initialize();
    AdService().ensureBanner();
    AdService().preloadInterstitial();
  } catch (_) {
    // Ads unavailable on this platform
  }
  // Push notifications (no-op until Firebase is configured)
  await PushService().initialize();
  runApp(const CalCityApp());
}

class CalCityApp extends StatelessWidget {
  const CalCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SettingsProvider()..load(),
      builder: (context, _) {
        final settings = context.watch<SettingsProvider>();
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ContentProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            title: 'Cal City',
            debugShowCheckedModeBanner: false,
            theme: _buildLightTheme(),
            darkTheme: _buildDarkTheme(),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: const MainShell(),
          ),
        );
      },
    );
  }

  // ---- Dark theme (neon green on black) ----
  ThemeData _buildDarkTheme() {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF00FF41),
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFF003D10),
      onPrimaryContainer: Color(0xFF7BFF90),
      secondary: Color(0xFF39FF14),
      onSecondary: Color(0xFF000000),
      secondaryContainer: Color(0xFF003D10),
      onSecondaryContainer: Color(0xFF7BFF90),
      tertiary: Color(0xFF00E5FF),
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFF003540),
      onTertiaryContainer: Color(0xFF82F3FF),
      error: Color(0xFFFF5252),
      errorContainer: Color(0xFF93000A),
      onError: Color(0xFF000000),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF0D0D0D),
      onSurface: Color(0xFFE8E8E8),
      surfaceVariant: Color(0xFF1E1E1E),
      onSurfaceVariant: Color(0xFFB0B8B0),
      outline: Color(0xFF2A3A2A),
      outlineVariant: Color(0xFF1A2A1A),
      inverseSurface: Color(0xFFE0FFE0),
      onInverseSurface: Color(0xFF0A0A0A),
      inversePrimary: Color(0xFF00FF41),
      shadow: Color(0xFF000000),
      surfaceTint: Color(0xFF00FF41),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: const Color(0xFF121212),
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        indicatorColor: cs.primary.withValues(alpha: 0.15),
        elevation: 0,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: cs.onSurfaceVariant, size: 22),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: const Color(0xFF121212),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
        backgroundColor: cs.surfaceVariant.withValues(alpha: 0.5),
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5,
        space: 0,
        color: cs.outline.withValues(alpha: 0.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surfaceVariant.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  // ---- Light theme ----
  ThemeData _buildLightTheme() {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFB8573E),
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFFFDBD0),
      onPrimaryContainer: Color(0xFF3B0D02),
      secondary: Color(0xFF8B5A3C),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFFFDCC2),
      onSecondaryContainer: Color(0xFF311A06),
      tertiary: Color(0xFF5F6B41),
      onTertiary: Color(0xFFFFFFFF),
      tertiaryContainer: Color(0xFFE3F2BB),
      onTertiaryContainer: Color(0xFF1B2106),
      error: Color(0xFFBA1A1A),
      errorContainer: Color(0xFFFFDAD6),
      onError: Color(0xFFFFFFFF),
      onErrorContainer: Color(0xFF410002),
      surface: Color(0xFFF8F9FA),
      onSurface: Color(0xFF1A1C1E),
      surfaceVariant: Color(0xFFF0EEE9),
      onSurfaceVariant: Color(0xFF44474F),
      outline: Color(0xFFE0E0E0),
      outlineVariant: Color(0xFFE8E8E8),
      inverseSurface: Color(0xFF2F3033),
      onInverseSurface: Color(0xFFF1F0F4),
      inversePrimary: Color(0xFFFFB59E),
      shadow: Color(0xFF000000),
      surfaceTint: Color(0xFFB8573E),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFAFAFA),
        indicatorColor: cs.primary.withValues(alpha: 0.12),
        elevation: 0,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: cs.onSurfaceVariant, size: 22),
        ),
      ),
      drawerTheme: DrawerThemeData(
        backgroundColor: const Color(0xFFF5F5F5),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.5)),
        backgroundColor: cs.surfaceVariant.withValues(alpha: 0.5),
      ),
      dividerTheme: DividerThemeData(
        thickness: 0.5, space: 0,
        color: cs.outline.withValues(alpha: 0.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surfaceVariant.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: const Color(0xFFFAFAFA),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }
}

/// Main scaffold shell with bottom navigation
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  int _tabSwitches = 0;

  static const _screens = <Widget>[
    HomeScreen(),
    ExploreScreen(),
    BusinessesScreen(),
    AlertsScreen(),
    DealsScreen(),
  ];

  void _onDestinationSelected(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);

    // Interstitial every 3rd tab switch (AdService enforces a cooldown too)
    _tabSwitches++;
    if (_tabSwitches % 3 == 0) {
      AdService().showInterstitialIfReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner ad above the nav bar — visible on all tabs
          const AdBanner(),
          NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.explore_outlined),
                selectedIcon: Icon(Icons.explore),
                label: 'Explore',
              ),
              NavigationDestination(
                icon: Icon(Icons.store_outlined),
                selectedIcon: Icon(Icons.store),
                label: 'Businesses',
              ),
              NavigationDestination(
                icon: Icon(Icons.campaign_outlined),
                selectedIcon: Icon(Icons.campaign),
                label: 'Alerts',
              ),
              NavigationDestination(
                icon: Icon(Icons.local_offer_outlined),
                selectedIcon: Icon(Icons.local_offer),
                label: 'Deals',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Explore screen — category grid + event calendar
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});
  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  List<EventItem> _events = [];
  bool _loaded = false;

  static const _categories = <Map<String, dynamic>>[
    {'slug': 'city_works', 'label': 'City Works', 'icon': Icons.engineering_outlined, 'color': Color(0xFF5F6B41)},
    {'slug': 'church', 'label': 'Church/Faith', 'icon': Icons.church_outlined, 'color': Color(0xFF8B5A3C)},
    {'slug': 'recreation', 'label': 'Recreation', 'icon': Icons.park_outlined, 'color': Color(0xFF4A7C59)},
    {'slug': 'law_enforcement', 'label': 'Law Enforcement', 'icon': Icons.local_police_outlined, 'color': Color(0xFF3A4B6D)},
    {'slug': 'health', 'label': 'Health', 'icon': Icons.health_and_safety_outlined, 'color': Color(0xFF4D8C7A)},
    {'slug': 'education', 'label': 'Education', 'icon': Icons.school_outlined, 'color': Color(0xFF6B5B95)},
    {'slug': 'business', 'label': 'Business', 'icon': Icons.store_outlined, 'color': Color(0xFFB8573E)},
    {'slug': 'traffic', 'label': 'Traffic', 'icon': Icons.traffic_outlined, 'color': Color(0xFF8B6B3A)},
    {'slug': 'community', 'label': 'Community', 'icon': Icons.celebration_outlined, 'color': Color(0xFF9B5E3A)},
  ];

  static final _categoryColors = <String, Color>{
    'community': const Color(0xFF5B9BD5),
    'school': const Color(0xFFE8A838),
    'sports': const Color(0xFF28A745),
    'city': const Color(0xFFC67B5C),
  };

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await ApiService().fetchEvents();
    if (mounted) setState(() { _events = events; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/images/calcity_logo.png', height: 36),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _categories.length + 1,
              itemBuilder: (ctx, i) {
                // Last item = Freelancers button
                if (i == _categories.length) {
                  return GestureDetector(
                    onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => const FreelancersScreen(),
                    )),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_outline, color: Colors.blue, size: 22),
                          ),
                          const SizedBox(height: 10),
                          Text('Freelancers', textAlign: TextAlign.center, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface, height: 1.2,
                          ), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  );
                }

                final cat = _categories[i];
                final color = cat['color'] as Color;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => CategoryScreen(
                        category: cat['slug'] as String,
                        title: cat['label'] as String,
                      ),
                    ));
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(cat['icon'] as IconData, color: color, size: 22),
                        ),
                        const SizedBox(height: 10),
                        Text(cat['label'] as String, textAlign: TextAlign.center, style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurface, height: 1.2,
                        ), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Event Calendar
            if (_loaded && _events.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  const Icon(Icons.calendar_month, size: 20),
                  const SizedBox(width: 8),
                  Text('Events', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                  const Spacer(),
                  Text('${_events.length} upcoming', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                ]),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _events.length,
                  itemBuilder: (ctx, i) {
                    final event = _events[i];
                    final catColor = _categoryColors[event.category] ?? cs.primary;
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Container(
                            width: 56, height: 56,
                            decoration: BoxDecoration(
                              color: cs.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: cs.outline.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  event.startDate != null
                                      ? '${event.startDate!.day}'
                                      : '?',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
                                ),
                                Text(
                                  event.startDate != null
                                      ? _monthAbbr(event.startDate!.month)
                                      : '',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Color-coded dot
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: catColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  String _monthAbbr(int month) {
    const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month];
  }
}
