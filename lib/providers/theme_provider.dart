import 'package:app/util/colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ColorToken {
  ThemeData get themeData;

  // Primary colors
  Color get primary;
  Color get onPrimary;
  Color get primaryContainer;
  Color get onPrimaryContainer;

  // Background colors
  Color get background;
  Color get onBackground;
  Color get surface;
  Color get onSurface;
  Color get surfaceVariant;

  // Text colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;

  // Status colors
  Color get success;
  Color get warning;
  Color get error;
  Color get info;

  // Auction specific colors
  Color get bidActive;
  Color get bidWon;
  Color get bidLost;
  Color get watchlist;

  // UI elements
  Color get divider;
  Color get shadow;
  Color get cardBackground;
  Color get buttonSecondary;
  Color get onButtonSecondary;
}

class _LightColorToken extends ColorToken {
  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: Colors.grey,

    colorScheme: ColorScheme.light(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      surface: surface,
      onSurface: onSurface,
      error: error,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      displayMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      displaySmall: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      headlineLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      headlineMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      headlineSmall: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      titleLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      titleMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      titleSmall: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      bodyLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      bodyMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      bodySmall: TextStyle(color: textSecondary, fontFamily: 'SourceSans3'),
      labelLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      labelMedium: TextStyle(color: textSecondary, fontFamily: 'SourceSans3'),
      labelSmall: TextStyle(color: textTertiary, fontFamily: 'SourceSans3'),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'SourceSans3',
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: buttonSecondary,
        foregroundColor: onButtonSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: divider),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardBackground,
      shadowColor: shadow,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: divider,
      thickness: 1,
    ),
  );

  @override
  Color get primary => AppColors.gavelGrey; // Grey from gavel handle

  @override
  Color get onPrimary => Colors.white;

  @override
  Color get primaryContainer => AppColors.neutral100;

  @override
  Color get onPrimaryContainer => AppColors.neutral800;

  @override
  Color get background => AppColors.neutral050; // Light grey like screenshot

  @override
  Color get onBackground => AppColors.neutral900;

  @override
  Color get surface => Colors.white;

  @override
  Color get onSurface => AppColors.neutral800;

  @override
  Color get surfaceVariant => AppColors.neutral100; // Input field grey

  @override
  Color get textPrimary => AppColors.neutral800; // "Auction App" black text

  @override
  Color get textSecondary => AppColors.neutral500; // "Welcome back" grey

  @override
  Color get textTertiary => AppColors.neutral400; // Placeholder text

  @override
  Color get success => AppColors.success;

  @override
  Color get warning => AppColors.warning;

  @override
  Color get error => AppColors.error;

  @override
  Color get info => AppColors.info;

  @override
  Color get bidActive => AppColors.bidActive;

  @override
  Color get bidWon => AppColors.bidWon;

  @override
  Color get bidLost => AppColors.bidLost;

  @override
  Color get watchlist => AppColors.watchlist;

  @override
  Color get divider => AppColors.neutral200;

  @override
  Color get shadow => Colors.black.withValues(alpha: 0.05);

  @override
  Color get cardBackground => Colors.white;

  @override
  Color get buttonSecondary => AppColors.neutral100;

  @override
  Color get onButtonSecondary => AppColors.neutral700;
}

class _DarkColorToken extends ColorToken {
  @override
  ThemeData get themeData => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: Colors.grey,

