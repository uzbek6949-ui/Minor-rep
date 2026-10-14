import 'package:flutter/material.dart';

/// Ilovaning rang va soya "tokenlari" — bitta joyda saqlanadi.
class AppColors {
  AppColors._();

  // Yorug' rejim
  static const Color background = Color(0xFFEFF1F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF111317); // asosiy matn va tugmalar
  static const Color inkSoft = Color(0xFF6E727B); // ikkilamchi matn
  static const Color inkFaint = Color(0xFFA9ADB6); // uchinchi darajali
  static const Color line = Color(0xFFE4E7EC);
  static const Color waveTrack = Color(0xFFCCD0D8);

  // Qora rejim — dizayndagi "1c: qatlamli" variantidan olingan ranglar
  static const Color darkBackground = Color(0xFF0E1013);
  static const Color darkSurface = Color(0xFF1A1C20); // qatorlar, varaqlar
  static const Color darkSurfaceHigh = Color(0xFF24262A); // joriy qator
  static const Color darkMiniPlayer = Color(0xFF2B2D30); // eng yuqori qatlam
  static const Color darkInk = Color(0xFFF4F6F8);
  static const Color darkInkSoft = Color(0xFF9DA3AD);
  static const Color darkLine = Color(0xFF262A31);
  static const Color darkWaveTrack = Color(0xFF4A505A);
}

/// Yumshoq soyalar — dizaynning asosiy belgisi.
class AppShadows {
  AppShadows._();

  /// Kartochka va qatorlar uchun yengil soya.
  static List<BoxShadow> soft({double opacity = 0.06}) => <BoxShadow>[
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  /// Katta albom rasmi uchun: yorug' rejimda soya, qora rejimda — rasm
  /// orqasidan taraladigan yumshoq yorug'lik (dizayndagi "qatlamli" uslub).
  static List<BoxShadow> artwork([Brightness brightness = Brightness.light]) {
    if (brightness == Brightness.dark) {
      return <BoxShadow>[
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.10),
          blurRadius: 84,
          spreadRadius: -14,
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 52,
          spreadRadius: -20,
          offset: const Offset(0, 24),
        ),
      ];
    }
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.13),
        blurRadius: 56,
        spreadRadius: -14,
        offset: const Offset(0, 26),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 18,
        spreadRadius: -6,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Katta play tugmasi: yorug'da soya, qorada oq halqa yorug'ligi.
  static List<BoxShadow> button([Brightness brightness = Brightness.light]) {
    if (brightness == Brightness.dark) {
      return <BoxShadow>[
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.14),
          blurRadius: 34,
          spreadRadius: -6,
        ),
      ];
    }
    return <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.20),
        blurRadius: 30,
        spreadRadius: -8,
        offset: const Offset(0, 14),
      ),
    ];
  }
}

/// Umumiy o'lchamlar.
class AppRadii {
  AppRadii._();

  static const double tile = 16;
  static const double card = 20;
  static const double artwork = 26;
  static const double pill = 30;
}

class AppTheme {
  AppTheme._();

  static const String fontFamily = 'Poppins';

  static ThemeData light() {
    return _build(
      brightness: Brightness.light,
      background: AppColors.background,
      surface: AppColors.surface,
      ink: AppColors.ink,
      inkSoft: AppColors.inkSoft,
      line: AppColors.line,
    );
  }

  static ThemeData dark() {
    return _build(
      brightness: Brightness.dark,
      background: AppColors.darkBackground,
      surface: AppColors.darkSurface,
      ink: AppColors.darkInk,
      inkSoft: AppColors.darkInkSoft,
      line: AppColors.darkLine,
    );
  }

  static ThemeData _build({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color ink,
    required Color inkSoft,
    required Color line,
  }) {
    final isLight = brightness == Brightness.light;
    final onInk = isLight ? Colors.white : AppColors.darkBackground;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: ink,
      onPrimary: onInk,
      secondary: ink,
      onSecondary: onInk,
      surface: surface,
      onSurface: ink,
      surfaceContainerHighest:
          isLight ? const Color(0xFFE7EAEF) : AppColors.darkLine,
      onSurfaceVariant: inkSoft,
      outline: line,
      outlineVariant: line,
      error: const Color(0xFFD1373A),
      onError: Colors.white,
    );

    final textTheme = Typography.material2021(
      colorScheme: scheme,
    ).black.apply(fontFamily: fontFamily, bodyColor: ink, displayColor: ink);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      textTheme:
          brightness == Brightness.light
              ? textTheme
              : textTheme.apply(bodyColor: ink, displayColor: ink),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: ink, size: 24),
      ),
      iconTheme: IconThemeData(color: ink, size: 24),
      dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        iconColor: ink,
        textColor: ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: onInk,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          backgroundColor: surface,
          side: BorderSide(color: line),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: ink,
        side: BorderSide(color: line),
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: onInk,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: TextStyle(
          fontFamily: fontFamily,
          color: isLight ? AppColors.inkFaint : inkSoft,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          borderSide: BorderSide(color: ink, width: 1.4),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: BorderSide(color: line),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: onInk,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: ink,
        foregroundColor: onInk,
        elevation: 0,
        extendedTextStyle: const TextStyle(
          fontFamily: fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: line),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: ink,
        linearTrackColor: isLight ? AppColors.waveTrack : AppColors.darkLine,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
