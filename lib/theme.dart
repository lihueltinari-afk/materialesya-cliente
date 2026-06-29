import 'package:flutter/material.dart';

// ── Paleta de colores MaterialesYa ──────────────────────────────────────────
const kAmber     = Color(0xFFE07B00);  // Primario — naranja obra
const kAmberDark = Color(0xFFC46900);  // Primario oscuro — hover/pressed
const kNavy      = Color(0xFF1E3A5F);  // Secundario — azul marino (confianza)
const kBgPage    = Color(0xFFF5F5F3);  // Fondo general — gris cálido
const kTextDark  = Color(0xFF1A1A1A);  // Texto principal
const kTextGrey  = Color(0xFF6B6B6B);  // Texto secundario

// Semánticos — estados del pedido
const kSuccess   = Color(0xFF2E7D32);  // Entregado, confirmado
const kSuccessBg = Color(0xFFE8F5E9);
const kWarning   = Color(0xFFF57C00);  // Pendiente, preparando
const kWarningBg = Color(0xFFFFF3E0);
const kError     = Color(0xFFD32F2F);  // Cancelado, pago fallido
const kErrorBg   = Color(0xFFFFEBEE);
const kInfo      = Color(0xFF1976D2);  // En camino, repartidor
const kInfoBg    = Color(0xFFE3F2FD);

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
      elevation: 0,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: kAmber,
      side: const BorderSide(color: kAmber),
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
