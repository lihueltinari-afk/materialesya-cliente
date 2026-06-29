import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});
  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    ApiService.usuarioActual().then((u) => setState(() => _usuario = u));
  }

  Future<void> _cerrarSesion() async {
    await ApiService.cerrarSesion();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: SingleChildScrollView(child: Column(children: [
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
        child: Column(children: [
          const Text('Mi perfil', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: kTextDark, letterSpacing: -0.5)),
          const SizedBox(height: 20),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(color: kAmber, shape: BoxShape.circle),
            child: Center(child: Text(
              _usuario?['nombre']?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
            )),
          ),
          const SizedBox(height: 12),
          Text(_usuario?['nombre'] ?? 'Usuario', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: kTextDark)),
          Text(_usuario?['email'] ?? '', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ]),
      ),
      const SizedBox(height: 8),
      _seccion([
        _item(Icons.receipt_long_outlined, 'Mis pedidos', onTap: () {}),
        _item(Icons.location_on_outlined, 'Mis direcciones', onTap: () {}),
        _item(Icons.payment_outlined, 'Métodos de pago', onTap: () {}),
      ]),
      const SizedBox(height: 8),
      _seccion([
        _item(Icons.help_outline, 'Ayuda y soporte', onTap: () {}),
        _item(Icons.star_outline, 'Calificar la app', onTap: () {}),
        _item(Icons.info_outline, 'Acerca de MaterialesYa', onTap: () {}),
      ]),
      const SizedBox(height: 8),
      _seccion([
        _item(Icons.logout, 'Cerrar sesión', color: Colors.red, onTap: _cerrarSesion),
      ]),
      const SizedBox(height: 24),
      const Text('MaterialesYa v1.0 — Mendoza', style: TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 16),
    ])));
  }

  Widget _seccion(List<Widget> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade100)),
      child: Column(children: List.generate(items.length, (i) => Column(children: [
        items[i],
        if (i < items.length - 1) Divider(height: 1, color: Colors.grey.shade100),
      ]))),
    );
  }

  Widget _item(IconData icono, String label, {Color? color, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icono, color: color ?? kTextDark, size: 22),
      title: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color ?? kTextDark)),
      trailing: color == null ? const Icon(Icons.chevron_right, color: Colors.grey, size: 20) : null,
      onTap: onTap,
      dense: true,
    );
  }
}
