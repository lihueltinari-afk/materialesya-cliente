import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'verificar_email_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool sesionExpirada;
  const LoginScreen({super.key, this.sesionExpirada = false});
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

  @override
  void initState() {
    super.initState();
    if (widget.sesionExpirada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tu sesión expiró, ingresá de nuevo.'),
          backgroundColor: kWarning,
          duration: Duration(seconds: 4),
        ));
      });
    }
  }

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
        if (_esRegistro) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (_) => VerificarEmailScreen(email: _emailCtrl.text.trim()),
          ));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        setState(() => _error = res['data']?['error'] ?? 'Error al ingresar');
      }
    } catch (e) {
      setState(() => _error = 'No se pudo conectar al servidor');
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _abrirRecuperarPassword() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const _RecuperarPasswordScreen()));
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
            Text(_esRegistro ? 'Crear cuenta' : 'Bienvenido',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: kTextDark, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(_esRegistro ? 'Completá tus datos para empezar' : 'Ingresá a tu cuenta',
              style: const TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 32),

            if (_esRegistro) ...[
              const Text('Nombre completo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
              const SizedBox(height: 6),
              TextField(controller: _nombreCtrl,
                decoration: const InputDecoration(hintText: 'Juan Pérez', prefixIcon: Icon(Icons.person_outline))),
              const SizedBox(height: 16),
            ],

            const Text('Email', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
            const SizedBox(height: 6),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'tucorreo@email.com', prefixIcon: Icon(Icons.email_outlined))),
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
              Align(alignment: Alignment.centerRight, child: TextButton(
                onPressed: _abrirRecuperarPassword,
                child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(color: kAmber, fontSize: 13)),
              )),
            ],

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200)),
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
            const SizedBox(height: 32),
            Center(child: TextButton(
              onPressed: () => setState(() => _esRegistro = !_esRegistro),
              child: RichText(text: TextSpan(
                style: const TextStyle(fontSize: 14),
                children: [
                  TextSpan(text: _esRegistro ? '¿Ya tenés cuenta? ' : '¿No tenés cuenta? ',
                    style: const TextStyle(color: Colors.grey)),
                  TextSpan(text: _esRegistro ? 'Ingresá' : 'Registrate',
                    style: const TextStyle(color: kAmber, fontWeight: FontWeight.w700)),
                ],
              )),
            )),
          ]),
        ),
      ),
    );
  }
}

// ─── PANTALLA RECUPERAR CONTRASEÑA ───────────────────────────────────────────
class _RecuperarPasswordScreen extends StatefulWidget {
  const _RecuperarPasswordScreen();
  @override
  State<_RecuperarPasswordScreen> createState() => _RecuperarPasswordScreenState();
}

class _RecuperarPasswordScreenState extends State<_RecuperarPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _cargando = false;
  bool _enviado = false;
  String? _error;

  Future<void> _enviar() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Ingresá tu email');
      return;
    }
    setState(() { _cargando = true; _error = null; });
    final res = await ApiService.post('/auth/recuperar-password', {'email': _emailCtrl.text.trim()});
    if (!mounted) return;
    setState(() => _cargando = false);
    if (res['status'] == 200) {
      setState(() => _enviado = true);
    } else {
      setState(() => _error = res['data']?['error'] ?? 'No se pudo enviar el email');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgPage,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: kTextDark), onPressed: () => Navigator.pop(context)),
        title: const Text('Recuperar contraseña', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: kTextDark)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _enviado ? _PantallaConfirmacion(email: _emailCtrl.text) : _FormularioEmail(
          ctrl: _emailCtrl,
          cargando: _cargando,
          error: _error,
          onEnviar: _enviar,
        ),
      ),
    );
  }
}

class _FormularioEmail extends StatelessWidget {
  final TextEditingController ctrl;
  final bool cargando;
  final String? error;
  final VoidCallback onEnviar;
  const _FormularioEmail({required this.ctrl, required this.cargando, this.error, required this.onEnviar});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: kInfoBg, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.info_outline, color: kInfo, size: 20),
          SizedBox(width: 10),
          Expanded(child: Text(
            'Te enviaremos un código de 6 dígitos para restablecer tu contraseña.',
            style: TextStyle(fontSize: 13, color: kInfo, height: 1.5),
          )),
        ]),
      ),
      const SizedBox(height: 24),
      const Text('Email de tu cuenta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kTextDark)),
      const SizedBox(height: 8),
      TextField(
        controller: ctrl,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'tucorreo@email.com',
          prefixIcon: Icon(Icons.email_outlined, color: kAmber),
        ),
      ),
      if (error != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: kErrorBg, borderRadius: BorderRadius.circular(8)),
          child: Text(error!, style: const TextStyle(color: kError, fontSize: 13)),
        ),
      ],
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: cargando ? null : onEnviar,
        child: cargando
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Enviar código de recuperación'),
      ),
    ]);
  }
}

class _PantallaConfirmacion extends StatelessWidget {
  final String email;
  const _PantallaConfirmacion({required this.email});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 600),
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(color: kSuccessBg, shape: BoxShape.circle),
          child: const Icon(Icons.mark_email_read_rounded, color: kSuccess, size: 54),
        ),
      ),
      const SizedBox(height: 24),
      const Text('¡Email enviado!',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: kTextDark)),
      const SizedBox(height: 10),
      Text('Enviamos un código de recuperación a\n$email',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.6)),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: kWarningBg, borderRadius: BorderRadius.circular(12)),
        child: const Row(children: [
          Icon(Icons.timer_outlined, color: kWarning, size: 18),
          SizedBox(width: 10),
          Expanded(child: Text('El código expira en 30 minutos.',
            style: TextStyle(fontSize: 13, color: kWarning))),
        ]),
      ),
      const SizedBox(height: 32),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver al inicio de sesión',
          style: TextStyle(color: kAmber, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}
