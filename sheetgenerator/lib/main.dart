import 'dart:io';
import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sheetgenerator/Modal_Select_List.dart';
import 'package:sheetgenerator/Select.dart';

import 'Colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  final savedThemeMode = await AdaptiveTheme.getThemeMode();
  runApp(MyApp(savedThemeMode: savedThemeMode));
}

class MyApp extends StatelessWidget {
  final AdaptiveThemeMode? savedThemeMode;
  const MyApp({super.key, this.savedThemeMode});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: lightTheme,
      dark: darkTheme,
      initial: savedThemeMode ?? AdaptiveThemeMode.system,
      builder: (theme, darkTheme) =>
          MaterialApp(theme: theme, darkTheme: darkTheme, home: const Main()),
    );
  }
}

class Main extends StatefulWidget {
  const Main({super.key});

  @override
  State<Main> createState() => _MainState();
}

class _MainState extends State<Main> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '네오 견적서 생성기',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        automaticallyImplyLeading: false,
        shadowColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Select(
              selectClass: "customer",
              selectDefault: "거래처선택",
              onPressed: (int selectedIndex) {
                setState(() {});
              },
            ),
            SizedBox(height: 20),
            Select(
              selectClass: "manager",
              selectDefault: "담당자선택",
              onPressed: (int selectedIndex) {
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.sunny),
              title: const Text("라이트 모드"),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            IconButton(
              icon: Icon(
                isDark ? Icons.nightlight_outlined : Icons.sunny,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: _showThemeSelector,
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sunny),
                title: const Text("라이트 모드"),
                onTap: () {
                  AdaptiveTheme.of(context).setLight();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.nightlight_outlined),
                title: const Text("다크 모드"),
                onTap: () {
                  AdaptiveTheme.of(context).setDark();
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text("시스템 설정 따르기"),
                onTap: () {
                  AdaptiveTheme.of(context).setSystem();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // '?'를 추가해서 null safety 확보
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Widget toggleMode() {
  final isDarkMode = Get.isDarkMode;
  final newTheme = isDarkMode ? ThemeData.light() : ThemeData.dark();
  final modeToCheck = isDarkMode ? "light" : "dark";

  return InkWell(
    onTap: () {
      Get.changeTheme(newTheme);
      StoreUtils.instance.checkMode(modeToCheck);
    },
    child: Icon(
      isDarkMode ? Icons.nightlight_outlined : Icons.sunny,
      color: isDarkMode ? Colors.white : Colors.black,
    ),
  );
}

class StoreUtils {
  static final StoreUtils instance = StoreUtils._internal();

  StoreUtils._internal();

  Future<void> checkMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("themeMode", mode);
  }

  Future<String?> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("themeMode");
  }
}
