import 'package:flutter/material.dart';

/// "Architectural Obsidian" palette and theme for the classes module.
abstract final class KinevorClassesBookingsTheme {
  /// App background ink.
  static const Color ink = Color(0xFF111317);

  /// Base surface.
  static const Color surface = Color(0xFF16181D);

  /// Card and sheet surface.
  static const Color surfaceRaised = Color(0xFF1E2127);

  /// Hairline border.
  static const Color border = Color(0xFF2A2E36);

  /// Primary text.
  static const Color text = Color(0xFFF4F5F7);

  /// Secondary text.
  static const Color textMuted = Color(0xFF8E949E);

  /// Brand crimson accent.
  static const Color accent = Color(0xFFFF453A);

  /// Accent pressed state.
  static const Color accentPressed = Color(0xFFE0342A);

  /// Text on accent fills.
  static const Color onAccent = Color(0xFFFFFFFF);

  /// Success green.
  static const Color success = Color(0xFF34D399);

  /// Warning amber.
  static const Color warning = Color(0xFFFBBF24);

  /// Error red.
  static const Color error = Color(0xFFFF6B6B);

  /// Info blue.
  static const Color info = Color(0xFF4DAEFF);

  /// Brand gradient used by the logo and primary calls to action.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFBF360C), Color(0xFFFF7A00)],
  );

  /// Accent color for a class type.
  static Color classColor(String type) => switch (type.toLowerCase()) {
    'yoga' => const Color(0xFFAB47BC),
    'pilates' => const Color(0xFF42A5F5),
    'zumba' => const Color(0xFFFFCA28),
    'hiit' => const Color(0xFFEF5350),
    'spinning' => const Color(0xFF66BB6A),
    'boxing' => const Color(0xFFE65100),
    'crossfit' => const Color(0xFFFFA726),
    'aqua' => const Color(0xFF26C6DA),
    'bodypump' => const Color(0xFFEC407A),
    'kickboxing' => const Color(0xFF8D6E63),
    'stretching' => const Color(0xFF78909C),
    'meditation' => const Color(0xFF7E57C2),
    _ => accent,
  };

  /// Icon for a class type.
  static IconData classIcon(String type) => switch (type.toLowerCase()) {
    'yoga' => Icons.self_improvement,
    'pilates' => Icons.accessibility_new,
    'zumba' => Icons.music_note,
    'hiit' => Icons.local_fire_department_outlined,
    'spinning' => Icons.directions_bike,
    'boxing' => Icons.sports_mma,
    'crossfit' => Icons.fitness_center,
    'aqua' => Icons.pool,
    'bodypump' => Icons.fitness_center_outlined,
    'kickboxing' => Icons.sports_martial_arts,
    'stretching' => Icons.accessibility,
    'meditation' => Icons.spa_outlined,
    _ => Icons.event_available,
  };

  /// Status color used by class and booking badges.
  static Color statusColor(String status) => switch (status.toLowerCase()) {
    'scheduled' || 'confirmed' || 'attended' => success,
    'inprogress' || 'waitlisted' => warning,
    'cancelled' || 'noshow' => error,
    'completed' => textMuted,
    _ => info,
  };

  /// Icon paired with [statusColor] so meaning never rides on color.
  static IconData statusIcon(String status) => switch (status.toLowerCase()) {
    'scheduled' || 'confirmed' || 'attended' => Icons.check_circle_outline,
    'inprogress' || 'waitlisted' => Icons.hourglass_top,
    'cancelled' || 'noshow' => Icons.block_outlined,
    'completed' => Icons.history,
    _ => Icons.info_outline,
  };

  /// Builds the dark classes theme with Sora typography.
  static ThemeData dark({String fontFamily = 'Sora'}) {
    const scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: accent,
      onPrimary: onAccent,
      secondary: accent,
      onSecondary: onAccent,
      error: error,
      onError: onAccent,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: textMuted,
      surfaceContainerHighest: surfaceRaised,
      surfaceContainerHigh: surfaceRaised,
      surfaceContainerLow: surface,
      surfaceContainerLowest: ink,
      surfaceContainer: surfaceRaised,
      outline: border,
      outlineVariant: border,
    );

    final textTheme = const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.5),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5),
      bodySmall: TextStyle(fontSize: 12, height: 1.45),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
    ).apply(fontFamily: fontFamily, bodyColor: text, displayColor: text);

    final buttonTextStyle = textTheme.labelLarge?.copyWith(
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    final outlinedButtonTextStyle = textTheme.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w700,
    );
    final segmentTextStyle = textTheme.labelSmall?.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: ink,
      canvasColor: ink,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: ink,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceRaised,
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: accent,
          foregroundColor: onAccent,
          textStyle: buttonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(46),
          foregroundColor: text,
          side: const BorderSide(color: border),
          textStyle: outlinedButtonTextStyle,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? accent : surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? onAccent : textMuted,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          textStyle: WidgetStatePropertyAll(segmentTextStyle),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
      dividerTheme: const DividerThemeData(
        color: border,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceRaised,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: text),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    );
  }
}
