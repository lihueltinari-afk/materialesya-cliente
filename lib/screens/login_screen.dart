import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _esRegistro = false;
  bool _verPassword = false;
  bool _cargando = false;
  String? _error;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nombreCtrl = TextEditingController();

  Future<void> _continuar() async {
    setState(() { _cargando = true; _error = null; });
    try {
      Map<String, dynamic> res;
      if (_esRegistro) {
        if (_nombreCtrl.text.isEmpty) { setState(() { _error = 'Ingresá tu nombre'; _cargando = false; }); return; }
        res = await ApiService.registro(_nombreCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text);
      } else {
        res = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
      }
      if (res['status'] == 200 || res['status'] == 201) {
        if (!mounted) return;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() => _error = res['data']['error'] ?? 'Error al ingresar');
      }
    } catch (e) {
      setState(() => _error = 'No se pudo conectar al servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 24),
            // Logo
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: kAmber, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.construction, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 10),
              RichText(text: const TextSpan(
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: kTextDark, letterSpacing: -0.5),
                children: [TextSpan(text: 'Materiales'), TextSpan(text: 'Ya', style: TextStyle(color: kAmber))],
              )),
            ]),
            const SizedBox(height: 40),
            Text(_esRegistro ? 'Crear cuenta' : 'Bienvenido', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(_esRegistro ? 'Completá tus datos para empezar' : 'Ingresá a tu cuenta', style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),

            if (_esRegistro) ...[
              const Text('Nombre completo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
              const SizedBox(height: 6),
              TextField(controller: _nombreCtrl, decoration: const InputDecoration(hintText: 'Juan Pérez', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
            ],

            const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
            const SizedBox(height: 6),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'tucorreo@email.com', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 16),

            const Text('Contraseña', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _passCtrl,
              obscureText: !_verPassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_verPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _verPassword = !_verPassword),
                ),
              ),
            ),

            if (!_esRegistro) ...[
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () {}, child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: kAmber, fontSize: 13)))),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargando ? null : _continuar,
              child: _cargando
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(_esRegistro ? 'Crear cuenta' : 'Ingresar'),
            ),
            const SizedBox(height: 16),

            // Divider
            Row(children: [
              Expanded(child: Divider(color: Colors.grey.shade300)),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('o', style: TextStyle(color: Colors.grey))),
              Expanded(child: Divider(color: Colors.grey.shade300)),
            ]),
            const SizedBox(height: 16),

            // Botón Google (visual, sin lógica por ahora)
            OutlinedButton.icon(
              onPressed: _continuar,
              icon: const Icon(Icons.g_mobiledata, size: 22),
              label: const Text('Continuar con Google'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.grey.shade300),
                foregroundColor: kTextDark,
              ),
            ),
            const SizedBox(height: 32),

            Center(child: TextButton(
              onPressed: () => setState(() => _esRegistro = !_esRegistro),
              child: RichText(text: TextSpan(
                style: const TextStyle(fontSize: 14),
                children: [
                  TextSpan(text: _esRegistro ? '¿Ya tenés cuenta? ' : '¿No tenés cuenta? ', style: const TextStyle(color: Colors.grey)),
                  TextSpan(text: _esRegistro ? 'Ingresá' : 'Registrate', style: const TextStyle(color: kAmber, fontWeight: FontWeight.w700)),
                ],
              )),
            )),
          ]),
        ),
      ),
    );
  }
}
