import 'package:flutter/material.dart';
//import 'package:get/get.dart';

class LightColors {
  // color define
  static const Color basic = Color(0xFFFFFFFF);
  // static const Color orange1 = Color(0xFFEB8C1C);
  // static const Color orange2 = Color(0xFFFFA842);
  static const Color blue = Color(0xFF3485FF);
  static const Color gray1 = Color(0xFFFFFFFF);
  static const Color gray2 = Color(0xFFF5F5F5);
  static const Color gray3 = Color(0xFFEEEEEF);
  static const Color gray4 = Color(0xFFDFE1E4);
  static const Color gray5 = Color(0xFF767676);
  static const Color gray6 = Color(0xFF4D4D4D);

  ///텍스트 컬러, 버튼 테두리, 버튼 텍스트, 버튼 반전 시 버튼 안의 색상
  static const Color textColor = Color(0xFF121212);

  static const Color important = Color(0xFF2D2D2D);

  static const Color gray0 = Color(0xFF2D2D2D);
  //custom
}

class DarkColors {
  // color define
  static const Color basic = Color(0xFF000000);
  // static const Color orange1 = Color(0xFFEF8E1D);
  // static const Color orange2 = Color(0xFFFFB55E);
  static const Color blue = Color(0xFF5196FF);
  static const Color gray1 = Color(0xFF1A1A1A);
  static const Color gray2 = Color(0xFF2B2B2B);
  static const Color gray3 = Color(0XFF3C3C3C);
  static const Color gray4 = Color(0xFF4D4D4D);
  static const Color gray5 = Color(0xFFAFAFAF);
  static const Color gray6 = Color(0xFFDCDCDC);

  ///텍스트 컬러, 버튼 테두리, 버튼 텍스트, 버튼 반전 시 버튼 안의 색상
  static const Color textColor = Color(0xFFDCDCDC);

  static const Color important = Color(0xFFFFFFFF);

  //custom
  static const Color gray0 = Color(0xFF000000);
}

class CommonColors {
  // color define
  ///차트에 사용 할 컬러
  static const Color red = Color(0xFFEF2D21);
  static const Color blue = Color(0xFF4881FF);

  ///관심종목
  static const Color yellow = Color(0xFFFAD113);

  static const Color green = Color(0xFF8ED9AB);
  static const Color onWhite = Color(0xFFFFFFFF);
  static const Color onBlack = Color(0xFF2D2D2D);
}

ThemeData lightTheme = ThemeData(
  appBarTheme: const AppBarTheme(backgroundColor: LightColors.gray2),
  colorScheme: const ColorScheme(
    primary: LightColors.gray0, // point color1
    onPrimary: LightColors.textColor, //required
    onSecondary: LightColors.textColor, //required
    primaryContainer: LightColors.gray0, // point color2
    secondary: LightColors.blue, // point color3
    background: LightColors.gray1, // app backgound
    surface: LightColors.gray2, // card background
    outline: LightColors.gray3, // card line or divider
    surfaceVariant: LightColors.gray4, // disabled
    onSurface: LightColors.gray5, // text3
    onSurfaceVariant: LightColors.gray6, //text2
    onBackground: LightColors.important, //text1
    error: CommonColors.red, // danger
    tertiary: CommonColors.yellow, // normal
    tertiaryContainer: CommonColors.green, // safe
    onError: LightColors.basic, //no use
    brightness: Brightness.light,
  ),
);

ThemeData darkTheme = ThemeData(
  appBarTheme: const AppBarTheme(backgroundColor: DarkColors.gray2),
  colorScheme: const ColorScheme(
    primary: DarkColors.gray0, // point color1
    onPrimary: DarkColors.textColor, //required
    onSecondary: CommonColors.onWhite, //required
    primaryContainer: DarkColors.gray0, // point color2
    secondary: DarkColors.blue, // point color3
    background: DarkColors.gray1, // app backgound
    surface: DarkColors.gray2, // card background
    outline: DarkColors.gray3, // card line or divider
    surfaceVariant: DarkColors.gray4, // disabled
    onSurface: DarkColors.important, //text3
    onSurfaceVariant: DarkColors.gray6, // text2
    onBackground: DarkColors.important, //text1
    error: CommonColors.red, // danger
    tertiary: CommonColors.yellow, // normal
    tertiaryContainer: CommonColors.green, // safe
    onError: DarkColors.basic, // no use
    brightness: Brightness.light,
  ),
);
