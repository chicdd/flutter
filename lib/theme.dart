import 'package:flutter/material.dart';

// 커스텀 색상 확장
class AppColors extends ThemeExtension<AppColors> {
  final Color gray10;
  final Color gray30;
  final Color cardBackground;
  final Color secondBackground;
  final Color dividerColor;
  final Color textEnable;
  final Color selectedColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color borderColor;
  final Color fillhiright;
  final Color background;
  final Color textReadOnly;
  final Color snackBarColor;
  final Color deepBlue;
  final Color white;
  final Color orange;
  final Color green;
  final Color red;

  const AppColors({
    required this.gray10,
    required this.gray30,
    required this.cardBackground,
    required this.secondBackground,
    required this.dividerColor,
    required this.textEnable,
    required this.selectedColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.borderColor,
    required this.fillhiright,
    required this.background,
    required this.textReadOnly,
    required this.snackBarColor,
    required this.deepBlue,
    required this.white,
    required this.orange,
    required this.green,
    required this.red,
  });

  @override
  AppColors copyWith({
    Color? gray10,
    Color? gray30,
    Color? cardBackground,
    Color? secondBackground,
    Color? dividerColor,
    Color? textEnable,
    Color? selectedColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? borderColor,
    Color? fillhiright,
    Color? background,
    Color? textReadOnly,
    Color? snackBarColor,
    Color? deepBlue,
    Color? white,
    Color? orange,
    Color? green,
    Color? red,
  }) {
    return AppColors(
      gray10: gray10 ?? this.gray10,
      gray30: gray30 ?? this.gray30,
      cardBackground: cardBackground ?? this.cardBackground,
      secondBackground: secondBackground ?? this.secondBackground,
      dividerColor: dividerColor ?? this.dividerColor,
      textEnable: textEnable ?? this.textEnable,
      selectedColor: selectedColor ?? this.selectedColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      borderColor: borderColor ?? this.borderColor,
      fillhiright: fillhiright ?? this.fillhiright,
      background: background ?? this.background,
      textReadOnly: textReadOnly ?? this.textReadOnly,
      snackBarColor: snackBarColor ?? this.snackBarColor,
      deepBlue: deepBlue ?? this.deepBlue,
      white: white ?? this.white,
      orange: orange ?? this.orange,
      green: green ?? this.green,
      red: red ?? this.red,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      gray10: Color.lerp(gray10, other.gray10, t)!,
      gray30: Color.lerp(gray30, other.gray30, t)!,
      cardBackground: Color.lerp(cardBackground, other.cardBackground, t)!,
      secondBackground: Color.lerp(
        secondBackground,
        other.secondBackground,
        t,
      )!,
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t)!,
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t)!,
      textEnable: Color.lerp(textEnable, other.textEnable, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      borderColor: Color.lerp(borderColor, other.borderColor, t)!,
      fillhiright: Color.lerp(fillhiright, other.fillhiright, t)!,
      background: Color.lerp(background, other.background, t)!,
      textReadOnly: Color.lerp(textReadOnly, other.textReadOnly, t)!,
      snackBarColor: Color.lerp(snackBarColor, other.snackBarColor, t)!,
      deepBlue: Color.lerp(deepBlue, other.deepBlue, t)!,
      white: Color.lerp(white, other.white, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
    );
  }

  // Light 테마 색상
  static const light = AppColors(
    gray10: Color(0xFFE8E8ED),
    gray30: Color(0xFFA9A9A9),
    cardBackground: Color(0xFFFFFFFF),
    secondBackground: Color(0xFFF2F4F6),
    dividerColor: Color(0xFFD1D1D6),
    textEnable: Color(0xFFFFFFFF),
    selectedColor: Color(0xFF007AFF),
    textPrimary: Color(0xFF000000),
    textSecondary: Color(0xFF707075),
    textTertiary: Color(0xFFC7C7CC),
    borderColor: Color(0x00000000),
    fillhiright: Color(0x93007AFF),
    background: Color(0xFFf2f1f6),
    textReadOnly: Color(0xFFF0F0F3),
    snackBarColor: Color(0x80232525),
    deepBlue: Color(0x930065CE),
    white: Colors.white,
    orange: Colors.orange,
    green: Colors.green,
    red: Colors.red,
  );

  // Dark 테마 색상
  static const dark = AppColors(
    gray10: Color(0xFF1E1E1E),
    gray30: Color(0xFF505050),
    cardBackground: Color(0xFF1c1c1e),
    secondBackground: Color(0xff262628),
    dividerColor: Color(0xFF3D3D3D),
    textEnable: Color(0xFF3D3D3D),
    selectedColor: Color(0xFF447FBB),
    textPrimary: Color(0xFFE0E0E0),
    textSecondary: Color(0xFFB0B0B0),
    textTertiary: Color(0xFF707070),
    borderColor: Color(0xFF707070),
    fillhiright: Color(0x00000000),
    background: Color(0xFF000000),
    textReadOnly: Color(0xff171718),
    snackBarColor: Color(0x7Bffffff),
    deepBlue: Color(0x93115FAB),
    white: Colors.white,
    orange: Color(0xFFD5912E),
    green: Color(0xFF4CAF50),
    red: Color(0xFFDE1F1F),
  );
}

class AppTheme {
  // Light 테마 색상
  static const Color backgroundColor = Color(0xFFF5F5F7);
  static const Color sidebarBackground = Color(0xFFE8E8ED);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFD1D1D6);
  static const Color selectedColor = Color(0xFF007AFF);
  static const Color textEnable = Color(0xFFE5E5EA);
  static const Color textPrimary = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF77777C);
  static const Color textTertiary = Color(0xFFC7C7CC);

  // Dark 테마 색상
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSidebarBackground = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF2D2D2D);
  static const Color darkDividerColor = Color(0xFF3D3D3D);
  static const Color darkSelectedColor = Color(0xFF298CFF);
  static const Color darktextEnable = Color(0xFF3D3D3D);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkTextTertiary = Color(0xFF707070);

  // 그림자
  static const List<BoxShadow> cardShadow = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> elevatedShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  // 테마 데이터
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: selectedColor,
        surface: backgroundColor,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: backgroundColor,
      extensions: const <ThemeExtension<dynamic>>[AppColors.light],
      fontFamily: 'AppleSDGothicNeo',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: selectedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // 다크 테마
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: selectedColor,
        surface: darkBackgroundColor,
        onSurface: darkTextPrimary,
      ),
      scaffoldBackgroundColor: darkBackgroundColor,
      extensions: const <ThemeExtension<dynamic>>[AppColors.dark],
      fontFamily: 'AppleSDGothicNeo',
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: darkTextPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: darkTextPrimary),
        bodySmall: TextStyle(fontSize: 12, color: darkTextSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCardBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkDividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: darkDividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: selectedColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

// BuildContext extension으로 쉽게 접근
extension ThemeExtensions on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
