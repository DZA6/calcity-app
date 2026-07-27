import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/content_provider.dart';
import 'services/ad_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AdService().initialize();
    AdService().loadBannerAd();
  } catch (_) {
    // Ads unavailable on this platform
  }
  runApp(const CalCityApp());
}

class CalCityApp extends StatelessWidget {
  const CalCityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContentProvider(),
      child: MaterialApp(
        title: 'Cal City',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme(
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
      background: Color(0xFFFFFBFF),
      onBackground: Color(0xFF201A18),
      surface: Color(0xFFFFFBFF),
      onSurface: Color(0xFF201A18),
      surfaceVariant: Color(0xFFF5DED5),
      onSurfaceVariant: Color(0xFF53443D),
      outline: Color(0xFF85736B),
      onInverseSurface: Color(0xFFFAEEE8),
      inverseSurface: Color(0xFF362F2B),
      inversePrimary: Color(0xFFFFB59E),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        thickness: 0.5,
        space: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFFFB59E),
      onPrimary: Color(0xFF571F0D),
      primaryContainer: Color(0xFF8B3A26),
      onPrimaryContainer: Color(0xFFFFDBD0),
      secondary: Color(0xFFF0BA96),
      onSecondary: Color(0xFF4A2E15),
      secondaryContainer: Color(0xFF6A4426),
      onSecondaryContainer: Color(0xFFFFDCC2),
      tertiary: Color(0xFFC7D6A1),
      onTertiary: Color(0xFF303615),
      tertiaryContainer: Color(0xFF474F2B),
      onTertiaryContainer: Color(0xFFE3F2BB),
      error: Color(0xFFFFB4AB),
      errorContainer: Color(0xFF93000A),
      onError: Color(0xFF690005),
      onErrorContainer: Color(0xFFFFDAD6),
      background: Color(0xFF1F1A18),
      onBackground: Color(0xFFEDE0DA),
      surface: Color(0xFF1F1A18),
      onSurface: Color(0xFFEDE0DA),
      surfaceVariant: Color(0xFF53443D),
      onSurfaceVariant: Color(0xFFD8C2B9),
      outline: Color(0xFFA08D84),
      onInverseSurface: Color(0xFF201A18),
      inverseSurface: Color(0xFFEDE0DA),
      inversePrimary: Color(0xFFB8573E),
      shadow: Color(0xFF000000),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        filled: true,
        fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}
