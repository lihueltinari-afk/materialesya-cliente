import 'package:flutter/material.dart';

const kAmber = Color(0xFFE07B00);
const kAmberDark = Color(0xFFC46900);
const kBgPage = Color(0xFFF5F5F3);
const kTextDark = Color(0xFF1A1A1A);
const kSuccess = Color(0xFF2E7D32);
const kSuccessBg = Color(0xFFE8F5E9);

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: kAmber, primary: kAmber),
  fontFamily: 'Roboto',
  useMaterial3: true,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kAmber,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAmber, width: 1.5)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
);
