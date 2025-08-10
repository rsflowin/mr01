import 'package:flutter/material.dart';
import 'screens/main_menu_screen.dart';

void main() {
  runApp(const MazeReignsApp());
}

class MazeReignsApp extends StatelessWidget {
  const MazeReignsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maze Reigns',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B0000),
          secondary: Color(0xFF4A4A4A),
          surface: Color(0xFF1A1A1A),
          background: Color(0xFF0A0A0A),
          onSurface: Color(0xFFE0E0E0),
        ),
        fontFamily: 'serif',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4D4D4),
            letterSpacing: 2.0,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: Color(0xFFB0B0B0),
            letterSpacing: 1.2,
          ),
        ),
      ),
      home: const MainMenuScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

