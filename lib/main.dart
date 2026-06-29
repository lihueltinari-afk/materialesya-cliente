import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const MaterialesYaApp());

class MaterialesYaApp extends StatelessWidget {
  const MaterialesYaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaterialesYa',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}
