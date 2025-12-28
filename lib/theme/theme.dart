import 'package:flutter/material.dart';

// Light Mode: Black on White
ThemeData lightTheme() => ThemeData(
  brightness: Brightness.light,
  // Define a simple ColorScheme that is essentially Black on White
  colorScheme: const ColorScheme(
    brightness: Brightness.light,
    primary:
        Colors.black, // Used for primary app elements (e.g., AppBar background)
    onPrimary: Colors.white, // Text/Icons on primary color
    secondary: Colors
        .black, // Used for secondary elements (e.g., Floating Action Button)
    onSecondary: Colors.white, // Text/Icons on secondary color
    surface: Colors.white, // Background for cards, sheets, etc.
    onSurface: Colors.black, // Text/Icons on surface color
    error: Colors.red, // For error states
    onError: Colors.white, // Text/Icons on error color
  ),
  // Customize other properties for the light theme
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    titleTextStyle: TextStyle(color: Colors.black, fontSize: 20),
    toolbarTextStyle: TextStyle(color: Colors.black, fontSize: 18),
    iconTheme: IconThemeData(color: Colors.black),
    elevation: 1, // subtle shadow
  ),
  // Text theme to ensure default text is black
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.black),
    displayMedium: TextStyle(color: Colors.black),
    displaySmall: TextStyle(color: Colors.black),
    headlineLarge: TextStyle(color: Colors.black),
    headlineMedium: TextStyle(color: Colors.black),
    headlineSmall: TextStyle(color: Colors.black),
    titleLarge: TextStyle(color: Colors.black),
    titleMedium: TextStyle(color: Colors.black),
    titleSmall: TextStyle(color: Colors.black),
    bodyLarge: TextStyle(color: Colors.black),
    bodyMedium: TextStyle(color: Colors.black),
    bodySmall: TextStyle(color: Colors.black),
    labelLarge: TextStyle(color: Colors.black),
    labelMedium: TextStyle(color: Colors.black),
    labelSmall: TextStyle(color: Colors.black),
  ),
);

// Dark Mode: Black on Yellow
ThemeData darkTheme() => ThemeData(
  brightness: Brightness.dark,
  // Define a simple ColorScheme that is essentially White on Black
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: Colors.white, // Used for primary app elements
    onPrimary: Colors.black, // Text/Icons on primary color
    secondary: Colors.white, // Used for secondary elements
    onSecondary: Colors.black, // Text/Icons on secondary color
    surface: Colors.black, // Background for cards, sheets, etc.
    onSurface: Colors.white, // Text/Icons on surface color
    error: Colors.red, // For error states
    onError: Colors.white, // Text/Icons on error color
  ),
  // Customize other properties for the dark theme
  scaffoldBackgroundColor: Colors.black,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.black,
    // `foregroundColor` is deprecated. Use `titleTextStyle` and `iconTheme`
    titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    toolbarTextStyle: TextStyle(color: Colors.white, fontSize: 18),
    iconTheme: IconThemeData(color: Colors.white),
    elevation: 1,
  ),
  // Text theme to ensure default text is white
  textTheme: const TextTheme(
    displayLarge: TextStyle(color: Colors.white),
    displayMedium: TextStyle(color: Colors.white),
    displaySmall: TextStyle(color: Colors.white),
    headlineLarge: TextStyle(color: Colors.white),
    headlineMedium: TextStyle(color: Colors.white),
    headlineSmall: TextStyle(color: Colors.white),
    titleLarge: TextStyle(color: Colors.white),
    titleMedium: TextStyle(color: Colors.white),
    titleSmall: TextStyle(color: Colors.white),
    bodyLarge: TextStyle(color: Colors.white),
    bodyMedium: TextStyle(color: Colors.white),
    bodySmall: TextStyle(color: Colors.white),
    labelLarge: TextStyle(color: Colors.white),
    labelMedium: TextStyle(color: Colors.white),
    labelSmall: TextStyle(color: Colors.white),
  ),
);
