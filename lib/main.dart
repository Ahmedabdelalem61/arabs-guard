import 'package:flutter/material.dart';

import 'home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArabsGuardApp());
}

class ArabsGuardApp extends StatelessWidget {
  const ArabsGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF06162F);
    const teal = Color(0xFF15B7A5);
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: navy,
      secondary: teal,
      surface: const Color(0xFFF6F8FB),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arabs Guard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF6F8FB),
        fontFamily: 'sans-serif',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFE4E9F1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: teal, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
