import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/content_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/auth_provider.dart';
import 'services/push_service.dart';
import 'services/reminder_service.dart';
import 'screens/home_screen.dart';
import 'screens/businesses_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/deals_screen.dart';
import 'screens/conversations_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Push notifications (no-op until Firebase is configured)
  try {
    await PushService().initialize();
  } catch (_) {
    // Firebase/Play Services unavailable on this device
  }
  try {
    await ReminderService.instance.init();
  } catch (_) {
    // Notifications unavailable on this device
  }
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
            ChangeNotifierProvider(create: (_) => AuthProvider()..load()),
          ],
          child: MaterialApp(
            title: 'Cal City',
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              ErrorWidget.builder = (details) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Something went wrong.\nPull to refresh.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ),
                  );
              // Apply user font-size preference
              final media = MediaQuery.of(context);
              return MediaQuery(
                data: media.copyWith(
                  textScaler: TextScaler.linear(settings.fontScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
            theme: _buildLightTheme(settings.accentColorValue),
            darkTheme: _buildDarkTheme(settings.accentColorValue),
            themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            home: settings.initialized && !settings.onboarded
                ? OnboardingScreen(
                    onComplete: () => settings.setOnboarded(true))
                : const MainShell(),
          ),
        );
      },
    );
  }

  // ---- Dark theme (accent color on black) ----
  ThemeData _buildDarkTheme(Color accent) {
    final cs = ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
      primaryContainer: Color.lerp(accent, Colors.black, 0.65)!,
      onPrimaryContainer: Color.lerp(accent, Colors.white, 0.75)!,
      secondary: Color.lerp(accent, Colors.white, 0.25)!,
      onSecondary:
          accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
      secondaryContainer: Color.lerp(accent, Colors.black, 0.7)!,
      onSecondaryContainer: Color.lerp(accent, Colors.white, 0.7)!,
      tertiary: Color.lerp(accent, const Color(0xFF00E5FF), 0.5)!,
      onTertiary: Colors.black,
      tertiaryContainer: Color.lerp(accent, Colors.black, 0.8)!,
      onTertiaryContainer: Color.lerp(accent, Colors.white, 0.8)!,
      error: const Color(0xFFFF5252),
      errorContainer: const Color(0xFF93000A),
      onError: const Color(0xFF000000),
      onErrorContainer: const Color(0xFFFFDAD6),
      surface: const Color(0xFF0D0D0D),
      onSurface: const Color(0xFFE8E8E8),
      surfaceVariant: const Color(0xFF1E1E1E),
      onSurfaceVariant: const Color(0xFFB0B8B0),
      outline: Color.lerp(accent, Colors.black, 0.8)!,
      outlineVariant: const Color(0xFF1A2A1A),
      inverseSurface: const Color(0xFFE0FFE0),
      onInverseSurface: const Color(0xFF0A0A0A),
      inversePrimary: accent,
      shadow: const Color(0xFF000000),
      surfaceTint: accent,
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
          TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  ThemeData _buildLightTheme(Color accent) {
    final cs = ColorScheme(
      brightness: Brightness.light,
      primary: accent,
      onPrimary: accent.computeLuminance() > 0.5 ? Colors.black : Colors.white,
      primaryContainer: Color.lerp(accent, Colors.white, 0.8)!,
      onPrimaryContainer: Color.lerp(accent, Colors.black, 0.75)!,
      secondary: Color.lerp(accent, Colors.black, 0.15)!,
      onSecondary: Colors.white,
      secondaryContainer: Color.lerp(accent, Colors.white, 0.75)!,
      onSecondaryContainer: Color.lerp(accent, Colors.black, 0.8)!,
      tertiary: const Color(0xFF5F6B41),
      onTertiary: const Color(0xFFFFFFFF),
      tertiaryContainer: const Color(0xFFE3F2BB),
      onTertiaryContainer: const Color(0xFF1B2106),
      error: const Color(0xFFBA1A1A),
      errorContainer: const Color(0xFFFFDAD6),
      onError: const Color(0xFFFFFFFF),
      onErrorContainer: const Color(0xFF410002),
      surface: const Color(0xFFF8F9FA),
      onSurface: const Color(0xFF1A1C1E),
      surfaceVariant: const Color(0xFFF0EEE9),
      onSurfaceVariant: const Color(0xFF44474F),
      outline: const Color(0xFFE0E0E0),
      outlineVariant: const Color(0xFFE8E8E8),
      inverseSurface: const Color(0xFF2F3033),
      onInverseSurface: const Color(0xFFF1F0F4),
      inversePrimary: Color.lerp(accent, Colors.white, 0.5)!,
      shadow: const Color(0xFF000000),
      surfaceTint: accent,
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
          TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurface),
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
        thickness: 0.5,
        space: 0,
        color: cs.outline.withValues(alpha: 0.3),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: cs.surfaceVariant.withValues(alpha: 0.3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
  // Lazy tab loading: only build the selected screen.
  // IndexedStack built ALL tabs at once — 6 screens + 9 API calls
  // on app open, which crashed cheap phones. This builds one at a time
  // and keeps previously-visited tabs alive.
  final Map<int, Widget> _tabCache = {};
  int _selectedIndex = 0;

  Widget _buildTab(int index) {
    if (!_tabCache.containsKey(index)) {
      _tabCache[index] = _buildScreen(index);
    }
    return _tabCache[index]!;
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ExploreScreen();
      case 2:
        return const BusinessesScreen();
      case 3:
        return const AlertsScreen();
      case 4:
        return const DealsScreen();
      case 5:
        return const ConversationsScreen();
      default:
        return const HomeScreen();
    }
  }

  @override
  void initState() {
    super.initState();
    // Only build the Home tab initially — the rest load lazily on first tap.
    _tabCache[0] = const HomeScreen();
  }

  void _onDestinationSelected(int i) {
    if (i == _selectedIndex) return;
    setState(() => _selectedIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTab(_selectedIndex),
      bottomNavigationBar: NavigationBar(
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
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Community',
          ),
        ],
      ),
    );
  }
}
