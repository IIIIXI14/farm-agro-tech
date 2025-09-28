import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _primaryColorKey = 'primary_color';
  
  ThemeMode _themeMode = ThemeMode.system;
  Color _primaryColor = const Color(0xFF2E7D32); // Green for agriculture theme
  
  // Enhanced color palette
  static const Color _accentGreen = Color(0xFF4CAF50);
  static const Color _accentBlue = Color(0xFF2196F3);
  static const Color _accentOrange = Color(0xFFFF9800);
  static const Color _accentRed = Color(0xFFF44336);
  static const Color _accentPurple = Color(0xFF9C27B0);
  static const Color _accentTeal = Color(0xFF009688);
  
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  static Future<ThemeService> init() async {
    final service = ThemeService();
    await service._loadPreferences();
    return service;
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Handle theme mode - check if it's stored as string or int
    int themeIndex = 0;
    final themeValue = prefs.get(_themeKey);
    if (themeValue is int) {
      themeIndex = themeValue;
    } else if (themeValue is String) {
      // Try to parse the string value
      try {
        themeIndex = int.parse(themeValue);
      } catch (e) {
        themeIndex = 0; // Default to system theme
      }
    }
    
    // Ensure themeIndex is within valid range
    if (themeIndex >= ThemeMode.values.length) {
      themeIndex = 0;
    }
    
    // Handle primary color
    int primaryColorValue = 0xFF2E7D32; // Default green color
    final colorValue = prefs.get(_primaryColorKey);
    if (colorValue is int) {
      primaryColorValue = colorValue;
    } else if (colorValue is String) {
      try {
        primaryColorValue = int.parse(colorValue);
      } catch (e) {
        primaryColorValue = 0xFF2E7D32; // Default green color
      }
    }
    
    _themeMode = ThemeMode.values[themeIndex];
    _primaryColor = Color(primaryColorValue);
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, _themeMode.index);
    await prefs.setInt(_primaryColorKey, _primaryColor.toARGB32());
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _savePreferences();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _savePreferences();
    notifyListeners();
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    _savePreferences();
    notifyListeners();
  }

  ThemeData get lightTheme {
    // Use Inter when bundled; fall back to default TextTheme if runtime fetching is disabled
    final textTheme = GoogleFonts.config.allowRuntimeFetching
        ? GoogleFonts.interTextTheme()
        : ThemeData.light().textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.light,
        primary: _primaryColor,
        secondary: _accentTeal,
        tertiary: _accentOrange,
        error: _accentRed,
        surface: const Color(0xFFF8F9FA),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: (GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.config.allowRuntimeFetching
              ? GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )
              : const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: _primaryColor,
        labelStyle: GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )
            : const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              )
            : const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _primaryColor.withValues(alpha: 0.1),
        selectedColor: _primaryColor,
        labelStyle: GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(fontWeight: FontWeight.w500)
            : const TextStyle(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),
    );
  }

  ThemeData get darkTheme {
    final textTheme = GoogleFonts.config.allowRuntimeFetching
        ? GoogleFonts.interTextTheme(ThemeData.dark().textTheme)
        : ThemeData.dark().textTheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primaryColor,
        brightness: Brightness.dark,
        primary: _primaryColor,
        secondary: _accentTeal,
        tertiary: _accentOrange,
        error: _accentRed,
        surface: const Color(0xFF1E1E1E),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        titleTextStyle: (GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )
            : const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              )),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: const Color(0xFF1E1E1E),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 3,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.config.allowRuntimeFetching
              ? GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                )
              : const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade800,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: _primaryColor,
        unselectedLabelColor: Colors.grey.shade400,
        indicatorColor: _primaryColor,
        labelStyle: GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              )
            : const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              )
            : const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _primaryColor.withValues(alpha: 0.2),
        selectedColor: _primaryColor,
        labelStyle: GoogleFonts.config.allowRuntimeFetching
            ? GoogleFonts.inter(fontWeight: FontWeight.w500)
            : const TextStyle(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade800,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Get accent colors for different purposes
  Color getAccentColor(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return _accentGreen;
      case 'info':
        return _accentBlue;
      case 'warning':
        return _accentOrange;
      case 'error':
        return _accentRed;
      case 'secondary':
        return _accentTeal;
      case 'tertiary':
        return _accentPurple;
      default:
        return _primaryColor;
    }
  }

  // Get gradient for enhanced visual appeal
  LinearGradient getPrimaryGradient() {
    return LinearGradient(
      colors: [_primaryColor, _primaryColor.withValues(alpha: 0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  LinearGradient getAccentGradient() {
    return const LinearGradient(
      colors: [_accentTeal, _accentBlue],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
} 