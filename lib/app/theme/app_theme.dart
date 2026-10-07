import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF6366F1);
  static const _surface = Color(0xFF111827);
  static const _border = Color(0xFF1E293B);
  static const _muted = Color(0xFF94A3B8);

  static ThemeData get darkTheme {
    final scheme = ColorScheme.fromSeed(seedColor: _primary, brightness: Brightness.dark).copyWith(
      primary: _primary,
      surface: _surface,
      outline: _border,
      error: const Color(0xFFEF4444),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B1120),
      fontFamily: 'Arial',
      cardTheme: CardThemeData(color: _surface, elevation: 0, margin: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border))),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        labelStyle: const TextStyle(color: _muted, fontSize: 13),
        hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _primary, width: 1.4)),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(inputDecorationTheme: const InputDecorationTheme(filled: true, fillColor: Color(0xFF0F172A))),
      checkboxTheme: CheckboxThemeData(fillColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected) ? _primary : Colors.transparent), side: const BorderSide(color: _muted)),
      listTileTheme: const ListTileThemeData(iconColor: _muted, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
      snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: _surface, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: _primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFA5B4FC), side: const BorderSide(color: _border), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    );
  }
}
