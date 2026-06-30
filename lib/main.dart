import 'package:flutter/material.dart';
import 'core/app_router.dart';
import 'theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar FCM en background (no bloquea el arranque de la app)
  NotificationService.inicializar().catchError((_) {});
  runApp(const MaterialesYaApp());
}

class MaterialesYaApp extends StatelessWidget {
  const MaterialesYaApp({super.key});
  @override
  Widget build(BuildContext context) {
    ApiService.onSesionExpirada = () async {
      await ApiService.cerrarSesion();
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen(sesionExpirada: true)),
        (_) => false,
      );
    };

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'MaterialesYa',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}