    colorScheme: ColorScheme.dark(
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      surface: surface,
      onSurface: onSurface,
      error: error,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      displayMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      displaySmall: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      headlineLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      headlineMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      headlineSmall: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      titleLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      titleMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      titleSmall: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      bodyLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      bodyMedium: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      bodySmall: TextStyle(color: textSecondary, fontFamily: 'SourceSans3'),
      labelLarge: TextStyle(color: textPrimary, fontFamily: 'SourceSans3'),
      labelMedium: TextStyle(color: textSecondary, fontFamily: 'SourceSans3'),
      labelSmall: TextStyle(color: textTertiary, fontFamily: 'SourceSans3'),
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        fontFamily: 'SourceSans3',
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        backgroundColor: buttonSecondary,
        foregroundColor: onButtonSecondary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: divider),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardBackground,
      shadowColor: shadow,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),

    dividerTheme: DividerThemeData(
      color: divider,
      thickness: 1,
    ),
  );

  @override
  Color get primary => AppColors.gavelGrey;

  @override
  Color get onPrimary => AppColors.black;

  @override
  Color get primaryContainer => AppColors.neutral800;

  @override
  Color get onPrimaryContainer => AppColors.neutral100;

  @override
  Color get background => AppColors.black;

  @override
  Color get onBackground => AppColors.neutral100;

  @override
  Color get surface => AppColors.neutral900;

  @override
  Color get onSurface => AppColors.neutral200;

  @override
  Color get surfaceVariant => AppColors.neutral800;

  @override
  Color get textPrimary => AppColors.neutral100;

  @override
  Color get textSecondary => AppColors.neutral400;

  @override
  Color get textTertiary => AppColors.neutral500;

  @override
  Color get success => AppColors.success;

  @override
  Color get warning => AppColors.warning;

  @override
  Color get error => AppColors.error;

  @override
  Color get info => AppColors.info;

  @override
  Color get bidActive => AppColors.bidActive;

  @override
  Color get bidWon => AppColors.bidWon;

  @override
  Color get bidLost => AppColors.bidLost;

  @override
  Color get watchlist => AppColors.watchlist;

  @override
  Color get divider => AppColors.neutral800;

  @override
  Color get shadow => Colors.black.withValues(alpha: 0.3);

  @override
  Color get cardBackground => AppColors.neutral800;

  @override
  Color get buttonSecondary => AppColors.neutral800;

  @override
  Color get onButtonSecondary => AppColors.neutral200;
}

const String _themeKey = "auction_theme";

class ThemeProvider with ChangeNotifier {
  bool isLightTheme = true;
  ColorToken _colorToken = _LightColorToken();
  ColorToken get colorToken => _colorToken;

  final SharedPreferences sharedPreferences;

  ThemeProvider(this.sharedPreferences) {
    loadTheme();
  }

  static ThemeProvider of(BuildContext context, {bool listen = false}) {
    return Provider.of<ThemeProvider>(context, listen: listen);
  }

  void toggleTheme() {
    setIsLightTheme(!isLightTheme);
  }

  void setIsLightTheme(bool isLight) async {
    isLightTheme = isLight;
    _colorToken = isLightTheme ? _LightColorToken() : _DarkColorToken();

    await sharedPreferences.setBool(_themeKey, isLightTheme);
    notifyListeners();
  }

  Future<void> loadTheme() async {
    isLightTheme = sharedPreferences.getBool(_themeKey) ?? true;
    _colorToken = isLightTheme ? _LightColorToken() : _DarkColorToken();

    notifyListeners();
  }

  // Minimal background - NO gradient like screenshot
  LinearGradient get primaryGradient => isLightTheme
      ? const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.neutral050, // Just solid grey
      AppColors.neutral050,
    ],
  )
      : const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      AppColors.black,
      AppColors.black,
    ],
  );

  LinearGradient get cardGradient => isLightTheme
      ? const LinearGradient(
    colors: [Colors.white, Colors.white],
  )
      : LinearGradient(
    colors: [_colorToken.cardBackground, _colorToken.cardBackground],
  );

  // Status color helpers for auction items
  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'bidding':
        return _colorToken.bidActive;
      case 'won':
        return _colorToken.bidWon;
      case 'lost':
        return _colorToken.bidLost;
      case 'watching':
        return _colorToken.watchlist;
      default:
        return _colorToken.textSecondary;
    }
  }

  Color getStatusBackgroundColor(String status) {
    final color = getStatusColor(status);
    return color.withValues(alpha: 0.1);
  }
}