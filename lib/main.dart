import 'package:flutter/material.dart';
import 'package:hckt/home.dart';
import 'package:hckt/home_screen.dart';
import 'package:hckt/ok.dart';
import 'package:hckt/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeNotifier = ValueNotifier(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color(0xFF1DA1F2),
    scaffoldBackgroundColor: Color(0xFFF5F8FA),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1DA1F2),
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    colorScheme: ColorScheme.light(
      primary: Color(0xFF1DA1F2),
      secondary: Color(0xFFFFC107),
      surface: Colors.white,
      background: Color(0xFFF5F8FA),
      error: Color(0xFFFF4B5C),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Color(0xFF1F1F1F),
      onBackground: Color(0xFF1F1F1F),
      onError: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1DA1F2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all(Color(0xFF1DA1F2)),
    ),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF1F1F1F)),
      bodySmall: TextStyle(color: Color(0xFF6B6B6B)),
    ),
  );

  final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: Color(0xFF121212),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
    ),
    colorScheme: ColorScheme.dark(
      primary: Color(0xFF1DA1F2),
      secondary: Color(0xFFFFC107),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      error: Color(0xFFFF4B5C),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white,
      onBackground: Colors.white,
      onError: Colors.black,
    ),
    inputDecorationTheme: InputDecorationTheme(fillColor: Colors.grey[800]),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF1DA1F2),
        foregroundColor: Colors.white,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.all(Color(0xFF1DA1F2)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return AnimatedTheme(
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          data: currentMode == ThemeMode.dark ? darkTheme : lightTheme,
          child: MaterialApp(
            title: 'Từ điển chuyên ngành',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: currentMode,
            home: SplashScreen(),
          ),
        );
      },
    );
  }
}
