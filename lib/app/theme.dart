import 'package:flutter/material.dart';

const ink = Color(0xFF46384C);
const muted = Color(0xFF8A7A8E);
const pink = Color(0xFFFF7FA5);
const paper = Color(0xFFFFF9F5);
const line = Color(0xFFEADDE5);

ThemeData buildAppTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  colorScheme: ColorScheme.fromSeed(
    seedColor: pink,
    brightness: Brightness.light,
    surface: paper,
  ),
  fontFamily: '.AppleSystemUIFont',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      color: ink,
      fontSize: 30,
      fontWeight: FontWeight.w900,
      height: 1.18,
    ),
    headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w900),
    titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w900),
    bodyMedium: TextStyle(color: ink),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: line),
    ),
  ),
);
