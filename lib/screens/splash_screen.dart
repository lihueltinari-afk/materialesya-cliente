import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'aceptar_terminos_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final token = await ApiService.obtenerToken();
      final aceptados = await terminosYaAceptados();
      if (!mounted) return;
      final destino = (token != null && token.isNotEmpty) ? const HomeScreen() : const LoginScreen();
      if (aceptados) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => destino));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AceptarTerminosScreen(destino: destino)));
      }
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAmber,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 90, height: 90,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.construction, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, color: Colors.white),
                  children: [
                    TextSpan(text: 'Materiales'),
                    TextSpan(text: 'Ya', style: TextStyle(color: Color(0xFFFFD280))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Text('delivery de construcción', style: TextStyle(fontSize: 13, color: Colors.white70, letterSpacing: 1.5)),
            ]),
          ),
        ),
      ),
    );
  }
}
